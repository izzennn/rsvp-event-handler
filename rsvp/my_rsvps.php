<?php
// Check that the member is signed in.
require_once __DIR__ . '/includes/auth.php';

$userId = require_login();
$pdo = db();

// Keep the page on one of its three tabs.
$tab = isset($_GET['tab']) && is_string($_GET['tab'])
    ? $_GET['tab']
    : 'upcoming';

if (!in_array($tab, ['upcoming', 'past', 'invitations'], true)) {
    $tab = 'upcoming';
}

// Format a date from the database for display.
function formatRsvpTime(string $value): string
{
    $dateTime = DateTime::createFromFormat('Y-m-d H:i:s', $value);

    return $dateTime
        ? $dateTime->format('M j, Y g:i A')
        : $value;
}

// Handle a request to cancel an RSVP.
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = isset($_POST['action']) && is_string($_POST['action'])
        ? $_POST['action']
        : '';

    if ($action === 'cancel') {
        $rsvpId = filter_input(INPUT_POST, 'rsvp_id', FILTER_VALIDATE_INT);

        if ($rsvpId === false || $rsvpId === null || $rsvpId < 1) {
            flash('error', 'Choose a valid RSVP to cancel.');
            redirect('my_rsvps.php?tab=upcoming');
        }

        try {
            $pdo->beginTransaction();

            // Lock the event before asking the database to cancel the RSVP.
            $lockStmt = $pdo->prepare("
                SELECT e.EventID
                FROM EVENT e
                INNER JOIN RSVP r ON r.EventID = e.EventID
                WHERE r.RSVPID = ? AND r.UserID = ?
                FOR UPDATE
            ");
            $lockStmt->execute([$rsvpId, $userId]);
            $lockStmt->fetchColumn();

            // The procedure checks ownership and moves up the waitlist if needed.
            $cancelStmt = $pdo->prepare('CALL sp_cancel_rsvp(?, ?)');
            $cancelStmt->execute([$rsvpId, $userId]);

            $pdo->commit();

            flash('success', 'Your RSVP was cancelled.');
            redirect('my_rsvps.php?tab=upcoming');
        } catch (PDOException $e) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }

            $message = rule_error($e);

            if ($message === null) {
                $message = 'Your RSVP could not be cancelled. Please try again.';
            }

            flash('error', $message);
            redirect('my_rsvps.php?tab=upcoming');
        }
    }

    // Handle a request to decline an invitation.
    if ($action === 'decline_invitation') {
        $invitationId = filter_input(
            INPUT_POST,
            'invitation_id',
            FILTER_VALIDATE_INT
        );

        if (
            $invitationId === false
            || $invitationId === null
            || $invitationId < 1
        ) {
            flash('error', 'Choose a valid invitation to decline.');
            redirect('my_rsvps.php?tab=invitations');
        }

        try {
            $declineStmt = $pdo->prepare("
                UPDATE INVITATION
                SET InvitationStatus = 'Declined'
                WHERE InvitationID = ?
                  AND InviteeID = ?
                  AND InvitationStatus = 'Sent'
            ");
            $declineStmt->execute([$invitationId, $userId]);

            if ($declineStmt->rowCount() === 1) {
                flash('success', 'The invitation was declined.');
            } else {
                flash('error', 'This invitation is no longer waiting for an answer.');
            }
        } catch (PDOException $e) {
            flash('error', 'The invitation could not be declined. Please try again.');
        }

        redirect('my_rsvps.php?tab=invitations');
    }

    redirect('my_rsvps.php?tab=' . urlencode($tab));
}

// Count invitations that still need an answer for the tab label.
$countStmt = $pdo->prepare("
    SELECT COUNT(*)
    FROM INVITATION i
    INNER JOIN EVENT e ON e.EventID = i.EventID
    WHERE i.InviteeID = ?
      AND i.InvitationStatus = 'Sent'
      AND e.EventStatus = 'Scheduled'
");
$countStmt->execute([$userId]);
$invitationCount = (int) $countStmt->fetchColumn();

$upcomingRsvps = [];
$guestNames = [];
$waitlistPositions = [];
$statusCounts = [
    'Confirmed' => 0,
    'Waitlisted' => 0,
    'Pending' => 0
];
$pastRsvps = [];
$invitations = [];

// Load the member's upcoming RSVPs and their summary counts.
if ($tab === 'upcoming') {
    $summaryStmt = $pdo->prepare("
        SELECT r.RSVPStatus, COUNT(*) AS RsvpCount
        FROM RSVP r
        INNER JOIN EVENT e ON e.EventID = r.EventID
        WHERE r.UserID = ?
          AND e.StartTime >= NOW()
          AND r.RSVPStatus IN ('Pending', 'Confirmed', 'Waitlisted')
        GROUP BY r.RSVPStatus
    ");
    $summaryStmt->execute([$userId]);

    foreach ($summaryStmt->fetchAll() as $row) {
        $statusCounts[$row['RSVPStatus']] = (int) $row['RsvpCount'];
    }

    $upcomingStmt = $pdo->prepare("
        SELECT r.RSVPID, e.EventID, e.Title, o.OrgName,
               e.StartTime, e.EndTime,
               v.VenueName, v.Building, v.Floor, v.RoomNumber,
               r.TypeName, COUNT(p.GuestNo) AS GuestCount,
               r.RSVPStatus, e.EventStatus,
               a.Reason AS DeclineReason,
               CASE
                   WHEN e.EventStatus = 'Scheduled' AND e.StartTime > NOW()
                   THEN 1
                   ELSE 0
               END AS CanCancel
        FROM RSVP r
        INNER JOIN EVENT e ON e.EventID = r.EventID
        INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
        INNER JOIN VENUE v ON v.VenueID = e.VenueID
        LEFT JOIN PLUS_ONE p ON p.RSVPID = r.RSVPID
        LEFT JOIN APPROVAL a ON a.RSVPID = r.RSVPID
        WHERE r.UserID = ?
          AND e.StartTime >= NOW()
        GROUP BY r.RSVPID, e.EventID, e.Title, o.OrgName,
                 e.StartTime, e.EndTime,
                 v.VenueName, v.Building, v.Floor, v.RoomNumber,
                 r.TypeName, r.RSVPStatus, e.EventStatus, a.Reason
        ORDER BY e.StartTime
    ");
    $upcomingStmt->execute([$userId]);
    $upcomingRsvps = $upcomingStmt->fetchAll();

    // Load all guest names for the upcoming RSVPs.
    $guestStmt = $pdo->prepare("
        SELECT p.RSVPID, p.GuestNo, p.GuestName
        FROM PLUS_ONE p
        INNER JOIN RSVP r ON r.RSVPID = p.RSVPID
        INNER JOIN EVENT e ON e.EventID = r.EventID
        WHERE r.UserID = ?
          AND e.StartTime >= NOW()
        ORDER BY p.RSVPID, p.GuestNo
    ");
    $guestStmt->execute([$userId]);

    foreach ($guestStmt->fetchAll() as $guest) {
        $guestNames[$guest['RSVPID']][] = $guest['GuestName'];
    }

    // Give each waitlisted RSVP its place in line.
    $waitlistStmt = $pdo->prepare("
        SELECT r.RSVPID, COUNT(w.RSVPID) AS WaitlistPosition
        FROM RSVP r
        INNER JOIN EVENT e ON e.EventID = r.EventID
        INNER JOIN RSVP w
            ON w.EventID = r.EventID
           AND w.RSVPStatus = 'Waitlisted'
           AND (
                w.SubmittedAt < r.SubmittedAt
                OR (
                    w.SubmittedAt = r.SubmittedAt
                    AND w.RSVPID <= r.RSVPID
                )
           )
        WHERE r.UserID = ?
          AND r.RSVPStatus = 'Waitlisted'
          AND e.StartTime >= NOW()
        GROUP BY r.RSVPID
    ");
    $waitlistStmt->execute([$userId]);

    foreach ($waitlistStmt->fetchAll() as $row) {
        $waitlistPositions[$row['RSVPID']] = (int) $row['WaitlistPosition'];
    }
}

// Load events that have already started.
if ($tab === 'past') {
    $pastStmt = $pdo->prepare("
        SELECT r.RSVPID, e.EventID, e.Title, o.OrgName,
               e.StartTime, v.VenueName,
               r.TypeName, r.RSVPStatus, c.CheckedInAt
        FROM RSVP r
        INNER JOIN EVENT e ON e.EventID = r.EventID
        INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
        INNER JOIN VENUE v ON v.VenueID = e.VenueID
        LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
        WHERE r.UserID = ?
          AND e.StartTime < NOW()
        ORDER BY e.StartTime DESC
    ");
    $pastStmt->execute([$userId]);
    $pastRsvps = $pastStmt->fetchAll();
}

// Load invitations and the names of the people who sent them.
if ($tab === 'invitations') {
    $invitationStmt = $pdo->prepare("
        SELECT i.InvitationID, e.EventID, e.Title, o.OrgName,
               e.StartTime, v.VenueName,
               u.FirstName AS InviterFirstName,
               u.LastName AS InviterLastName,
               i.SentAt, i.InvitationStatus
        FROM INVITATION i
        INNER JOIN EVENT e ON e.EventID = i.EventID
        INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
        INNER JOIN VENUE v ON v.VenueID = e.VenueID
        INNER JOIN USER u ON u.UserID = i.InvitedBy
        WHERE i.InviteeID = ?
        ORDER BY i.SentAt DESC
    ");
    $invitationStmt->execute([$userId]);
    $invitations = $invitationStmt->fetchAll();
}

$title = 'My RSVPs';
require __DIR__ . '/includes/header.php';
?>

<h1>My RSVPs</h1>

<nav class="tabs" aria-label="My RSVP pages">
    <?php if ($tab === 'upcoming'): ?>
        <strong aria-current="page">Upcoming</strong>
    <?php else: ?>
        <a href="my_rsvps.php?tab=upcoming">Upcoming</a>
    <?php endif; ?>

    <?php if ($tab === 'past'): ?>
        <strong aria-current="page">Past</strong>
    <?php else: ?>
        <a href="my_rsvps.php?tab=past">Past</a>
    <?php endif; ?>

    <?php if ($tab === 'invitations'): ?>
        <strong aria-current="page">
            Invitations (<?= e($invitationCount) ?>)
        </strong>
    <?php else: ?>
        <a href="my_rsvps.php?tab=invitations">
            Invitations (<?= e($invitationCount) ?>)
        </a>
    <?php endif; ?>
</nav>

<?php if ($tab === 'upcoming'): ?>

    <h2>Upcoming RSVPs</h2>

    <p>
        Confirmed: <?= e($statusCounts['Confirmed']) ?> |
        Waitlisted: <?= e($statusCounts['Waitlisted']) ?> |
        Pending: <?= e($statusCounts['Pending']) ?>
    </p>

    <?php if (count($upcomingRsvps) === 0): ?>
        <p>You do not have any upcoming RSVPs.</p>
    <?php else: ?>
        <?php foreach ($upcomingRsvps as $rsvp): ?>
            <section>
                <h3>
                    <a href="event.php?id=<?= (int) $rsvp['EventID'] ?>">
                        <?= e($rsvp['Title']) ?>
                    </a>
                </h3>

                <p><strong>Organization:</strong> <?= e($rsvp['OrgName']) ?></p>
                <p>
                    <strong>Starts:</strong>
                    <?= e(formatRsvpTime($rsvp['StartTime'])) ?>
                </p>
                <p>
                    <strong>Ends:</strong>
                    <?= e(formatRsvpTime($rsvp['EndTime'])) ?>
                </p>
                <p>
                    <strong>Venue:</strong>
                    <?= e($rsvp['VenueName']) ?>,
                    <?= e($rsvp['Building']) ?>,
                    floor <?= e($rsvp['Floor']) ?>,
                    room <?= e($rsvp['RoomNumber']) ?>
                </p>
                <p><strong>Ticket type:</strong> <?= e($rsvp['TypeName']) ?></p>
                <p><strong>Guests:</strong> <?= e($rsvp['GuestCount']) ?></p>
                <p><strong>Status:</strong> <?= e($rsvp['RSVPStatus']) ?></p>

                <?php if ($rsvp['EventStatus'] === 'Cancelled'): ?>
                    <p><strong>Event status:</strong> Cancelled by the organizer</p>
                <?php endif; ?>

                <?php if ($rsvp['DeclineReason'] !== null): ?>
                    <p>
                        <strong>Reason:</strong>
                        <?= e($rsvp['DeclineReason']) ?>
                    </p>
                <?php endif; ?>

                <?php if ($rsvp['RSVPStatus'] === 'Waitlisted'): ?>
                    <p>
                        Waitlist #<?= e(
                            $waitlistPositions[$rsvp['RSVPID']] ?? ''
                        ) ?>
                    </p>
                <?php endif; ?>

                <?php if (!empty($guestNames[$rsvp['RSVPID']])): ?>
                    <p><strong>Guest names:</strong></p>
                    <ul>
                        <?php foreach ($guestNames[$rsvp['RSVPID']] as $guestName): ?>
                            <li><?= e($guestName) ?></li>
                        <?php endforeach; ?>
                    </ul>
                <?php endif; ?>

                <?php if (
                    (int) $rsvp['CanCancel'] === 1
                    && in_array(
                        $rsvp['RSVPStatus'],
                        ['Pending', 'Confirmed', 'Waitlisted'],
                        true
                    )
                ): ?>
                    <form
                        method="post"
                        onsubmit="return confirm('Cancel your RSVP?');"
                    >
                        <input type="hidden" name="action" value="cancel">
                        <input
                            type="hidden"
                            name="rsvp_id"
                            value="<?= (int) $rsvp['RSVPID'] ?>"
                        >
                        <button type="submit">Cancel RSVP</button>
                    </form>
                <?php endif; ?>

                <hr>
            </section>
        <?php endforeach; ?>
    <?php endif; ?>

<?php elseif ($tab === 'past'): ?>

    <h2>Past events</h2>

    <?php if (count($pastRsvps) === 0): ?>
        <p>You do not have any past RSVPs.</p>
    <?php else: ?>
        <table>
            <thead>
                <tr>
                    <th>Event</th>
                    <th>Organization</th>
                    <th>When</th>
                    <th>Venue</th>
                    <th>Ticket type</th>
                    <th>Status</th>
                    <th>Check-in</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($pastRsvps as $rsvp): ?>
                    <tr>
                        <td>
                            <a href="event.php?id=<?= (int) $rsvp['EventID'] ?>">
                                <?= e($rsvp['Title']) ?>
                            </a>
                        </td>
                        <td><?= e($rsvp['OrgName']) ?></td>
                        <td><?= e(formatRsvpTime($rsvp['StartTime'])) ?></td>
                        <td><?= e($rsvp['VenueName']) ?></td>
                        <td><?= e($rsvp['TypeName']) ?></td>
                        <td><?= e($rsvp['RSVPStatus']) ?></td>
                        <td>
                            <?php if ($rsvp['CheckedInAt'] === null): ?>
                                Not checked in
                            <?php else: ?>
                                <?= e(formatRsvpTime($rsvp['CheckedInAt'])) ?>
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

<?php else: ?>

    <h2>Invitations</h2>

    <?php if (count($invitations) === 0): ?>
        <p>You do not have any invitations.</p>
    <?php else: ?>
        <table>
            <thead>
                <tr>
                    <th>Event</th>
                    <th>Organization</th>
                    <th>Starts</th>
                    <th>Venue</th>
                    <th>Invited by</th>
                    <th>Sent</th>
                    <th>Status</th>
                    <th>Actions</th>
                </tr>
            </thead>
            <tbody>
                <?php foreach ($invitations as $invitation): ?>
                    <tr>
                        <td>
                            <a href="event.php?id=<?= (int) $invitation['EventID'] ?>">
                                <?= e($invitation['Title']) ?>
                            </a>
                        </td>
                        <td><?= e($invitation['OrgName']) ?></td>
                        <td><?= e(formatRsvpTime($invitation['StartTime'])) ?></td>
                        <td><?= e($invitation['VenueName']) ?></td>
                        <td>
                            <?= e($invitation['InviterFirstName']) ?>
                            <?= e($invitation['InviterLastName']) ?>
                        </td>
                        <td><?= e(formatRsvpTime($invitation['SentAt'])) ?></td>
                        <td><?= e($invitation['InvitationStatus']) ?></td>
                        <td>
                            <?php if ($invitation['InvitationStatus'] === 'Sent'): ?>
                                <a href="event.php?id=<?= (int) $invitation['EventID'] ?>">
                                    RSVP
                                </a>

                                <form method="post">
                                    <input
                                        type="hidden"
                                        name="action"
                                        value="decline_invitation"
                                    >
                                    <input
                                        type="hidden"
                                        name="invitation_id"
                                        value="<?= (int) $invitation['InvitationID'] ?>"
                                    >
                                    <button type="submit">Decline</button>
                                </form>
                            <?php else: ?>
                                No action needed
                            <?php endif; ?>
                        </td>
                    </tr>
                <?php endforeach; ?>
            </tbody>
        </table>
    <?php endif; ?>

<?php endif; ?>

<?php require __DIR__ . '/includes/footer.php'; ?>