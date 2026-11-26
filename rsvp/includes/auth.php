<?php
// Session and access-control helpers used by every page.
require_once __DIR__ . '/db.php';

if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// Sends the Location header and stops the page.
function redirect($url)
{
    header('Location: ' . $url);
    exit;
}

// Stores one message ('success' or 'error') that the header prints once.
function flash($type, $message)
{
    $_SESSION['flash'] = ['type' => $type, 'message' => $message];
}

// Sends logged-out visitors to login.php; otherwise returns the user id.
function require_login()
{
    if (!isset($_SESSION['user_id'])) {
        redirect('login.php');
    }
    return (int) $_SESSION['user_id'];
}

// True if the logged-in user is an officer of this organization.
function is_officer($orgId)
{
    if (!isset($_SESSION['user_id'])) {
        return false;
    }
    $stmt = db()->prepare(
        "SELECT 1 FROM ORG_MEMBERSHIP
         WHERE UserID = ? AND OrgID = ? AND Role = 'Officer'"
    );
    $stmt->execute([(int) $_SESSION['user_id'], (int) $orgId]);
    return $stmt->fetch() !== false;
}

// Only officers of this organization may continue.
function require_officer($orgId)
{
    require_login();
    if (!is_officer($orgId)) {
        redirect('my_rsvps.php');
    }
}

// Only officers of the event's organization may continue. Returns the OrgID.
function require_officer_for_event($eventId)
{
    require_login();
    $stmt = db()->prepare('SELECT OrgID FROM EVENT WHERE EventID = ?');
    $stmt->execute([(int) $eventId]);
    $row = $stmt->fetch();

    if ($row === false || !is_officer($row['OrgID'])) {
        redirect('my_rsvps.php');
    }
    return (int) $row['OrgID'];
}
