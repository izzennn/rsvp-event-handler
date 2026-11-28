<?php
require_once __DIR__ . '/includes/db.php';
require_once __DIR__ . '/includes/auth.php';

//officer check first, everything below uses this event and org
$event_id = filter_input(INPUT_GET, 'event', FILTER_VALIDATE_INT);
if (!$event_id){
    redirect('my_rsvps.php');
}
$org_id = require_officer_for_event($event_id);
$user_id = require_login();
$pdo = db(true);
$self_url = 'manage_event.php?event=' . $event_id;

$tab = $_GET['tab'] ?? 'rsvps';
if (!in_array($tab, ['rsvps', 'waitlist', 'invitations', 'attendance'], true)){
    $tab = 'rsvps';
}
$statuses = ['Pending', 'Confirmed', 'Waitlisted', 'Declined', 'Cancelled'];
$status = $_GET['status'] ?? '';
if (!in_array($status, $statuses, true)){
    $status = '';
}
$search = trim($_GET['search'] ?? '');
$action = $_POST['action'] ?? '';

//approve or decline
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'review'){
    $rsvp_id = filter_var($_POST['rsvp'] ?? '', FILTER_VALIDATE_INT);
    $decision = $_POST['decision'] ?? '';
    $reason = trim($_POST['reason'] ?? '');
    if (!$rsvp_id || !in_array($decision, ['approve', 'decline'], true)){
        flash('error', 'Only pending RSVPs can be reviewed.');
        redirect($self_url);
    }
    if ($decision === 'decline' && $reason === ''){
        flash('error', 'Please give a reason for declining.');
        redirect($self_url);
    }
    if (mb_strlen($reason) > 255){
        flash('error', 'The reason can be 255 characters max.');
        redirect($self_url);
    }
    try{
        $pdo->beginTransaction();
        //lock must be the very next query (team rule 1)
        $stmt = $pdo->prepare('SELECT EventID, Capacity FROM EVENT WHERE EventID = ? FOR UPDATE');
        $stmt->execute([$event_id]);
        $capacity = (int) $stmt->fetch()['Capacity'];

        //EventID = this page's event, so other orgs' RSVPs can't be reviewed
        $stmt = $pdo->prepare(
            'SELECT r.RSVPStatus, r.TypeName, t.TypeCapacity, COUNT(p.GuestNo) AS Guests
             FROM RSVP r
             INNER JOIN TICKET_TYPE t ON t.EventID = r.EventID AND t.TypeName = r.TypeName
             LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
             WHERE r.RSVPID = ? AND r.EventID = ?
             GROUP BY r.RSVPID, r.RSVPStatus, r.TypeName, t.TypeCapacity'
        );
        $stmt->execute([$rsvp_id, $event_id]);
        $rsvp = $stmt->fetch();
        if (!$rsvp || $rsvp['RSVPStatus'] !== 'Pending'){
            $pdo->rollBack();
            flash('error', 'Only pending RSVPs can be reviewed.');
            redirect($self_url);
        }

        if ($decision === 'approve'){
            //MS1 rule 14: confirmed only if the whole group fits in the event and the ticket type
            $stmt = $pdo->prepare('SELECT fn_spots_taken(?) AS Taken, fn_type_spots_taken(?, ?) AS TypeTaken');
            $stmt->execute([$event_id, $event_id, $rsvp['TypeName']]);
            $spots = $stmt->fetch();
            $group = 1 + (int) $rsvp['Guests'];
            if ($spots['Taken'] + $group <= $capacity && $spots['TypeTaken'] + $group <= $rsvp['TypeCapacity']){
                $new_status = 'Confirmed';
            }
            else{
                $new_status = 'Waitlisted';
            }
            $db_decision = 'Approved';
            $db_reason = null;
        }
        else{
            $new_status = 'Declined';
            $db_decision = 'Declined';
            $db_reason = $reason;
        }

        $stmt = $pdo->prepare('INSERT INTO APPROVAL (RSVPID, ReviewedBy, Decision, DecidedAt, Reason) VALUES (?, ?, ?, NOW(), ?)');
        $stmt->execute([$rsvp_id, $user_id, $db_decision, $db_reason]);
        $stmt = $pdo->prepare('UPDATE RSVP SET RSVPStatus = ? WHERE RSVPID = ?');
        $stmt->execute([$new_status, $rsvp_id]);
        $pdo->commit();

        if ($new_status === 'Confirmed'){
            flash('success', 'Approved, and confirmed.');
        }
        else if ($new_status === 'Waitlisted'){
            flash('success', 'Approved, but the event is full, so they are on the waitlist.');
        }
        else{
            flash('success', 'Declined.');
        }
    }
    catch (PDOException $e){
        if ($pdo->inTransaction()){
            $pdo->rollBack();
        }
        $msg = rule_error($e);
        if ($msg === null){
            $msg = (db_code($e) === 1062) ? 'This RSVP was already reviewed.' : 'Something went wrong, and nothing was saved.';
        }
        flash('error', $msg);
    }
    redirect($self_url);
}

//send invitations
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'invite'){
    $invite_url = $self_url . '&tab=invitations';
    $invitees = [];
    foreach ((array) ($_POST['invitee'] ?? []) as $id){
        $id = filter_var($id, FILTER_VALIDATE_INT);
        if ($id){
            $invitees[] = $id;
        }
    }
    $invitees = array_unique($invitees);
    $stmt = $pdo->prepare('SELECT Visibility FROM EVENT WHERE EventID = ?');
    $stmt->execute([$event_id]);
    if ($stmt->fetchColumn() !== 'Invite-only'){
        flash('error', 'Only invite-only events have invitations.');
        redirect($self_url);
    }
    if (count($invitees) === 0){
        flash('error', 'Choose at least one person to invite.');
        redirect($invite_url);
    }
    try{
        $pdo->beginTransaction();
        $stmt = $pdo->prepare("INSERT INTO INVITATION (EventID, InviteeID, InvitedBy, SentAt, InvitationStatus) VALUES (?, ?, ?, NOW(), 'Sent')");
        foreach ($invitees as $id){
            $stmt->execute([$event_id, $id, $user_id]);
        }
        $pdo->commit();
        flash('success', count($invitees) . ' invitation(s) sent.');
    }
    catch (PDOException $e){
        $pdo->rollBack();
        if (db_code($e) === 1062){
            flash('error', 'Someone you chose was already invited, so no invitations were sent.');
        }
        else{
            flash('error', 'Something went wrong, and no invitations were sent.');
        }
    }
    redirect($invite_url);
}

//header and spots taken card
$stmt = $pdo->prepare(
    'SELECT e.Title, e.StartTime, e.EndTime, e.RSVPDeadline, v.VenueName, v.Building, v.Floor, v.RoomNumber,
            e.RequiresApproval, e.Visibility, e.EventStatus, e.Capacity,
            fn_spots_taken(e.EventID) AS SpotsTaken
     FROM EVENT e
     INNER JOIN VENUE v ON v.VenueID = e.VenueID
     WHERE e.EventID = ?'
);
$stmt->execute([$event_id]);
$event = $stmt->fetch();

//ticket types card
$stmt = $pdo->prepare('SELECT TypeName, fn_type_spots_taken(EventID, TypeName) AS SpotsTaken, TypeCapacity FROM TICKET_TYPE WHERE EventID = ?');
$stmt->execute([$event_id]);
$types = $stmt->fetchAll();

if ($tab === 'rsvps'){
    //status chips
    $stmt = $pdo->prepare('SELECT RSVPStatus, COUNT(*) AS RSVPs FROM RSVP WHERE EventID = ? GROUP BY RSVPStatus ORDER BY RSVPStatus');
    $stmt->execute([$event_id]);
    $counts = [];
    $total = 0;
    foreach ($stmt->fetchAll() as $row){
        $counts[$row['RSVPStatus']] = (int) $row['RSVPs'];
        $total += (int) $row['RSVPs'];
    }

    //guests on each RSVP
    $stmt = $pdo->prepare(
        'SELECT r.RSVPID, COUNT(p.GuestNo) AS Guests
         FROM RSVP r
         LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
         WHERE r.EventID = ?
         GROUP BY r.RSVPID
         ORDER BY r.RSVPID'
    );
    $stmt->execute([$event_id]);
    $guests = [];
    foreach ($stmt->fetchAll() as $row){
        $guests[$row['RSVPID']] = (int) $row['Guests'];
    }

    //search box: same conditions as the S8 search query
    $found = null;
    if ($search !== ''){
        $stmt = $pdo->prepare(
            'SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.RSVPStatus
             FROM RSVP r
             INNER JOIN USER u ON u.UserID = r.UserID
             WHERE r.EventID = ?
               AND (u.FirstName LIKE ? OR u.LastName LIKE ? OR u.NetID LIKE ?)'
        );
        $like = $search . '%';
        $stmt->execute([$event_id, $like, $like, $like]);
        $found = array_column($stmt->fetchAll(), 'RSVPID');
    }

    //table with answers, one row per answer, grouped by RSVP below
    $sql = 'SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, r.SubmittedAt,
                   q.QuestionText, a.AnswerText, r.RSVPStatus
            FROM RSVP r
            INNER JOIN USER u ON u.UserID = r.UserID
            LEFT JOIN RSVP_ANSWER a ON a.RSVPID = r.RSVPID
            LEFT JOIN RSVP_QUESTION q ON q.QuestionID = a.QuestionID
            WHERE r.EventID = ?';
    $params = [$event_id];
    if ($status !== ''){
        $sql .= ' AND r.RSVPStatus = ?';
        $params[] = $status;
    }
    $sql .= ' ORDER BY r.SubmittedAt, r.RSVPID, q.QuestionID';
    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $rsvps = [];
    foreach ($stmt->fetchAll() as $row){
        $id = $row['RSVPID'];
        if ($found !== null && !in_array($id, $found)){
            continue;
        }
        if (!isset($rsvps[$id])){
            $rsvps[$id] = $row;
            $rsvps[$id]['answers'] = [];
        }
        if ($row['QuestionText'] !== null){
            $rsvps[$id]['answers'][] = $row;
        }
    }
}

if ($tab === 'waitlist'){
    $stmt = $pdo->prepare(
        "SELECT r.RSVPID, u.FirstName, u.LastName, u.NetID, r.TypeName, r.SubmittedAt
         FROM RSVP r
         INNER JOIN USER u ON u.UserID = r.UserID
         WHERE r.EventID = ? AND r.RSVPStatus = 'Waitlisted'
         ORDER BY r.SubmittedAt"
    );
    $stmt->execute([$event_id]);
    $waitlist = $stmt->fetchAll();
}

if ($tab === 'invitations' && $event['Visibility'] === 'Invite-only'){
    $user_search = trim($_GET['user_search'] ?? '');
    $people = [];
    if ($user_search !== ''){
        $stmt = $pdo->prepare(
            'SELECT UserID, FirstName, LastName, NetID, Email
             FROM USER
             WHERE (FirstName LIKE ? OR LastName LIKE ? OR Email LIKE ? OR NetID LIKE ?)
               AND UserID NOT IN (SELECT InviteeID FROM INVITATION WHERE EventID = ?)'
        );
        $like = '%' . $user_search . '%';
        $stmt->execute([$like, $like, $like, $user_search . '%', $event_id]);
        $people = $stmt->fetchAll();
    }

    $stmt = $pdo->prepare(
        'SELECT u.FirstName, u.LastName, u.NetID,
                b.FirstName AS InvitedByFirstName, b.LastName AS InvitedByLastName,
                i.SentAt, i.InvitationStatus
         FROM INVITATION i
         INNER JOIN USER u ON u.UserID = i.InviteeID
         INNER JOIN USER b ON b.UserID = i.InvitedBy
         WHERE i.EventID = ?
         ORDER BY i.SentAt'
    );
    $stmt->execute([$event_id]);
    $invitations = $stmt->fetchAll();

    //summary line
    $stmt = $pdo->prepare('SELECT InvitationStatus, COUNT(*) AS Invitations FROM INVITATION WHERE EventID = ? GROUP BY InvitationStatus ORDER BY InvitationStatus');
    $stmt->execute([$event_id]);
    $invite_counts = ['Sent' => 0, 'Accepted' => 0, 'Declined' => 0];
    foreach ($stmt->fetchAll() as $row){
        $invite_counts[$row['InvitationStatus']] = (int) $row['Invitations'];
    }
    $invite_total = array_sum($invite_counts);
}

if ($tab === 'attendance'){
    $stmt = $pdo->prepare(
        "SELECT COUNT(r.RSVPID) AS ConfirmedRSVPs,
                COUNT(c.CheckInID) AS CheckedIn,
                COUNT(r.RSVPID) - COUNT(c.CheckInID) AS NoShows,
                ROUND(100 * COUNT(c.CheckInID) / COUNT(r.RSVPID)) AS AttendanceRate
         FROM RSVP r
         LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
         WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed'"
    );
    $stmt->execute([$event_id]);
    $attendance = $stmt->fetch();

    $stmt = $pdo->prepare(
        'SELECT COUNT(*) AS GuestsCheckedIn
         FROM PLUS_ONE p
         INNER JOIN CHECK_IN c ON c.RSVPID = p.RSVPID
         INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
         WHERE r.EventID = ?'
    );
    $stmt->execute([$event_id]);
    $guests_in = $stmt->fetchColumn();

    $stmt = $pdo->prepare(
        "SELECT r.TypeName, COUNT(r.RSVPID) AS Confirmed, COUNT(c.CheckInID) AS CheckedIn
         FROM RSVP r
         LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
         WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed'
         GROUP BY r.TypeName
         ORDER BY r.TypeName"
    );
    $stmt->execute([$event_id]);
    $by_type = $stmt->fetchAll();

    $stmt = $pdo->prepare(
        "SELECT u.FirstName, u.LastName, r.TypeName
         FROM RSVP r
         INNER JOIN USER u ON u.UserID = r.UserID
         LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
         WHERE r.EventID = ? AND r.RSVPStatus = 'Confirmed' AND c.CheckInID IS NULL
         ORDER BY r.TypeName, u.LastName"
    );
    $stmt->execute([$event_id]);
    $no_shows = $stmt->fetchAll();
}

$title = 'Manage ' . $event['Title'];
require __DIR__ . '/includes/header.php';
?>
<p><a href="org.php?id=<?= e($org_id) ?>">&larr; Back to organization</a></p>
<h1><?= e($event['Title']) ?></h1>
<p>
    <?= e(date('D, M j, Y g:i A', strtotime($event['StartTime']))) ?> to <?= e(date('g:i A', strtotime($event['EndTime']))) ?>
    &middot; <?= e($event['VenueName']) ?>, <?= e($event['Building']) ?>, floor <?= e($event['Floor']) ?><?= $event['RoomNumber'] ? ', room ' . e($event['RoomNumber']) : '' ?>
</p>
<p>
    Status: <strong><?= e($event['EventStatus']) ?></strong>
    &middot; <?= e($event['Visibility']) ?>
    &middot; <?= $event['RequiresApproval'] ? 'Requires approval' : 'No approval needed' ?>
    &middot; RSVP deadline <?= e(date('M j, g:i A', strtotime($event['RSVPDeadline']))) ?>
</p>
<p>
    <?php if ($event['EventStatus'] === 'Scheduled'){ ?>
        <a class="button" href="event_edit.php?event=<?= e($event_id) ?>">Edit</a>
    <?php } ?>
    <a class="button" href="checkin.php?event=<?= e($event_id) ?>">Check-in</a>
</p>

<table>
    <tr><th>Spots taken</th><th>Ticket types</th></tr>
    <tr>
        <td><strong><?= e($event['SpotsTaken']) ?> of <?= e($event['Capacity']) ?></strong></td>
        <td>
            <?php foreach ($types as $t){ ?>
                <?= e($t['TypeName']) ?> <?= e($t['SpotsTaken']) ?> of <?= e($t['TypeCapacity']) ?><br>
            <?php } ?>
        </td>
    </tr>
</table>

<p>
    <?php foreach (['rsvps' => 'RSVPs', 'waitlist' => 'Waitlist', 'invitations' => 'Invitations', 'attendance' => 'Attendance'] as $key => $label){ ?>
        <?php if ($key === $tab){ ?>
            <strong><?= e($label) ?></strong> &nbsp;
        <?php } else{ ?>
            <a href="<?= e($self_url . '&tab=' . $key) ?>"><?= e($label) ?></a> &nbsp;
        <?php } ?>
    <?php } ?>
</p>

<?php if ($tab === 'rsvps'){ ?>
    <p>
        <?php if ($status === ''){ ?>
            <strong>All (<?= e($total) ?>)</strong> &nbsp;
        <?php } else{ ?>
            <a href="<?= e($self_url) ?>">All (<?= e($total) ?>)</a> &nbsp;
        <?php } ?>
        <?php foreach ($statuses as $s){ ?>
            <?php if ($s === $status){ ?>
                <strong><?= e($s) ?> (<?= e($counts[$s] ?? 0) ?>)</strong> &nbsp;
            <?php } else{ ?>
                <a href="<?= e($self_url . '&status=' . $s) ?>"><?= e($s) ?> (<?= e($counts[$s] ?? 0) ?>)</a> &nbsp;
            <?php } ?>
        <?php } ?>
    </p>

    <form method="get" action="manage_event.php">
        <input type="hidden" name="event" value="<?= e($event_id) ?>">
        <?php if ($status !== ''){ ?>
            <input type="hidden" name="status" value="<?= e($status) ?>">
        <?php } ?>
        <label for="search">Search by name or NetID</label>
        <input id="search" name="search" maxlength="50" value="<?= e($search) ?>">
        <button type="submit">Search</button>
    </form>

    <?php if (count($rsvps) === 0){ ?>
        <p>No RSVPs here.</p>
    <?php } else{ ?>
        <table>
            <tr><th>Name</th><th>NetID</th><th>Ticket</th><th>Guests</th><th>Submitted</th><th>Status</th><th>Answers</th><th></th></tr>
            <?php foreach ($rsvps as $r){ ?>
                <tr>
                    <td><?= e($r['FirstName'] . ' ' . $r['LastName']) ?></td>
                    <td><?= e($r['NetID'] ?? '-') ?></td>
                    <td><?= e($r['TypeName']) ?></td>
                    <td><?= e($guests[$r['RSVPID']] ?? 0) ?></td>
                    <td><?= e(date('M j, g:i A', strtotime($r['SubmittedAt']))) ?></td>
                    <td><?= e($r['RSVPStatus']) ?></td>
                    <td>
                        <?php foreach ($r['answers'] as $a){ ?>
                            <strong><?= e($a['QuestionText']) ?></strong><br><?= e($a['AnswerText']) ?><br>
                        <?php } ?>
                    </td>
                    <td>
                        <?php if ($r['RSVPStatus'] === 'Pending'){ ?>
                            <form method="post" action="<?= e($self_url) ?>">
                                <input type="hidden" name="action" value="review">
                                <input type="hidden" name="rsvp" value="<?= e($r['RSVPID']) ?>">
                                <input type="hidden" name="decision" value="approve">
                                <button type="submit">Approve</button>
                            </form>
                            <details>
                                <summary>Decline</summary>
                                <form method="post" action="<?= e($self_url) ?>">
                                    <input type="hidden" name="action" value="review">
                                    <input type="hidden" name="rsvp" value="<?= e($r['RSVPID']) ?>">
                                    <input type="hidden" name="decision" value="decline">
                                    <label for="reason<?= e($r['RSVPID']) ?>">Reason</label>
                                    <textarea id="reason<?= e($r['RSVPID']) ?>" name="reason" maxlength="255" rows="3" required></textarea>
                                    <button type="submit">Decline</button>
                                </form>
                            </details>
                        <?php } ?>
                    </td>
                </tr>
            <?php } ?>
        </table>
    <?php } ?>
<?php } ?>

<?php if ($tab === 'waitlist'){ ?>
    <?php if (count($waitlist) === 0){ ?>
        <p>Nobody is on the waitlist.</p>
    <?php } else{ ?>
        <table>
            <tr><th>#</th><th>Name</th><th>NetID</th><th>Ticket</th><th>Submitted</th></tr>
            <?php foreach ($waitlist as $i => $w){ ?>
                <tr>
                    <td><?= e($i + 1) ?></td>
                    <td><?= e($w['FirstName'] . ' ' . $w['LastName']) ?></td>
                    <td><?= e($w['NetID'] ?? '-') ?></td>
                    <td><?= e($w['TypeName']) ?></td>
                    <td><?= e(date('M j, g:i A', strtotime($w['SubmittedAt']))) ?></td>
                </tr>
            <?php } ?>
        </table>
    <?php } ?>
<?php } ?>

<?php if ($tab === 'invitations'){ ?>
    <?php if ($event['Visibility'] !== 'Invite-only'){ ?>
        <p>This event is <?= e($event['Visibility']) ?>, so it has no invitations.</p>
    <?php } else{ ?>
        <form method="get" action="manage_event.php">
            <input type="hidden" name="event" value="<?= e($event_id) ?>">
            <input type="hidden" name="tab" value="invitations">
            <label for="user_search">Find people to invite (name, email or NetID)</label>
            <input id="user_search" name="user_search" maxlength="100" value="<?= e($user_search) ?>">
            <button type="submit">Search</button>
        </form>

        <?php if ($user_search !== ''){ ?>
            <?php if (count($people) === 0){ ?>
                <p>Nobody found who isn't already invited.</p>
            <?php } else{ ?>
                <form method="post" action="<?= e($self_url . '&tab=invitations') ?>">
                    <input type="hidden" name="action" value="invite">
                    <table>
                        <tr><th></th><th>Name</th><th>NetID</th><th>Email</th></tr>
                        <?php foreach ($people as $p){ ?>
                            <tr>
                                <td><input type="checkbox" name="invitee[]" value="<?= e($p['UserID']) ?>" style="width:auto"></td>
                                <td><?= e($p['FirstName'] . ' ' . $p['LastName']) ?></td>
                                <td><?= e($p['NetID'] ?? '-') ?></td>
                                <td><?= e($p['Email']) ?></td>
                            </tr>
                        <?php } ?>
                    </table>
                    <button type="submit">Send invitations</button>
                </form>
            <?php } ?>
        <?php } ?>

        <h2>Sent invitations</h2>
        <p><?= e($invite_total) ?> sent: <?= e($invite_counts['Accepted']) ?> accepted, <?= e($invite_counts['Sent']) ?> waiting, <?= e($invite_counts['Declined']) ?> declined</p>
        <?php if (count($invitations) > 0){ ?>
            <table>
                <tr><th>Name</th><th>NetID</th><th>Invited by</th><th>Sent</th><th>Status</th></tr>
                <?php foreach ($invitations as $inv){ ?>
                    <tr>
                        <td><?= e($inv['FirstName'] . ' ' . $inv['LastName']) ?></td>
                        <td><?= e($inv['NetID'] ?? '-') ?></td>
                        <td><?= e($inv['InvitedByFirstName'] . ' ' . $inv['InvitedByLastName']) ?></td>
                        <td><?= e(date('M j, g:i A', strtotime($inv['SentAt']))) ?></td>
                        <td><?= e($inv['InvitationStatus']) ?></td>
                    </tr>
                <?php } ?>
            </table>
        <?php } ?>
    <?php } ?>
<?php } ?>

<?php if ($tab === 'attendance'){ ?>
    <table>
        <tr><th>Confirmed</th><th>Checked in</th><th>No-shows</th><th>Attendance rate</th><th>Guests checked in</th></tr>
        <tr>
            <td><?= e($attendance['ConfirmedRSVPs']) ?></td>
            <td><?= e($attendance['CheckedIn']) ?></td>
            <td><?= e($attendance['NoShows']) ?></td>
            <td><?= $attendance['AttendanceRate'] === null ? '-' : e($attendance['AttendanceRate']) . '%' ?></td>
            <td><?= e($guests_in) ?></td>
        </tr>
    </table>

    <h2>By ticket type</h2>
    <table>
        <tr><th>Ticket</th><th>Confirmed</th><th>Checked in</th></tr>
        <?php foreach ($by_type as $t){ ?>
            <tr><td><?= e($t['TypeName']) ?></td><td><?= e($t['Confirmed']) ?></td><td><?= e($t['CheckedIn']) ?></td></tr>
        <?php } ?>
    </table>

    <h2>No-shows</h2>
    <?php if (count($no_shows) === 0){ ?>
        <p>No no-shows.</p>
    <?php } else{ ?>
        <table>
            <tr><th>Name</th><th>Ticket</th></tr>
            <?php foreach ($no_shows as $n){ ?>
                <tr><td><?= e($n['FirstName'] . ' ' . $n['LastName']) ?></td><td><?= e($n['TypeName']) ?></td></tr>
            <?php } ?>
        </table>
    <?php } ?>
<?php } ?>

<?php require __DIR__ . '/includes/footer.php'; ?>