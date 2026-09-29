<?php
declare(strict_types=1);
return [
    'username' => 'admin',
    'password_hash' => '', // Generate with: php bin/setup.php
    'python' => '/usr/bin/python3',
    'https_only' => true,
    'session_seconds' => 3600,
    'retention_hours' => 24,
    'max_jobs' => 20,
    'storage_quota' => 10 * 1024 * 1024 * 1024,
];
