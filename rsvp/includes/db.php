<?php
// Database helpers used by every page.

// Returns a PDO connection. Member account by default, officer account when $officer is true.
// One connection of each kind per page load.
function db($officer = false)
{
    static $connections = [];
    $kind = $officer ? 'officer' : 'member';

    if (!isset($connections[$kind])) {
        $config = require __DIR__ . '/../config.php';
        $dsn = 'mysql:host=' . $config['host'] . ';dbname=' . $config['dbname'] . ';charset=utf8mb4';

        $connections[$kind] = new PDO(
            $dsn,
            $config[$kind . '_user'],
            $config[$kind . '_password'],
            [
                PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
                PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
                PDO::ATTR_EMULATE_PREPARES   => false,
            ]
        );
    }
    return $connections[$kind];
}

// If the error came from one of our triggers or procedures (SQLSTATE 45000),
// returns its message, e.g. "This event is full, so the RSVP must be waitlisted."
// Otherwise returns null.
function rule_error($e)
{
    $info = $e->errorInfo;
    if (is_array($info) && isset($info[0]) && $info[0] === '45000') {
        return $info[2] ?? null;
    }
    return null;
}

// Escapes a value for HTML output. Every value printed on a page goes through this.
function e($value)
{
    return htmlspecialchars((string) $value, ENT_QUOTES, 'UTF-8');
}

// Returns the MySQL error number (1062, 1451, 4025, ...) as an int, or 0 if there is none.
// Use this instead of $e->getCode(), which returns '23000' for a duplicate (team rule 2).
function db_code($e)
{
    $info = $e->errorInfo;
    if (is_array($info) && isset($info[1])) {
        return (int) $info[1];
    }
    return 0;
}
