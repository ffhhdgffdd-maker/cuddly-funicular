<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
umask(0077);
$path = dirname(__DIR__) . '/config.local.php';
if (is_file($path) && !in_array('--reset', $argv, true)) exit("الحساب موجود. لتغييره استخدم --reset.\n");
fwrite(STDOUT, "اسم المستخدم [admin]: ");
$username = trim((string)fgets(STDIN)) ?: 'admin';
fwrite(STDOUT, "كلمة المرور (لن تُحفظ كنص): ");
$tty = function_exists('stream_isatty') && stream_isatty(STDIN);
if ($tty) system('stty -echo');
try { $password = rtrim((string)fgets(STDIN), "\r\n"); }
finally { if ($tty) system('stty echo'); }
fwrite(STDOUT, "\n");
if (strlen($password) < 8) exit("استخدم كلمة مرور من 8 أحرف على الأقل.\n");
$config = is_file($path) ? require $path : [];
$config['username'] = $username;
$config['password_hash'] = password_hash($password, PASSWORD_DEFAULT);
file_put_contents($path, "<?php\nreturn " . var_export($config, true) . ";\n", LOCK_EX);
chmod($path, 0600);
$sessions = dirname(__DIR__) . '/storage/sessions';
foreach (glob($sessions . '/sess_*') ?: [] as $session) unlink($session);
echo "تم حفظ الحساب وإلغاء الجلسات السابقة. فعّل HTTPS واجعل public هو جذر الموقع.\n";
