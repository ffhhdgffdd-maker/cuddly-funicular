<?php
declare(strict_types=1);
const ROOT = __DIR__ . '/..';
const STORE = ROOT . '/storage';
const MAX_IPA = 512 * 1024 * 1024;
umask(0077);
ini_set('display_errors', '0');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');
header('Referrer-Policy: no-referrer');
header("Content-Security-Policy: default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'; form-action 'self'");
header('Cache-Control: no-store, private');
$config = require ROOT . '/config.example.php';
if (is_file(ROOT . '/config.local.php')) {
    $config = array_replace($config, require ROOT . '/config.local.php');
}
if (getenv('WOLFOX_ADMIN_PASSWORD_HASH')) {
    $config['password_hash'] = getenv('WOLFOX_ADMIN_PASSWORD_HASH');
}
$https = !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
// Set HTTPS at the web server for a trusted TLS proxy; never trust arbitrary forwarded headers.
if ($config['https_only'] && !$https) {
    http_response_code(503);
    exit('هذه الصفحة تتطلب اتصال HTTPS. فعّل شهادة الموقع أولًا.');
}
if ($https) header('Strict-Transport-Security: max-age=31536000');
if (!is_dir(STORE)) mkdir(STORE, 0700, true);
if (!is_dir(STORE . '/sessions')) mkdir(STORE . '/sessions', 0700);
ini_set('session.use_strict_mode', '1');
ini_set('session.use_only_cookies', '1');
ini_set('session.gc_maxlifetime', (string)$config['session_seconds']);
session_save_path(STORE . '/sessions');
session_name('WOLFOXSESSID');
session_set_cookie_params(['lifetime' => 0, 'path' => '/', 'secure' => $https, 'httponly' => true, 'samesite' => 'Strict']);
session_start();
if (isset($_SESSION['last']) && time() - $_SESSION['last'] > $config['session_seconds']) {
    $_SESSION = [];
    session_regenerate_id(true);
}
$_SESSION['last'] = time();
$_SESSION['csrf'] ??= bin2hex(random_bytes(32));

function e(mixed $value): string { return htmlspecialchars((string)$value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8'); }
function signedIn(): bool { return ($_SESSION['authenticated'] ?? false) === true; }
function jsonResponse(array $body, int $status = 200): never {
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($body, JSON_UNESCAPED_UNICODE | JSON_INVALID_UTF8_SUBSTITUTE);
    exit;
}
function csrf(): void {
    if (!is_string($_POST['csrf'] ?? null) || !hash_equals($_SESSION['csrf'], $_POST['csrf'])) {
        jsonResponse(['ok' => false, 'error' => 'انتهت صلاحية الطلب. حدّث الصفحة ثم حاول مجددًا.'], 403);
    }
}
function removeDir(string $path): void {
    if (!is_dir($path) || is_link($path)) return;
    foreach (new FilesystemIterator($path) as $entry) {
        if ($entry->isDir() && !$entry->isLink()) removeDir($entry->getPathname());
        else unlink($entry->getPathname());
    }
    rmdir($path);
}
function jobs(): array {
    $paths = glob(STORE . '/job-*', GLOB_ONLYDIR) ?: [];
    usort($paths, fn($a, $b) => filemtime($b) <=> filemtime($a));
    return $paths;
}
function diskUsage(): int {
    $total = 0;
    foreach (new RecursiveIteratorIterator(new RecursiveDirectoryIterator(STORE, FilesystemIterator::SKIP_DOTS)) as $entry) {
        if ($entry->isFile()) $total += $entry->getSize();
    }
    return $total;
}
function processingLock() {
    $lock = fopen(STORE . '/processing.lock', 'c');
    if (!$lock || !flock($lock, LOCK_EX | LOCK_NB)) {
        throw new RuntimeException('توجد عملية قيد المعالجة. انتظر اكتمالها ثم حاول مجددًا.');
    }
    return $lock;
}
function cleanup(int $hours): void {
    foreach (jobs() as $path) {
        if (filemtime($path) < time() - $hours * 3600) removeDir($path);
    }
}
function getJob(string $id): string {
    if (!preg_match('/^[a-f0-9]{32}$/D', $id)) throw new RuntimeException('الملف غير موجود.');
    $path = STORE . '/job-' . $id;
    if (!is_file($path . '/result.json')) throw new RuntimeException('الملف غير موجود.');
    return $path;
}
function saveUpload(array $file, string $destination, int $max): void {
    if (($file['error'] ?? UPLOAD_ERR_NO_FILE) !== UPLOAD_ERR_OK || !is_string($file['tmp_name'] ?? null)
        || !is_uploaded_file($file['tmp_name']) || $file['size'] < 1 || $file['size'] > $max) {
        throw new RuntimeException('فشل رفع الملف أو تجاوز الحد المسموح. تحقق أيضًا من حدود الاستضافة.');
    }
    if (!move_uploaded_file($file['tmp_name'], $destination)) throw new RuntimeException('تعذر حفظ الملف المرفوع.');
    chmod($destination, 0600);
}
function loginAttempt(string $user, string $password, array $config): bool {
    $handle = fopen(STORE . '/login-limit.json', 'c+');
    if (!$handle || !flock($handle, LOCK_EX)) throw new RuntimeException('تعذر التحقق من الدخول.');
    try {
        $state = json_decode(stream_get_contents($handle), true) ?: ['since' => time(), 'count' => 0];
        if (time() - $state['since'] >= 900) $state = ['since' => time(), 'count' => 0];
        if ($state['count'] >= 8) throw new RuntimeException('محاولات كثيرة. انتظر 15 دقيقة ثم حاول مجددًا.');
        $valid = password_verify($password, $config['password_hash']) && hash_equals($config['username'], $user);
        $state['count'] = $valid ? 0 : $state['count'] + 1;
        ftruncate($handle, 0); rewind($handle); fwrite($handle, json_encode($state)); fflush($handle);
        return $valid;
    } finally { flock($handle, LOCK_UN); fclose($handle); }
}
function runWorker(string $job, string $python): array {
    if (!function_exists('proc_open')) throw new RuntimeException('الاستضافة لا تتيح تشغيل عامل الدمج. يلزم تفعيل proc_open.');
    $proc = proc_open([$python, '-I', ROOT . '/bin/ipa_worker.py', $job],
        [0 => ['file', '/dev/null', 'r'], 1 => ['file', $job . '/worker.log', 'a'], 2 => ['file', $job . '/worker.log', 'a']], $pipes);
    if (!is_resource($proc)) throw new RuntimeException('تعذر تشغيل Python على الخادم.');
    $deadline = microtime(true) + 290;
    try {
        do {
            $status = proc_get_status($proc);
            if (!$status['running']) break;
            if (microtime(true) > $deadline) {
                proc_terminate($proc, 9);
                throw new RuntimeException('انتهت مهلة المعالجة. حاول بملف أصغر.');
            }
            usleep(100000);
        } while (true);
    } finally { proc_close($proc); }
    $result = is_file($job . '/result.json') ? json_decode(file_get_contents($job . '/result.json'), true) : null;
    if (!is_array($result)) throw new RuntimeException('تعذر تشغيل المعالجة. تحقق من Python 3.11 أو أحدث وصلاحيات الخادم.');
    if (!($result['ok'] ?? false)) throw new RuntimeException($result['error'] ?? 'فشلت المعالجة.');
    return $result;
}
