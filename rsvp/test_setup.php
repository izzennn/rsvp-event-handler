<?php
// Setup check for Task 1. Delete this file before the final submission.
// Log in first to get past require_login(). Until login.php exists you can add
// $_SESSION['user_id'] = 1; below the require lines, but NEVER commit that line:
// it would let anyone on the server past the login check.
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';

$userId = require_login();
$title = 'Setup check';
require __DIR__ . '/includes/header.php';

echo '<h1>Setup check</h1>';
echo '<p>Logged in as user ' . e($userId) . '.</p>';

// 1. Member account can read EVENT
$count = db()->query('SELECT COUNT(*) AS n FROM EVENT')->fetch()['n'];
echo '<p>Events (member account): ' . e($count) . '</p>';

// 2. Member account must NOT read RSVP_ANSWER (expect error 1142)
try {
    db()->query('SELECT COUNT(*) FROM RSVP_ANSWER');
    echo '<div class="msg-error">Member account CAN read RSVP_ANSWER. security.sql is not set up right.</div>';
} catch (PDOException $ex) {
    echo '<div class="msg-success">Member account blocked from RSVP_ANSWER (error ' . e(db_code($ex)) . ', expected 1142).</div>';
}

// 3. Officer account CAN read RSVP_ANSWER (expect 162)
$answers = db(true)->query('SELECT COUNT(*) AS n FROM RSVP_ANSWER')->fetch()['n'];
echo '<div class="msg-success">Officer account reads RSVP_ANSWER: ' . e($answers) . ' rows (expected 162).</div>';

require __DIR__ . '/includes/footer.php';
