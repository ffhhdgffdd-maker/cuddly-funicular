# متطلبات بناء WolFox ومعالجة Crash الإقلاع

## الحالة

- الإصدار: `3.0.1`
- الهدف: Masajid / Mosques
- Bundle ID: `sa.gov.moia.mosques-2`
- نطاق iOS: `15.8 - 27.0`
- آخر بناء runtime-hardening: `240-1`
- GitHub Actions run: `37058057314`
- commit: `8c96677544ee20a9deea4affe2496e6926fc4e36`

## الإصلاحات المطبقة

1. تأجيل تثبيت runtime hooks من `constructor` إلى Main Queue.
2. منع استدعاء أي `original IMP` عندما لا يكون قد تم التقاطه بنجاح.
3. حماية hooks الخاصة بـ:
   - CoreLocation
   - WebKit
   - CoreBluetooth
   - AVFoundation / Camera
   - NSURLSession upload hooks
   - Identifier hooks
4. إضافة تعريف متوافق لـ `WFRecoveryBoth` في `WFInterfacePolicy.h`.
5. تصحيح اختبارات Bluetooth وRecovery Policy.
6. ضبط `release.json` ليتطابق مع فرع `main`.
7. الإبقاء على سلوك زر `X` لإغلاق اللوحة فقط، وعدم اعتباره Hide Tool.

## اختبارات CI المطلوبة

يجب أن تنجح الخطوات التالية قبل اعتماد أي DEB:

- `native-tests`
- Linux location simulation
- Bluetooth codec and interface policy tests
- `Check branch configuration`
- Theos / Clang build
- Package/source matching verification
- SHA256 verification

## تثبيت الحزمة

- Rootful: استخدم ملف `*_Rootful.deb`.
- Rootless: استخدم ملف `*_Rootless.deb`.
- لا تثبت Rootful على بيئة Rootless أو العكس.
- أزل نسخة WolFox السابقة قبل الاختبار، ثم أعد تشغيل SpringBoard أو الجهاز حسب بيئة jailbreak.

## اختبار crash على الجهاز

1. اختبر أولًا بدون تفعيل spoof أو schedule أو Bluetooth أو Camera.
2. افتح التطبيق المضيف وتأكد من بقائه مفتوحًا لمدة 30 ثانية.
3. فعّل GPS فقط واختبر.
4. فعّل Schedule فقط واختبر.
5. فعّل Bluetooth وCamera كل واحدة منفصلة.
6. إذا حدث crash، احفظ ملف `.ips` أو سجل Cr4shed/Syslog مع:
   - اسم التطبيق المضيف
   - Rootful/Rootless
   - رقم build
   - أول 40 سطرًا من `Exception Type`, `Termination Reason`, و`Thread 0`.

> نجاح GitHub Actions يثبت سلامة البناء والاختبارات المتاحة فقط؛ لا يثبت غياب crash runtime على كل جهاز أو كل إصدار iOS.
