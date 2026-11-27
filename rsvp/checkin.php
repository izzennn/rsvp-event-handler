<?php
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';

//officer check first, everything below uses this event
$event_id = filter_input(INPUT_GET, 'event', FILTER_VALIDATE_INT);
if (!$event_id){
    redirect('my_rsvps.php');
}
require_officer_for_event($event_id);
$user_id = require_login();
$pdo = db(true);
$self_url = 'checkin.php?event=' . $event_id;

$show = ($_GET['show'] ?? '') === 'not' ? 'not' : 'all';
$search = trim($_GET['search'] ?? '');
$action = $_POST['action'] ?? '';

//counts RSVP rows with this id at this event, so other orgs' RSVPs can't be touched
function belongs_to_event($pdo, $rsvp_id, $event_id){
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM RSVP WHERE RSVPID = ? AND EventID = ?');
    $stmt->execute([$rsvp_id, $event_id]);
    return (int) $stmt->fetchColumn() === 1;
}

//check in
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'checkin'){
    $rsvp_id = filter_var($_POST['rsvp'] ?? '', FILTER_VALIDATE_INT);
    if (!$rsvp_id || !belongs_to_event($pdo, $rsvp_id, $event_id)){
        flash('error', 'This person does not have an RSVP for this event.');
        redirect($self_url);
    }
    try{
        //trg_check_in_before_insert makes sure the RSVP is confirmed
        $stmt = $pdo->prepare('INSERT INTO CHECK_IN (RSVPID, CheckedInBy, CheckedInAt) VALUES (?, ?, NOW())');
        $stmt->execute([$rsvp_id, $user_id]);
        $_SESSION['last_checkin'] = $rsvp_id;
        flash('success', 'Checked in.');
    }
    catch (PDOException $e){
        $msg = rule_error($e);
        if ($msg === null){
            $msg = (db_code($e) === 1062) ? 'Already checked in.' : 'Something went wrong, and nothing was saved.';
        }
        flash('error', $msg);
    }
    redirect($self_url);
}

//undo, only for the last person this officer checked in
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'undo'){
    $rsvp_id = filter_var($_POST['rsvp'] ?? '', FILTER_VALIDATE_INT);
    if (!$rsvp_id || ($_SESSION['last_checkin'] ?? null) !== $rsvp_id || !belongs_to_event($pdo, $rsvp_id, $event_id)){
        flash('error', 'Only the last check-in can be undone.');
        redirect($self_url);
    }
    $stmt = $pdo->prepare('DELETE FROM CHECK_IN WHERE RSVPID = ?');
    $stmt->execute([$rsvp_id]);
    unset($_SESSION['last_checkin']);
    flash('success', 'Check-in undone.');
    redirect($self_url);
}
$last_checkin = $_SESSION['last_checkin'] ?? null;

$stmt = $pdo->prepare('SELECT Title FROM EVENT WHERE EventID = ?');
$stmt->execute([$event_id]);
$event_title = $stmt->fetchColumn();

//live counter
$stmt = $pdo->prepare(
    "SELECT COUNT(c.CheckInID) AS CheckedIn, COUNT(r.RSVPID) AS ConfirmedRSVPs
     FROM RSVP r
     LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
     WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed'"
);
$stmt->execute([$event_id]);
$counter = $stmt->fetch();

//attendee list, one row per guest, grouped by RSVP below
$stmt = $pdo->prepare(
    "SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, p.GuestName, c.CheckedInAt
     FROM RSVP r
     INNER JOIN USER u ON u.UserID = r.UserID
     LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
     LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
     WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed'
     ORDER BY u.LastName, u.FirstName"
);
$stmt->execute([$event_id]);
$attendees = [];
foreach ($stmt->fetchAll() as $row){
    $id = $row['RSVPID'];
    if (!isset($attendees[$id])){
        $attendees[$id] = $row;
        $attendees[$id]['RSVPStatus'] = 'Confirmed';
        $attendees[$id]['guests'] = [];
    }
    if ($row['GuestName'] !== null){
        $attendees[$id]['guests'][] = $row['GuestName'];
    }
}

if ($search !== ''){
    //search also finds RSVPs that are not confirmed, so the officer can say why
    $stmt = $pdo->prepare(
        'SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.RSVPStatus
         FROM RSVP r
         INNER JOIN USER u ON u.UserID = r.UserID
         WHERE r.EventID = ?
           AND (u.FirstName LIKE ? OR u.LastName LIKE ? OR u.NetID LIKE ?)
         ORDER BY u.LastName, u.FirstName'
    );
    $like = $search . '%';
    $stmt->execute([$event_id, $like, $like, $like]);
    $list = [];
    foreach ($stmt->fetchAll() as $row){
        $list[] = $attendees[$row['RSVPID']] ?? $row;
    }
}
else if ($show === 'not'){
    //not checked in chip
    $stmt = $pdo->prepare(
        "SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName
         FROM RSVP r
         INNER JOIN USER u ON u.UserID = r.UserID
         LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
         WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed' AND c.CheckInID IS NULL
         ORDER BY u.LastName, u.FirstName"
    );
    $stmt->execute([$event_id]);
    $list = [];
    foreach ($stmt->fetchAll() as $row){
        $list[] = $attendees[$row['RSVPID']];
    }
}
else{
    $list = array_values($attendees);
}

$title = 'Check-in: ' . $event_title;
require __DIR__ . '/includes/header.php';
?>
<style>
    .checkin { font-size: 20px; }
    .checkin button, .checkin .button { width: 100%; padding: 14px; font-size: 20px; }
    .person { background: #fff; border: 1px solid #ccc; border-radius: 4px; padding: 12px; margin: 10px 0; }
    .counter { font-size: 28px; font-weight: bold; }
</style>
<div class="checkin">
    <p><a href="manage_event.php?event=<?= e($event_id) ?>">&larr; Back to manage event</a></p>
    <h1><?= e($event_title) ?></h1>
    <p class="counter"><?= e($counter['CheckedIn']) ?> of <?= e($counter['ConfirmedRSVPs']) ?> checked in</p>

    <p>
        <?php if ($show === 'all' && $search === ''){ ?>
            <strong>All</strong> &nbsp; <a href="<?= e($self_url . '&show=not') ?>">Not checked in yet</a>
        <?php } else if ($show === 'not' && $search === ''){ ?>
            <a href="<?= e($self_url) ?>">All</a> &nbsp; <strong>Not checked in yet</strong>
        <?php } else{ ?>
            <a href="<?= e($self_url) ?>">All</a> &nbsp; <a href="<?= e($self_url . '&show=not') ?>">Not checked in yet</a>
        <?php } ?>
    </p>

    <form method="get" action="checkin.php">
        <input type="hidden" name="event" value="<?= e($event_id) ?>">
        <label for="search">Search by name or NetID</label>
        <input id="search" name="search" maxlength="50" value="<?= e($search) ?>">
        <button type="submit">Search</button>
    </form>

    <?php if (count($list) === 0){ ?>
        <p>Nobody found.</p>
    <?php } ?>
    <?php foreach ($list as $p){ ?>
        <div class="person">
            <strong><?= e($p['FirstName'] . ' ' . $p['LastName']) ?></strong> (<?= e($p['NetID'] ?? 'external') ?>)<br>
            <?php if ($p['RSVPStatus'] !== 'Confirmed'){ ?>
                <span class="msg-error" style="display:block">Not confirmed (<?= e($p['RSVPStatus']) ?>). Do not admit.</span>
            <?php } else{ ?>
                <?= e($p['TypeName']) ?> ticket
                <?php if (count($p['guests']) > 0){ ?>
                    &middot; Guests: <?= e(implode(', ', $p['guests'])) ?>
                <?php } ?>
                <br>
                <?php if ($p['CheckedInAt'] !== null){ ?>
                    Checked in at <?= e(date('g:i A', strtotime($p['CheckedInAt']))) ?>
                    <?php if ($last_checkin === (int) $p['RSVPID']){ ?>
                        <form method="post" action="<?= e($self_url) ?>">
                            <input type="hidden" name="action" value="undo">
                            <input type="hidden" name="rsvp" value="<?= e($p['RSVPID']) ?>">
                            <button type="submit">Undo</button>
                        </form>
                    <?php } ?>
                <?php } else{ ?>
                    <form method="post" action="<?= e($self_url) ?>">
                        <input type="hidden" name="action" value="checkin">
                        <input type="hidden" name="rsvp" value="<?= e($p['RSVPID']) ?>">
                        <button type="submit">Check in</button>
                    </form>
                <?php } ?>
            <?php } ?>
        </div>
    <?php } ?>
</div>
<?php require __DIR__ . '/includes/footer.php'; ?>