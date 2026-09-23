#!/usr/bin/env python3
"""Bounded IPA packaging. No uploaded code is executed and no signing is attempted."""
import hashlib
import http.client
import ipaddress
import json
import os
from pathlib import Path, PurePosixPath
import plistlib
import re
import shutil
import signal
import socket
import ssl
import stat
import struct
import sys
import urllib.parse
import zipfile

MAX_IPA = 512 * 1024**2
MAX_EXPANDED = 2 * 1024**3
MAX_BINARY = 256 * 1024**2
MAX_DYLIB = 32 * 1024**2
ARM64 = 0x0100000C


class Invalid(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise Invalid(message)


def public_addresses(host):
    require(re.fullmatch(r"[A-Za-z0-9.-]{1,253}", host) is not None, "اسم مضيف الرابط غير صالح.")
    addresses = {entry[4][0] for entry in socket.getaddrinfo(host, 443, type=socket.SOCK_STREAM)}
    require(bool(addresses), "تعذر العثور على خادم الرابط.")
    for raw in addresses:
        addr = ipaddress.ip_address(raw)
        mapped = isinstance(addr, ipaddress.IPv6Address) and addr.ipv4_mapped is not None
        require(addr.is_global and not addr.is_multicast and not addr.is_unspecified and not mapped,
                "روابط الشبكات الداخلية غير مسموحة.")
    return sorted(addresses)


class PinnedHTTPS(http.client.HTTPSConnection):
    def __init__(self, host, address):
        super().__init__(host, timeout=25, context=ssl.create_default_context())
        self.address = address

    def connect(self):
        sock = socket.create_connection((self.address, 443), self.timeout)
        try:
            self.sock = self._context.wrap_socket(sock, server_hostname=self.host)
        except BaseException:
            sock.close()
            raise


def download(url, destination):
    """Resolve and pin every redirect; never use environment HTTP proxies."""
    for _ in range(6):
        parsed = urllib.parse.urlsplit(url)
        require(parsed.scheme == "https" and parsed.hostname and not parsed.username
                and not parsed.password and parsed.port in (None, 443)
                and not any(ord(c) < 32 for c in url), "أدخل رابط HTTPS مباشرًا دون بيانات دخول.")
        addresses = public_addresses(parsed.hostname)
        conn = PinnedHTTPS(parsed.hostname, addresses[0])
        try:
            target = urllib.parse.urlunsplit(("", "", parsed.path or "/", parsed.query, ""))
            conn.request("GET", target, headers={"User-Agent": "WolFox-Portal/3.0.0", "Accept-Encoding": "identity"})
            res = conn.getresponse()
            if res.status in (301, 302, 303, 307, 308):
                location = res.getheader("Location")
                require(bool(location), "رابط التحويل غير صالح.")
                url = urllib.parse.urljoin(url, location)
                continue
            require(res.status == 200, "لم يعطِ الرابط ملفًا قابلًا للتنزيل.")
            length = res.getheader("Content-Length")
            require(length is None or (length.isdigit() and int(length) <= MAX_IPA), "حجم IPA يتجاوز 512 ميجابايت.")
            total = 0
            with open(destination, "xb") as out:
                while chunk := res.read(1024 * 1024):
                    total += len(chunk)
                    require(total <= MAX_IPA, "حجم IPA يتجاوز 512 ميجابايت.")
                    out.write(chunk)
            return
        finally:
            conn.close()
    raise Invalid("تجاوز الرابط عدد التحويلات المسموح.")


def slices(data):
    require(len(data) >= 32, "ملف Mach-O غير مكتمل.")
    if data[:4] == b"\xcf\xfa\xed\xfe":
        return [(0, len(data))]
    variants = {b"\xca\xfe\xba\xbe": (">", 20), b"\xbe\xba\xfe\xca": ("<", 20),
                b"\xca\xfe\xba\xbf": (">", 32), b"\xbf\xba\xfe\xca": ("<", 32)}
    magic = bytes(data[:4])
    require(magic in variants, "يُدعم Mach-O ‏64-bit على arm64 فقط.")
    endian, entry_size = variants[magic]
    count = struct.unpack_from(endian + "I", data, 4)[0]
    require(1 <= count <= 16 and 8 + count * entry_size <= len(data), "ترويسة Universal غير صالحة.")
    result = []
    for i in range(count):
        pos = 8 + i * entry_size
        cpu, _ = struct.unpack_from(endian + "II", data, pos)
        off, size = struct.unpack_from(endian + ("II" if entry_size == 20 else "QQ"), data, pos + 8)
        require(cpu == ARM64 and off >= 8 + count * entry_size and size >= 32
                and off + size <= len(data), "تحتوي الحزمة شريحة غير مدعومة أو تالفة.")
        require(all(off + size <= old or off >= old + n for old, n in result), "شرائح Universal متداخلة.")
        result.append((off, size))
    return result


def inspect_slice(data, expected_type):
    require(len(data) >= 32 and data[:4] == b"\xcf\xfa\xed\xfe", "شريحة Mach-O غير مدعومة.")
    _, cpu, subtype, kind, count, size, _, _ = struct.unpack_from("<8I", data)
    require(cpu == ARM64 and kind == expected_type, "نوع الملف أو معماريته غير متوافق.")
    require(count <= 8192 and 32 + size <= len(data), "أوامر Mach-O تالفة.")
    commands, boundaries, dependencies = [], [], []
    cursor = 32
    for _ in range(count):
        require(cursor + 8 <= 32 + size, "أمر Mach-O ناقص.")
        cmd, length = struct.unpack_from("<II", data, cursor)
        require(length >= 8 and length % 8 == 0 and cursor + length <= 32 + size, "حجم أمر Mach-O غير صالح.")
        part = data[cursor:cursor + length]
        if cmd in (0x21, 0x2C):  # LC_ENCRYPTION_INFO[_64]
            require(length >= 20 and struct.unpack_from("<I", part, 16)[0] == 0,
                    "الملف التنفيذي مشفّر؛ يلزم ملف بناء غير مشفّر تملك حق تعديله.")
        if cmd == 0x19:  # LC_SEGMENT_64
            require(length >= 72, "مقطع Mach-O ناقص.")
            fileoff, filesize = struct.unpack_from("<QQ", part, 40)
            require(fileoff + filesize <= len(data), "مقطع Mach-O خارج حدود الملف.")
            if fileoff and filesize:
                boundaries.append(fileoff)
            sections = struct.unpack_from("<I", part, 64)[0]
            require(72 + sections * 80 <= length, "أقسام Mach-O غير صالحة.")
            for j in range(sections):
                s = 72 + j * 80
                section_size = struct.unpack_from("<Q", part, s + 40)[0]
                offset = struct.unpack_from("<I", part, s + 48)[0]
                flags = struct.unpack_from("<I", part, s + 64)[0] & 0xFF
                if offset and section_size and flags not in (1, 0xC, 0x12):
                    require(offset + section_size <= len(data), "قسم Mach-O خارج حدود الملف.")
                    boundaries.append(offset)
        if cmd in (0xC, 0x80000018, 0x8000001F, 0x80000023):
            require(length >= 24, "أمر تحميل مكتبة ناقص.")
            offset = struct.unpack_from("<I", part, 8)[0]
            require(24 <= offset < length and b"\0" in part[offset:], "مسار مكتبة غير صالح.")
            dependencies.append(part[offset:].split(b"\0", 1)[0].decode("utf-8", "strict"))
        commands.append((cmd, part))
        cursor += length
    require(cursor == 32 + size, "حجم أوامر Mach-O غير متسق.")
    return subtype & 0xFFFFFF, commands, boundaries, dependencies, size


def inspect_binary(data, kind):
    return [inspect_slice(data[o:o+n], kind) for o, n in slices(data)]


def inject_binary(original, names):
    result = bytearray(original)
    for start, length in slices(original):
        data = original[start:start + length]
        _, commands, boundaries, dependencies, old_size = inspect_slice(data, 2)
        require(bool(boundaries), "تعذر تحديد مساحة ترويسة الملف بأمان.")
        packed = [part for cmd, part in commands if cmd != 0x1D]  # discard stale LC_CODE_SIGNATURE
        for name in names:
            path = "@executable_path/Frameworks/WolFoxInject/" + name
            require(path not in dependencies, "هذه المكتبة محقونة مسبقًا.")
            raw = path.encode() + b"\0"
            size = (24 + len(raw) + 7) & ~7
            packed.append(struct.pack("<6I", 0xC, size, 24, 0, 0x10000, 0x10000) + raw + b"\0" * (size - 24 - len(raw)))
        payload = b"".join(packed)
        end = 32 + len(payload)
        require(end <= min(boundaries), "لا توجد مساحة كافية في الترويسة لإضافة المكتبات بأمان.")
        require(not any(data[32 + old_size:end]), "مساحة الترويسة ليست فارغة؛ أوقِف الدمج لحماية الملف.")
        struct.pack_into("<II", result, start + 16, len(packed), len(payload))
        result[start + 32:start + max(end, 32 + old_size)] = payload + b"\0" * max(0, old_size - len(payload))
    return bytes(result)


def validate_archive(z):
    entries = z.infolist()
    require(len(entries) <= 50000, "عدد ملفات IPA كبير جدًا.")
    total, seen = 0, set()
    for entry in entries:
        name = entry.filename
        path = PurePosixPath(name)
        require(name and not path.is_absolute() and ".." not in path.parts
                and "\\" not in name and "\x00" not in name and ":" not in name
                and str(path) == name.rstrip("/"), "مسار غير آمن داخل IPA.")
        folded = name.rstrip("/").casefold()
        require(folded not in seen, "مسارات مكررة داخل IPA.")
        seen.add(folded)
        mode = entry.external_attr >> 16
        require(stat.S_IFMT(mode) in (0, stat.S_IFREG, stat.S_IFDIR), "روابط أو ملفات خاصة غير مدعومة داخل IPA.")
        require(not entry.flag_bits & 1 and entry.compress_type in (0, 8), "ضغط أو تشفير ZIP غير مدعوم.")
        total += entry.file_size
        require(total <= MAX_EXPANDED and entry.file_size <= MAX_IPA, "حجم IPA بعد الفك يتجاوز الحد.")
        require(entry.file_size <= max(1024**2, entry.compress_size * 1000), "نسبة ضغط غير آمنة.")
    return entries


def process(ipa, libraries, output):
    require(0 < ipa.stat().st_size <= MAX_IPA, "حجم IPA غير صالح.")
    require(len(libraries) <= 8, "الحد الأقصى ثماني مكتبات.")
    with zipfile.ZipFile(ipa) as z:
        entries = validate_archive(z)
        plists = [e for e in entries if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", e.filename)]
        require(len(plists) == 1 and plists[0].file_size <= 2 * 1024**2, "يلزم تطبيق رئيسي واحد داخل Payload.")
        info = plistlib.loads(z.read(plists[0]))
        app = str(PurePosixPath(plists[0].filename).parent)
        executable = info.get("CFBundleExecutable", "")
        require(isinstance(executable, str) and re.fullmatch(r"[^/\\\x00.][^/\\\x00]*", executable), "اسم الملف التنفيذي غير صالح.")
        main = app + "/" + executable
        require(z.getinfo(main).file_size <= MAX_BINARY, "الملف التنفيذي أكبر من الحد.")
        binary = z.read(main)
        # An unmodified IPA may be encrypted. Injection requires inspect_binary below.
        metadata = {"bundle": str(info.get("CFBundleIdentifier", "")),
                    "app": str(info.get("CFBundleDisplayName", info.get("CFBundleName", "تطبيق"))),
                    "version": str(info.get("CFBundleShortVersionString", "")), "libraries": []}
        injected = []
        if libraries:
            app_arches = {s[0] for s in inspect_binary(binary, 2)}
            known = {e.filename.casefold() for e in entries}
            names = set()
            for library in libraries:
                require(re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\.dylib", library.name), "اسم المكتبة يجب أن يكون إنجليزيًا وينتهي بـ dylib.")
                require(library.name.casefold() not in names, "اسم مكتبة مكرر.")
                names.add(library.name.casefold())
                require(0 < library.stat().st_size <= MAX_DYLIB, "حجم المكتبة يتجاوز 32 ميجابايت.")
                raw = library.read_bytes()
                inspected = inspect_binary(raw, 6)
                arches = {s[0] for s in inspected}
                require(app_arches <= arches or 0 in arches, "معمارية المكتبة لا تغطي معمارية التطبيق.")
                dest = app + "/Frameworks/WolFoxInject/" + library.name
                require(dest.casefold() not in known, "توجد مكتبة بهذا الاسم في مسار الدمج.")
                injected.append((dest, raw))
                metadata["libraries"].append({"name": library.name, "dependencies": sorted({d for s in inspected for d in s[3]})})
            binary = inject_binary(binary, [p.name for p in libraries])
            with zipfile.ZipFile(output, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as out:
                for entry in entries:
                    if "_CodeSignature" in PurePosixPath(entry.filename).parts:
                        continue
                    if entry.filename == main:
                        out.writestr(entry, binary)
                    else:
                        with z.open(entry) as src, out.open(entry, "w") as dst:
                            shutil.copyfileobj(src, dst, 1024 * 1024)
                for dest, raw in injected:
                    entry = zipfile.ZipInfo(dest)
                    entry.external_attr = (stat.S_IFREG | 0o755) << 16
                    entry.compress_type = zipfile.ZIP_DEFLATED
                    out.writestr(entry, raw)
            metadata["mode"] = "injected_unsigned"
        else:
            require(z.testzip() is None, "فشل فحص سلامة IPA.")
            shutil.copyfile(ipa, output)
            metadata["mode"] = "unchanged"
    with open(output, "rb") as f:
        metadata["sha256"] = hashlib.file_digest(f, "sha256").hexdigest()
    metadata["size"] = output.stat().st_size
    return metadata


def main():
    signal.signal(signal.SIGALRM, lambda *_: (_ for _ in ()).throw(Invalid("انتهت مهلة المعالجة؛ حاول بملف أصغر.")))
    signal.alarm(280)
    # Linux worker limits supplement the web upload and disk quota limits.
    import resource
    resource.setrlimit(resource.RLIMIT_AS, (1536 * 1024**2, 1536 * 1024**2))
    resource.setrlimit(resource.RLIMIT_FSIZE, (3 * 1024**3, 3 * 1024**3))
    job = Path(sys.argv[1]).resolve()
    spec = json.loads((job / "request.json").read_text())
    output = job / "result.ipa"
    try:
        if spec.get("url"):
            download(spec["url"], job / "input.ipa")
        libraries = [job / "libraries" / name for name in spec["libraries"]]
        require(all(p.parent == job / "libraries" for p in libraries), "مسار مكتبة غير صالح.")
        result = process(job / "input.ipa", libraries, output)
        result.update(ok=True)
    except Invalid as exc:
        result = {"ok": False, "error": str(exc)}
    except Exception:
        result = {"ok": False, "error": "تعذرت قراءة الملف أو تنزيله. تحقق من سلامة IPA والرابط."}
    if not result["ok"]:
        output.unlink(missing_ok=True)
    (job / "result.json").write_text(json.dumps(result, ensure_ascii=False))
    return 0 if result["ok"] else 1


if __name__ == "__main__":
    sys.exit(main())
