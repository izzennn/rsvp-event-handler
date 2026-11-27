<?php
// S6 Organization Dashboard (officers only): org.php?id=OrgID
require_once __DIR__ . '/includes/auth.php';

// ---------- Officer check first: every query below uses this checked OrgID ----------
$orgId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
if (!$orgId) {
    redirect('my_rsvps.php');
}
require_officer($orgId);
$userId = require_login();
$pdo = db(true);

$tab = $_GET['tab'] ?? 'events';
if (!in_array($tab, ['events', 'members'], true)) {
    $tab = 'events';
}
$selfUrl = 'org.php?id=' . $orgId;

// Demote or remove a member of THIS organization, never leaving it without an officer.
// $newRole is 'Officer' or 'Member' to change the role, or null to remove the member.
function change_membership($pdo, $orgId, $targetId, $newRole)
{
    $pdo->beginTransaction();

    // Team rule 16: the lock is the very next query after beginTransaction()
    $stmt = $pdo->prepare("SELECT UserID FROM ORG_MEMBERSHIP WHERE OrgID = ? AND Role = 'Officer' FOR UPDATE");
    $stmt->execute([$orgId]);
    $officers = array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));

    $losesOfficer = in_array($targetId, $officers, true) && $newRole !== 'Officer';
    if ($losesOfficer && count($officers) === 1) {
        $pdo->rollBack();
        return 'last_officer';
    }

    if ($newRole === null) {
        // S6 remove a member (their RSVPs stay)
        $stmt = $pdo->prepare('DELETE FROM ORG_MEMBERSHIP WHERE UserID = ? AND OrgID = ?');
        $stmt->execute([$targetId, $orgId]);
    } else {
        // S6 Make officer / Make member
        $stmt = $pdo->prepare('UPDATE ORG_MEMBERSHIP SET Role = ? WHERE UserID = ? AND OrgID = ?');
        $stmt->execute([$newRole, $targetId, $orgId]);
    }

    if ($stmt->rowCount() === 0) {
        $pdo->rollBack();
        return 'no_change';
    }
    $pdo->commit();
    return 'ok';
}

// ---------- Changes (POST). Every one ends with flash() then redirect(). ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // ----- Edit organization details -----
    if ($action === 'edit_details') {
        $orgName      = trim($_POST['org_name'] ?? '');
        $contactEmail = trim($_POST['contact_email'] ?? '');
        $description  = trim($_POST['description'] ?? '');

        if ($orgName === '' || $contactEmail === '') {
            flash('error', 'Name and contact email are required.');
        } elseif (mb_strlen($orgName) > 100) {
            flash('error', 'The name can be at most 100 characters.');
        } elseif (mb_strlen($contactEmail) > 100) {
            flash('error', 'The contact email can be at most 100 characters.');
        } elseif (filter_var($contactEmail, FILTER_VALIDATE_EMAIL) === false) {
            flash('error', 'Enter a valid contact email.');
        } elseif (mb_strlen($description) > 500) {
            flash('error', 'The description can be at most 500 characters.');
        } else {
            try {
                $stmt = $pdo->prepare('UPDATE ORGANIZATION SET OrgName = ?, ContactEmail = ?, Description = ? WHERE OrgID = ?');
                $stmt->execute([$orgName, $contactEmail, ($description === '') ? null : $description, $orgId]);
                flash('success', 'Organization details saved.');
            } catch (PDOException $ex) {
                if (db_code($ex) === 1062) {
                    flash('error', 'That name is already taken.');
                } else {
                    flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
                }
            }
        }
        redirect($selfUrl);
    }

    // ----- Add a member by email or NetID -----
    if ($action === 'add_member') {
        $who = trim($_POST['who'] ?? '');

        if ($who === '') {
            flash('error', 'Enter an email or NetID.');
            redirect($selfUrl . '&tab=members');
        }
        if (mb_strlen($who) > 100) {
            flash('error', 'That email or NetID is too long.');
            redirect($selfUrl . '&tab=members');
        }

        // S6 "find the user" (the value is used twice, so it is passed twice: team rule 19)
        $stmt = $pdo->prepare('SELECT UserID, FirstName, LastName, NetID, Email FROM USER WHERE Email = ? OR NetID = ?');
        $stmt->execute([$who, $who]);
        $found = $stmt->fetch();

        if ($found === false) {
            flash('error', 'No user has that email or NetID.');
            redirect($selfUrl . '&tab=members');
        }
        $name = $found['FirstName'] . ' ' . $found['LastName'];

        $stmt = $pdo->prepare('SELECT COUNT(*) AS AlreadyMember FROM ORG_MEMBERSHIP WHERE UserID = ? AND OrgID = ?');
        $stmt->execute([$found['UserID'], $orgId]);
        if ((int) $stmt->fetch()['AlreadyMember'] > 0) {
            flash('error', $name . ' is already a member.');
            redirect($selfUrl . '&tab=members');
        }

        try {
            $stmt = $pdo->prepare("INSERT INTO ORG_MEMBERSHIP (UserID, OrgID, Role, JoinedDate) VALUES (?, ?, 'Member', CURDATE())");
            $stmt->execute([$found['UserID'], $orgId]);
            flash('success', $name . ' was added as a member.');
        } catch (PDOException $ex) {
            if (db_code($ex) === 1062) {
                flash('error', $name . ' is already a member.');
            } else {
                flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
            }
        }
        redirect($selfUrl . '&tab=members');
    }

    // ----- Make officer / Make member / Remove -----
    if ($action === 'set_role' || $action === 'remove_member') {
        $targetId = filter_input(INPUT_POST, 'user_id', FILTER_VALIDATE_INT);
        $newRole = null;
        if ($action === 'set_role') {
            $newRole = $_POST['role'] ?? '';
            if ($newRole !== 'Officer' && $newRole !== 'Member') {
                $targetId = false;
            }
        }
        if (!$targetId) {
            flash('error', 'Choose a member.');
            redirect($selfUrl . '&tab=members');
        }

        try {
            $result = change_membership($pdo, $orgId, $targetId, $newRole);
        } catch (PDOException $ex) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
            redirect($selfUrl . '&tab=members');
        }

        if ($result === 'last_officer') {
            flash('error', ($targetId === $userId)
                ? "You're the only officer. Make someone else an officer first."
                : 'That member is the only officer. Make someone else an officer first.');
            redirect($selfUrl . '&tab=members');
        }
        if ($result === 'no_change') {
            flash('error', 'Nothing changed: that person is not a member, or already has that role.');
            redirect($selfUrl . '&tab=members');
        }

        if ($action === 'remove_member') {
            flash('success', ($targetId === $userId) ? 'You left the organization.' : 'Member removed.');
        } else {
            flash('success', 'Role changed to ' . $newRole . '.');
        }

        // An officer who removed or demoted themselves can no longer open this page
        if ($targetId === $userId && $newRole !== 'Officer') {
            redirect('profile.php');
        }
        redirect($selfUrl . '&tab=members');
    }

    redirect($selfUrl);
}

// ---------- Page load ----------

// S6 "become Completed": this organization's finished events (time from the database)
$stmt = $pdo->prepare("UPDATE EVENT SET EventStatus = 'Completed' WHERE EventStatus = 'Scheduled' AND EndTime < NOW() AND OrgID = ?");
$stmt->execute([$orgId]);

// S6 organization header
$stmt = $pdo->prepare('SELECT OrgName, Description, ContactEmail FROM ORGANIZATION WHERE OrgID = ?');
$stmt->execute([$orgId]);
$org = $stmt->fetch();

if ($tab === 'events') {
    // S6 events with spots taken
    $stmt = $pdo->prepare(
        'SELECT e.EventID, e.Title, e.StartTime, v.VenueName, e.RequiresApproval, e.Visibility,
                e.EventStatus, e.Capacity, fn_spots_taken(e.EventID) AS SpotsTaken
         FROM EVENT e
         INNER JOIN VENUE v ON v.VenueID = e.VenueID
         WHERE e.OrgID = ?
         ORDER BY e.StartTime'
    );
    $stmt->execute([$orgId]);
    $events = $stmt->fetchAll();

    // S6 "to review": Pending and Waitlisted counts per event
    $stmt = $pdo->prepare(
        "SELECT r.EventID, r.RSVPStatus, COUNT(*) AS RSVPs
         FROM RSVP r
         INNER JOIN EVENT e ON e.EventID = r.EventID
         WHERE e.OrgID = ? AND r.RSVPStatus IN ('Pending', 'Waitlisted')
         GROUP BY r.EventID, r.RSVPStatus
         ORDER BY r.EventID"
    );
    $stmt->execute([$orgId]);
    $review = [];
    foreach ($stmt->fetchAll() as $row) {
        $review[(int) $row['EventID']][$row['RSVPStatus']] = (int) $row['RSVPs'];
    }

    // S6 checked in out of confirmed
    $stmt = $pdo->prepare(
        "SELECT r.EventID, COUNT(c.CheckInID) AS CheckedIn, COUNT(r.RSVPID) AS ConfirmedRSVPs
         FROM RSVP r
         INNER JOIN EVENT e ON e.EventID = r.EventID
         LEFT JOIN CHECK_IN c ON c.RSVPID = r.RSVPID
         WHERE e.OrgID = ? AND r.RSVPStatus = 'Confirmed'
         GROUP BY r.EventID
         ORDER BY r.EventID"
    );
    $stmt->execute([$orgId]);
    $attendance = [];
    foreach ($stmt->fetchAll() as $row) {
        $attendance[(int) $row['EventID']] = $row;
    }
} else {
    // S6 members tab
    $stmt = $pdo->prepare(
        'SELECT u.UserID, u.FirstName, u.LastName, u.NetID, u.Email, u.UserType, m.Role, m.JoinedDate
         FROM ORG_MEMBERSHIP m
         INNER JOIN USER u ON u.UserID = m.UserID
         WHERE m.OrgID = ?
         ORDER BY m.Role DESC, m.JoinedDate'
    );
    $stmt->execute([$orgId]);
    $members = $stmt->fetchAll();
}

$title = $org['OrgName'];
require __DIR__ . '/includes/header.php';
?>
<h1><?= e($org['OrgName']) ?></h1>
<p><?= e($org['Description'] ?? '') ?></p>
<p>Contact: <?= e($org['ContactEmail']) ?></p>

<details>
    <summary>Edit details</summary>
    <form method="post" action="<?= e($selfUrl) ?>">
        <input type="hidden" name="action" value="edit_details">
        <label for="org_name">Name</label>
        <input type="text" id="org_name" name="org_name" maxlength="100" value="<?= e($org['OrgName']) ?>" required>
        <label for="contact_email">Contact email</label>
        <input type="email" id="contact_email" name="contact_email" maxlength="100" value="<?= e($org['ContactEmail']) ?>" required>
        <label for="description">Description</label>
        <textarea id="description" name="description" maxlength="500" rows="3"><?= e($org['Description'] ?? '') ?></textarea>
        <button type="submit">Save details</button>
    </form>
</details>

<p class="tabs">
    <?php foreach (['events' => 'Events', 'members' => 'Members'] as $key => $label): ?>
        <?php if ($key === $tab): ?>
            <strong><?= e($label) ?></strong>
        <?php else: ?>
            <a href="<?= e($selfUrl . '&tab=' . $key) ?>"><?= e($label) ?></a>
        <?php endif; ?>
    <?php endforeach; ?>
</p>

<?php if ($tab === 'events'): ?>
    <a class="button" href="event_edit.php?org=<?= e($orgId) ?>">+ Create event</a>

    <?php if (!$events): ?>
        <p class="muted">No events yet.</p>
    <?php else: ?>
        <table>
            <tr>
                <th>Event</th><th>Starts</th><th>Venue</th><th>Status</th>
                <th>Spots taken</th><th>To review</th><th>Checked in</th><th></th>
            </tr>
            <?php foreach ($events as $event): ?>
                <?php
                $eventId    = (int) $event['EventID'];
                $pending    = $review[$eventId]['Pending'] ?? 0;
                $waitlisted = $review[$eventId]['Waitlisted'] ?? 0;
                $checkedIn  = $attendance[$eventId]['CheckedIn'] ?? 0;
                $confirmed  = $attendance[$eventId]['ConfirmedRSVPs'] ?? 0;
                ?>
                <tr>
                    <td>
                        <?= e($event['Title']) ?><br>
                        <span class="muted"><?= e($event['Visibility']) ?><?= $event['RequiresApproval'] ? ', needs approval' : '' ?></span>
                    </td>
                    <td><?= e($event['StartTime']) ?></td>
                    <td><?= e($event['VenueName']) ?></td>
                    <td><?= e($event['EventStatus']) ?></td>
                    <td><?= e($event['SpotsTaken']) ?> of <?= e($event['Capacity']) ?></td>
                    <td><?= e($pending + $waitlisted) ?> (<?= e($pending) ?> pending, <?= e($waitlisted) ?> waitlisted)</td>
                    <td><?= e($checkedIn) ?> of <?= e($confirmed) ?></td>
                    <td>
                        <a href="manage_event.php?event=<?= e($eventId) ?>">Manage</a>
                        <?php if ($event['EventStatus'] === 'Scheduled'): ?>
                            | <a href="event_edit.php?event=<?= e($eventId) ?>">Edit</a>
                        <?php endif; ?>
                        | <a href="checkin.php?event=<?= e($eventId) ?>">Check-in</a>
                    </td>
                </tr>
            <?php endforeach; ?>
        </table>
    <?php endif; ?>

<?php else: ?>
    <form method="post" action="<?= e($selfUrl . '&tab=members') ?>">
        <input type="hidden" name="action" value="add_member">
        <label for="who">Add a member by email or NetID</label>
        <input type="text" id="who" name="who" maxlength="100" required>
        <button type="submit">Add member</button>
    </form>

    <table>
        <tr><th>Name</th><th>Email</th><th>Role</th><th>Joined</th><th></th></tr>
        <?php foreach ($members as $member): ?>
            <?php
            $memberId = (int) $member['UserID'];
            $isOfficer = ($member['Role'] === 'Officer');
            ?>
            <tr>
                <td><?= e($member['FirstName'] . ' ' . $member['LastName']) ?></td>
                <td><?= e($member['Email']) ?></td>
                <td><?= e($member['Role']) ?></td>
                <td><?= e($member['JoinedDate']) ?></td>
                <td>
                    <form method="post" action="<?= e($selfUrl . '&tab=members') ?>" class="inline">
                        <input type="hidden" name="action" value="set_role">
                        <input type="hidden" name="user_id" value="<?= e($memberId) ?>">
                        <input type="hidden" name="role" value="<?= $isOfficer ? 'Member' : 'Officer' ?>">
                        <button type="submit"><?= $isOfficer ? 'Make member' : 'Make officer' ?></button>
                    </form>
                    <form method="post" action="<?= e($selfUrl . '&tab=members') ?>" class="inline"
                          onsubmit="return confirm('Remove this member from the organization?');">
                        <input type="hidden" name="action" value="remove_member">
                        <input type="hidden" name="user_id" value="<?= e($memberId) ?>">
                        <button type="submit">Remove</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>

<?php require __DIR__ . '/includes/footer.php'; ?>
