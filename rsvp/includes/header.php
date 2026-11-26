<?php
// Page start. Pages set $title before including this file (optional).
require_once __DIR__ . '/auth.php';
$pageTitle = isset($title) ? $title . ' | RSVP Event Handler' : 'RSVP Event Handler';
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title><?= e($pageTitle) ?></title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
<?php if (isset($_SESSION['user_id'])): ?>
<nav class="nav">
    <a href="events.php">Browse Events</a>
    <a href="my_rsvps.php">My RSVPs</a>
    <a href="profile.php">Profile</a>
    <a href="logout.php">Log out</a>
    <span class="nav-hi">Hi, <?= e($_SESSION['first_name'] ?? '') ?></span>
</nav>
<?php endif; ?>
<main class="page">
<?php
if (isset($_SESSION['flash'])) {
    $flash = $_SESSION['flash'];
    unset($_SESSION['flash']);
    $class = ($flash['type'] === 'success') ? 'msg-success' : 'msg-error';
    echo '<div class="' . $class . '">' . e($flash['message']) . '</div>';
}
?>
