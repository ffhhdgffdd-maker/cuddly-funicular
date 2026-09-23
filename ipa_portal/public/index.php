<?php
declare(strict_types=1);
require __DIR__ . '/../src/bootstrap.php';
$action = is_string($_GET['action'] ?? null) ? $_GET['action'] : '';
$error = '';
$configured = (bool)password_get_info($config['password_hash'])['algo'];
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    // When post_max_size is exceeded PHP empties POST; report it before CSRF parsing.
    if (!$_POST && (int)($_SERVER['CONTENT_LENGTH'] ?? 0) > 0) jsonResponse(['ok'=>false,'error'=>'تجاوز الرفع حد post_max_size في الاستضافة.'], 413);
    csrf();
    if ($action === 'login') {
        try {
            if (!$configured) throw new RuntimeException('لم يُضبط حساب الإدارة. شغّل إعداد الحساب من الخادم.');
            $user = is_string($_POST['username'] ?? null) ? $_POST['username'] : '';
            $password = is_string($_POST['password'] ?? null) ? $_POST['password'] : '';
            if (!loginAttempt($user, $password, $config)) throw new RuntimeException('اسم المستخدم أو كلمة المرور غير صحيحة.');
            session_regenerate_id(true);
            $_SESSION['authenticated'] = true;
            $_SESSION['csrf'] = bin2hex(random_bytes(32));
            header('Location: index.php', true, 303); exit;
        } catch (RuntimeException $exc) { $error = $exc->getMessage(); }
    } else {
        if (!signedIn()) jsonResponse(['ok'=>false,'error'=>'سجّل الدخول أولًا.'], 401);
        if ($action === 'logout') {
            $_SESSION = []; session_destroy();
            setcookie(session_name(), '', ['expires'=>1, 'path'=>'/', 'secure'=>$https, 'httponly'=>true, 'samesite'=>'Strict']);
            header('Location: index.php', true, 303); exit;
        }
        if ($action === 'delete') {
            try {
                $lock = processingLock();
                removeDir(getJob((string)($_POST['id'] ?? '')));
                fclose($lock);
                header('Location: index.php', true, 303); exit;
            } catch (RuntimeException $exc) { $error = $exc->getMessage(); }
        }
        if ($action === 'upload') {
            $job = null; $lock = null;
            try {
                $lock = processingLock();
                cleanup((int)$config['retention_hours']);
                if (count(jobs()) >= $config['max_jobs'] || diskUsage() > $config['storage_quota'] - 3 * 1024**3) {
                    throw new RuntimeException('مساحة التخزين ممتلئة. احذف ملفات سابقة ثم أعد المحاولة.');
                }
                if (disk_free_space(STORE) < 3 * 1024**3) throw new RuntimeException('مساحة القرص غير كافية للمعالجة.');
                $url = is_string($_POST['url'] ?? null) ? trim($_POST['url']) : '';
                if (strlen($url) > 4096) throw new RuntimeException('الرابط أطول من الحد المسموح.');
                $hasFile = isset($_FILES['ipa']) && $_FILES['ipa']['error'] !== UPLOAD_ERR_NO_FILE;
                if (($hasFile ? 1 : 0) + ($url !== '' ? 1 : 0) !== 1) throw new RuntimeException('اختر ملف IPA أو رابطًا مباشرًا واحدًا.');
                $id = bin2hex(random_bytes(16)); $job = STORE . '/job-' . $id;
                mkdir($job, 0700); mkdir($job . '/libraries', 0700);
                if ($hasFile) {
                    if (strtolower(pathinfo($_FILES['ipa']['name'], PATHINFO_EXTENSION)) !== 'ipa') throw new RuntimeException('اختر ملفًا بامتداد IPA.');
                    saveUpload($_FILES['ipa'], $job . '/input.ipa', MAX_IPA);
                }
                $names = []; $items = $_FILES['libraries'] ?? null;
                if ($items && is_array($items['name'])) {
                    if (count($items['name']) > 8) throw new RuntimeException('الحد الأقصى ثماني مكتبات.');
                    foreach ($items['name'] as $i => $name) {
                        if ($items['error'][$i] === UPLOAD_ERR_NO_FILE) continue;
                        if (!is_string($name) || !preg_match('/^[A-Za-z0-9][A-Za-z0-9_.-]{0,99}\.dylib$/D', $name)
                            || in_array(strtolower($name), array_map('strtolower', $names), true)) throw new RuntimeException('اسم مكتبة غير صالح أو مكرر. استخدم اسمًا إنجليزيًا بامتداد dylib.');
                        $file = array_map(fn($values) => $values[$i], $items);
                        saveUpload($file, $job . '/libraries/' . $name, 32 * 1024 * 1024);
                        $names[] = $name;
                    }
                }
                file_put_contents($job . '/request.json', json_encode(['url'=>$url, 'libraries'=>$names]));
                session_write_close();
                ignore_user_abort(true); set_time_limit(310);
                $result = runWorker($job, $config['python']);
                @unlink($job . '/input.ipa'); removeDir($job . '/libraries');
                @unlink($job . '/request.json'); @unlink($job . '/worker.log');
                $result['id'] = $id; $result['download'] = 'index.php?action=download&id=' . $id;
                jsonResponse($result);
            } catch (Throwable $exc) {
                if ($job) removeDir($job);
                $message = $exc instanceof RuntimeException ? $exc->getMessage() : 'تعذر إكمال الطلب. تحقق من الملف وإعدادات الاستضافة.';
                jsonResponse(['ok'=>false,'error'=>$message], 400);
            } finally { if (is_resource($lock)) fclose($lock); }
        }
    }
}
if ($action === 'download') {
    if (!signedIn()) {
        $id = (string)($_GET['id'] ?? '');
        if (preg_match('/^[a-f0-9]{32}$/D', $id)) $_SESSION['download_after_login'] = $id;
        header('Location: index.php', true, 303); exit;
    }
    try {
        $path = getJob((string)($_GET['id'] ?? ''));
        if (filemtime($path) < time() - $config['retention_hours'] * 3600 || !is_file($path . '/result.ipa')) throw new RuntimeException('انتهت صلاحية الملف أو حُذف.');
        $file = fopen($path . '/result.ipa', 'rb');
        if (!$file) throw new RuntimeException('تعذر فتح الملف.');
        $size = fstat($file)['size'];
        session_write_close();
        header('Content-Type: application/octet-stream');
        header('Content-Disposition: attachment; filename="WolFox-' . $_GET['id'] . '.ipa"');
        header('Content-Length: ' . $size);
        fpassthru($file); fclose($file); exit;
    } catch (RuntimeException $exc) { http_response_code(404); $error = $exc->getMessage(); }
}
if (signedIn() && isset($_SESSION['download_after_login'])) {
    $pending = $_SESSION['download_after_login']; unset($_SESSION['download_after_login']);
    header('Location: index.php?action=download&id=' . $pending, true, 303); exit;
}
$history = [];
if (signedIn()) foreach (jobs() as $path) {
    if (is_file($path . '/result.json') && filemtime($path) >= time() - $config['retention_hours'] * 3600) {
        $item = json_decode(file_get_contents($path . '/result.json'), true);
        if ($item && ($item['ok'] ?? false) && is_file($path . '/result.ipa')) {
            $item['id'] = substr(basename($path), 4); $history[] = $item;
        }
    }
}
require __DIR__ . '/../src/view.php';
