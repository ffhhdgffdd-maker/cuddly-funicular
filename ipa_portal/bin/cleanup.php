<?php
declare(strict_types=1);
if (PHP_SAPI !== 'cli') exit(1);
$base = dirname(__DIR__);
$config = require $base . '/config.example.php';
if (is_file($base . '/config.local.php')) $config = array_replace($config, require $base . '/config.local.php');
if (!is_dir($base . '/storage')) exit(0);
$lock = fopen($base . '/storage/processing.lock', 'c');
if (!$lock || !flock($lock, LOCK_EX | LOCK_NB)) exit(0);
function removeTree(string $path): void {
    foreach (new FilesystemIterator($path) as $entry) {
        if ($entry->isDir() && !$entry->isLink()) removeTree($entry->getPathname()); else unlink($entry->getPathname());
    }
    rmdir($path);
}
foreach (glob($base . '/storage/job-*', GLOB_ONLYDIR) ?: [] as $job) {
    if (filemtime($job) < time() - $config['retention_hours'] * 3600) removeTree($job);
}
foreach (glob($base . '/storage/sessions/sess_*') ?: [] as $session) {
    if (filemtime($session) < time() - $config['session_seconds']) unlink($session);
}
fclose($lock);
