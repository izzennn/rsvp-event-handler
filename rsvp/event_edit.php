<?php
// S7 Create / Edit Event (officers only).
//   Create: event_edit.php?org=OrgID
//   Edit:   event_edit.php?event=EventID
require_once __DIR__ . '/includes/auth.php';

// ---------- Officer check first: every query below uses this checked OrgID ----------
$eventId = filter_input(INPUT_GET, 'event', FILTER_VALIDATE_INT);
if ($eventId) {
    $orgId = require_officer_for_event($eventId);      // edit mode
} else {
    $eventId = null;
    $orgId = filter_input(INPUT_GET, 'org', FILTER_VALIDATE_INT);
    if (!$orgId) {
        redirect('my_rsvps.php');
    }
    require_officer($orgId);                            // create mode
}
$userId = require_login();
$pdo = db(true);
$editing = ($eventId !== null);
$selfUrl = $editing ? 'event_edit.php?event=' . $eventId : 'event_edit.php?org=' . $orgId;

// ---------- Helpers ----------

// '2026-12-10T19:00' -> '2026-12-10 19:00:00', or null if it is not a real date and time.
function to_db_datetime($value)
{
    $value = trim((string) $value);
    if (!preg_match('/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/', $value)) {
        return null;
    }
    $text = str_replace('T', ' ', $value) . ':00';
    $dt = DateTime::createFromFormat('Y-m-d H:i:s', $text);
    if ($dt === false || $dt->format('Y-m-d H:i:s') !== $text) {
        return null;
    }
    return $text;
}

// '2026-12-10 19:00:00' -> '2026-12-10T19:00' for <input type="datetime-local">
function to_input_datetime($value)
{
    return $value ? str_replace(' ', 'T', substr($value, 0, 16)) : '';
}

function whole_number($value)
{
    $n = filter_var($value, FILTER_VALIDATE_INT);
    return ($n === false) ? null : $n;
}

// ---------- Data for the page ----------

// Venue dropdown (S7)
$venues = $pdo->query(
    'SELECT VenueID, VenueName, Building, Floor, RoomNumber, MaxCapacity
     FROM VENUE ORDER BY Building, VenueName'
)->fetchAll();

$orgStmt = $pdo->prepare('SELECT OrgName FROM ORGANIZATION WHERE OrgID = ?');
$orgStmt->execute([$orgId]);
$orgName = $orgStmt->fetchColumn();

// Loads the event and what is locked (S7 edit-mode queries).
function load_event($pdo, $eventId, $orgId)
{
    $stmt = $pdo->prepare('SELECT * FROM EVENT WHERE EventID = ? AND OrgID = ?');
    $stmt->execute([$eventId, $orgId]);
    $event = $stmt->fetch();
    if (!$event) {
        return null;
    }
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM RSVP WHERE EventID = ?');
    $stmt->execute([$eventId]);
    $event['RSVPCount'] = (int) $stmt->fetchColumn();
    $event['SpotsTaken'] = (int) $pdo->query('SELECT fn_spots_taken(' . (int) $eventId . ')')->fetchColumn();

    $stmt = $pdo->prepare(
        'SELECT t.TypeName, t.TypeCapacity, t.Description, COUNT(r.RSVPID) AS RSVPs,
                fn_type_spots_taken(t.EventID, t.TypeName) AS SpotsTaken
         FROM TICKET_TYPE t
         LEFT JOIN RSVP r ON r.EventID = t.EventID AND r.TypeName = t.TypeName
         WHERE t.EventID = ?
         GROUP BY t.EventID, t.TypeName, t.TypeCapacity, t.Description
         ORDER BY t.TypeName'
    );
    $stmt->execute([$eventId]);
    $event['types'] = [];
    foreach ($stmt->fetchAll() as $t) {
        $event['types'][$t['TypeName']] = $t;
    }

    $stmt = $pdo->prepare(
        'SELECT q.QuestionID, q.QuestionText, q.IsRequired, COUNT(a.RSVPID) AS Answers
         FROM RSVP_QUESTION q
         LEFT JOIN RSVP_ANSWER a ON a.QuestionID = q.QuestionID
         WHERE q.EventID = ?
         GROUP BY q.QuestionID, q.QuestionText, q.IsRequired
         ORDER BY q.QuestionID'
    );
    $stmt->execute([$eventId]);
    $event['questions'] = [];
    foreach ($stmt->fetchAll() as $q) {
        $event['questions'][(int) $q['QuestionID']] = $q;
    }

    // Running total of ticket capacity (S7)
    $stmt = $pdo->prepare('SELECT COALESCE(SUM(TypeCapacity), 0) FROM TICKET_TYPE WHERE EventID = ?');
    $stmt->execute([$eventId]);
    $event['TicketTotal'] = (int) $stmt->fetchColumn();
    return $event;
}

$event = null;
if ($editing) {
    $event = load_event($pdo, $eventId, $orgId);
    if (!$event) {
        redirect('my_rsvps.php');
    }
}

$errors = [];
$action = $_POST['action'] ?? '';

// ---------- Cancel event (POST) ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $editing && $action === 'cancel') {
    // Our trigger trg_event_after_update cancels all of its active RSVPs (MS1 rule 17).
    $stmt = $pdo->prepare(
        "UPDATE EVENT SET EventStatus = 'Cancelled'
         WHERE EventID = ? AND OrgID = ? AND EventStatus = 'Scheduled'"
    );
    $stmt->execute([$eventId, $orgId]);
    if ($stmt->rowCount() === 1) {
        flash('success', 'The event was cancelled, and all its RSVPs were cancelled.');
    } else {
        flash('error', 'Only scheduled events can be cancelled.');
    }
    redirect('org.php?id=' . $orgId);
}

// ---------- Save (POST) ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'save') {

    // 1. Read and check the form in PHP, before beginTransaction() (team rule 1).
    $f = [
        'Title'        => trim($_POST['title'] ?? ''),
        'Description'  => trim($_POST['description'] ?? ''),
        'VenueID'      => whole_number($_POST['venue'] ?? ''),
        'StartRaw'     => $_POST['start'] ?? '',
        'EndRaw'       => $_POST['end'] ?? '',
        'DeadlineRaw'  => $_POST['deadline'] ?? '',
        'Capacity'     => whole_number($_POST['capacity'] ?? ''),
        'RequiresApproval' => isset($_POST['approval']) ? 1 : 0,
        'Visibility'   => $_POST['visibility'] ?? '',
        'MaxPlusOnes'  => whole_number($_POST['max_guests'] ?? ''),
    ];
    $start = to_db_datetime($f['StartRaw']);
    $end = to_db_datetime($f['EndRaw']);
    $deadline = to_db_datetime($f['DeadlineRaw']);

    if ($f['Title'] === '' || mb_strlen($f['Title']) > 150) {
        $errors[] = 'Title is required (150 characters max).';
    }
    if (mb_strlen($f['Description']) > 1000) {
        $errors[] = 'Description can be 1000 characters max.';
    }
    if (!in_array($f['Visibility'], ['Public', 'NYU-only', 'Invite-only'], true)) {
        $errors[] = 'Choose a visibility.';
    }
    if (!$start || !$end || !$deadline) {
        $errors[] = 'Start, end and RSVP deadline must all be real dates and times.';
    } else {
        if ($end <= $start) {
            $errors[] = 'The event must end after it starts.';
        }
        if ($deadline >= $start) {
            $errors[] = 'The RSVP deadline must be before the event starts.';
        }
    }
    if ($f['Capacity'] === null || $f['Capacity'] <= 0) {
        $errors[] = 'Capacity must be a whole number above 0.';
    }
    if ($f['MaxPlusOnes'] === null || $f['MaxPlusOnes'] < 0) {
        $errors[] = 'Max guests per RSVP must be 0 or more.';
    }

    // Venue capacity (MS1 rule 2; the database cannot check this, MS3 report 5.1)
    $venueMax = null;
    if ($f['VenueID'] === null) {
        $errors[] = 'Choose a venue.';
    } else {
        $stmt = $pdo->prepare('SELECT MaxCapacity FROM VENUE WHERE VenueID = ?');
        $stmt->execute([$f['VenueID']]);
        $venueMax = $stmt->fetchColumn();
        if ($venueMax === false) {
            $errors[] = 'Choose a venue.';
        } elseif ($f['Capacity'] !== null && $f['Capacity'] > (int) $venueMax) {
            $errors[] = 'Capacity cannot be more than the venue\'s maximum (' . (int) $venueMax . ').';
        }
    }

    // Ticket types: rows of [orig, name, cap, desc, remove]
    $types = [];
    $names = [];
    foreach ((array) ($_POST['tt'] ?? []) as $row) {
        $t = [
            'orig'   => trim((string) ($row['orig'] ?? '')),
            'name'   => trim((string) ($row['name'] ?? '')),
            'cap'    => whole_number($row['cap'] ?? ''),
            'desc'   => trim((string) ($row['desc'] ?? '')),
            'remove' => isset($row['remove']),
        ];
        if ($t['orig'] === '' && $t['name'] === '' && ($row['cap'] ?? '') === '') {
            continue;                                   // empty new row
        }
        if ($editing && $t['orig'] !== '' && !isset($event['types'][$t['orig']])) {
            continue;                                   // not a type of this event
        }
        if ($t['orig'] !== '' && isset($event['types'][$t['orig']]) && $event['types'][$t['orig']]['RSVPs'] > 0) {
            $t['name'] = $t['orig'];                    // in use: name is locked, cannot be removed
            $t['remove'] = false;
        }
        $types[] = $t;
        if ($t['remove']) {
            continue;
        }
        if ($t['name'] === '' || mb_strlen($t['name']) > 50) {
            $errors[] = 'Each ticket type needs a name (50 characters max).';
        }
        if ($t['cap'] === null || $t['cap'] <= 0) {
            $errors[] = 'Each ticket type capacity must be a whole number above 0.';
        }
        if (mb_strlen($t['desc']) > 255) {
            $errors[] = 'Ticket type descriptions can be 255 characters max.';
        }
        $key = mb_strtolower($t['name']);
        if (isset($names[$key])) {
            $errors[] = 'Two ticket types cannot have the same name.';
        }
        $names[$key] = true;
    }
    $kept = array_filter($types, fn($t) => !$t['remove']);
    if (count($kept) === 0) {
        $errors[] = 'Add at least one ticket type.';
    }
    $ticketTotal = array_sum(array_map(fn($t) => (int) $t['cap'], $kept));
    if ($f['Capacity'] !== null && $ticketTotal > $f['Capacity']) {
        $errors[] = 'The ticket type capacities add up to ' . $ticketTotal . ', more than the event capacity (' . $f['Capacity'] . ').';
    }

    // Questions: rows of [id, text, req, remove]
    $questions = [];
    foreach ((array) ($_POST['q'] ?? []) as $row) {
        $q = [
            'id'     => whole_number($row['id'] ?? '') ?? 0,
            'text'   => trim((string) ($row['text'] ?? '')),
            'req'    => isset($row['req']) ? 1 : 0,
            'remove' => isset($row['remove']),
        ];
        if ($q['id'] === 0 && $q['text'] === '') {
            continue;                                   // empty new row
        }
        if ($q['id'] !== 0 && !isset($event['questions'][$q['id']])) {
            continue;                                   // not a question of this event
        }
        $questions[] = $q;
        if (!$q['remove'] && ($q['text'] === '' || mb_strlen($q['text']) > 255)) {
            $errors[] = 'Each question needs text (255 characters max).';
        }
    }
    $errors = array_values(array_unique($errors));

    // 2. Save
    if (!$errors && !$editing) {
        // ----- Create, in one transaction -----
        try {
            $pdo->beginTransaction();
            $stmt = $pdo->prepare(
                "INSERT INTO EVENT (OrgID, VenueID, Title, Description, StartTime, EndTime, Capacity,
                                    RequiresApproval, Visibility, MaxPlusOnes, RSVPDeadline, EventStatus)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'Scheduled')"
            );
            $stmt->execute([$orgId, $f['VenueID'], $f['Title'], $f['Description'] === '' ? null : $f['Description'],
                $start, $end, $f['Capacity'], $f['RequiresApproval'], $f['Visibility'], $f['MaxPlusOnes'], $deadline]);
            $newId = (int) $pdo->lastInsertId();

            $insType = $pdo->prepare('INSERT INTO TICKET_TYPE (EventID, TypeName, TypeCapacity, Description) VALUES (?, ?, ?, ?)');
            foreach ($kept as $t) {
                $insType->execute([$newId, $t['name'], $t['cap'], $t['desc'] === '' ? null : $t['desc']]);
            }
            $insQ = $pdo->prepare('INSERT INTO RSVP_QUESTION (EventID, QuestionText, IsRequired) VALUES (?, ?, ?)');
            foreach ($questions as $q) {
                if (!$q['remove']) {
                    $insQ->execute([$newId, $q['text'], $q['req']]);
                }
            }
            $pdo->commit();
            flash('success', 'The event was created.');
            redirect('manage_event.php?event=' . $newId);
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errors[] = save_error($e);
        }
    }

    if (!$errors && $editing) {
        // ----- Edit, in one transaction. The lock is the very next query (team rule 1). -----
        try {
            $pdo->beginTransaction();
            $lock = $pdo->prepare('SELECT EventID FROM EVENT WHERE EventID = ? AND OrgID = ? FOR UPDATE');
            $lock->execute([$eventId, $orgId]);

            // 3. After the lock: read what is locked and the spots taken now.
            $now = load_event($pdo, $eventId, $orgId);
            if ($now['EventStatus'] !== 'Scheduled') {
                throw new RuntimeException('Only scheduled events can be edited.');
            }
            $hasRsvps = $now['RSVPCount'] > 0;
            if ($hasRsvps) {
                // Approval and visibility are locked once the event has RSVPs: keep the stored values.
                $f['RequiresApproval'] = (int) $now['RequiresApproval'];
                $f['Visibility'] = $now['Visibility'];
            }
            if ($f['Capacity'] < $now['SpotsTaken']) {
                throw new RuntimeException('Capacity cannot go below the ' . $now['SpotsTaken'] . ' spots already taken.');
            }
            foreach ($types as $t) {
                if ($t['orig'] === '' || !isset($now['types'][$t['orig']])) {
                    continue;
                }
                $cur = $now['types'][$t['orig']];
                if ($cur['RSVPs'] > 0 && ($t['remove'] || $t['name'] !== $t['orig'])) {
                    throw new RuntimeException('Ticket type "' . $t['orig'] . '" has RSVPs, so it cannot be renamed or removed.');
                }
                if (!$t['remove'] && $t['cap'] < (int) $cur['SpotsTaken']) {
                    throw new RuntimeException('Ticket type "' . $t['orig'] . '" cannot go below its ' . (int) $cur['SpotsTaken'] . ' spots taken.');
                }
            }
            foreach ($questions as $q) {
                if ($q['id'] === 0) {
                    if ($hasRsvps && $q['req'] && !$q['remove']) {
                        throw new RuntimeException('A new question cannot be required once the event has RSVPs.');
                    }
                    continue;
                }
                $cur = $now['questions'][$q['id']];
                $changed = $q['remove'] || $q['text'] !== $cur['QuestionText'] || $q['req'] !== (int) $cur['IsRequired'];
                if ($cur['Answers'] > 0 && $changed) {
                    throw new RuntimeException('A question that already has answers cannot be changed or removed.');
                }
            }

            // 4. Save
            $stmt = $pdo->prepare(
                'UPDATE EVENT SET VenueID = ?, Title = ?, Description = ?, StartTime = ?, EndTime = ?, Capacity = ?,
                        RequiresApproval = ?, Visibility = ?, MaxPlusOnes = ?, RSVPDeadline = ?
                 WHERE EventID = ? AND OrgID = ?'
            );
            $stmt->execute([$f['VenueID'], $f['Title'], $f['Description'] === '' ? null : $f['Description'],
                $start, $end, $f['Capacity'], $f['RequiresApproval'], $f['Visibility'], $f['MaxPlusOnes'], $deadline,
                $eventId, $orgId]);

            // Ticket types: removals first, then changes, then new ones
            $delType = $pdo->prepare('DELETE FROM TICKET_TYPE WHERE EventID = ? AND TypeName = ?');
            $updType = $pdo->prepare('UPDATE TICKET_TYPE SET TypeName = ?, TypeCapacity = ?, Description = ? WHERE EventID = ? AND TypeName = ?');
            $insType = $pdo->prepare('INSERT INTO TICKET_TYPE (EventID, TypeName, TypeCapacity, Description) VALUES (?, ?, ?, ?)');
            foreach ($types as $t) {
                if ($t['orig'] !== '' && $t['remove']) {
                    $delType->execute([$eventId, $t['orig']]);
                }
            }
            foreach ($types as $t) {
                if ($t['remove']) {
                    continue;
                }
                $desc = $t['desc'] === '' ? null : $t['desc'];
                if ($t['orig'] !== '') {
                    $updType->execute([$t['name'], $t['cap'], $desc, $eventId, $t['orig']]);
                } else {
                    $insType->execute([$eventId, $t['name'], $t['cap'], $desc]);
                }
            }

            // Questions
            $delQ = $pdo->prepare('DELETE FROM RSVP_QUESTION WHERE QuestionID = ? AND EventID = ?');
            $updQ = $pdo->prepare('UPDATE RSVP_QUESTION SET QuestionText = ?, IsRequired = ? WHERE QuestionID = ? AND EventID = ?');
            $insQ = $pdo->prepare('INSERT INTO RSVP_QUESTION (EventID, QuestionText, IsRequired) VALUES (?, ?, ?)');
            foreach ($questions as $q) {
                if ($q['id'] !== 0 && $q['remove']) {
                    $delQ->execute([$q['id'], $eventId]);
                } elseif ($q['id'] !== 0) {
                    $updQ->execute([$q['text'], $q['req'], $q['id'], $eventId]);
                } elseif (!$q['remove']) {
                    $insQ->execute([$eventId, $q['text'], $q['req']]);
                }
            }

            $pdo->commit();
            flash('success', 'Your changes were saved.');
            redirect($selfUrl);
        } catch (RuntimeException $e) {
            $pdo->rollBack();
            $errors[] = $e->getMessage();
        } catch (PDOException $e) {
            $pdo->rollBack();
            $errors[] = save_error($e);
        }
    }
}

// Turns a database error into a message for the officer (raw SQL errors are never shown).
function save_error(PDOException $e)
{
    $rule = rule_error($e);
    if ($rule !== null) {
        return $rule;
    }
    switch (db_code($e)) {
        case 1062: return 'Two ticket types cannot have the same name.';
        case 1451: return 'This is already in use and can\'t be removed.';
        case 4025: return 'Check the times: the event must end after it starts, and the RSVP deadline must be before the start.';
        default:   return 'Something went wrong, and nothing was saved. Please try again.';
    }
}

// ---------- What the form shows: posted values after an error, otherwise the stored event ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST' && $action === 'save') {
    $form = [
        'Title' => $f['Title'], 'Description' => $f['Description'], 'VenueID' => $f['VenueID'],
        'Start' => $f['StartRaw'], 'End' => $f['EndRaw'], 'Deadline' => $f['DeadlineRaw'],
        'Capacity' => $_POST['capacity'] ?? '', 'RequiresApproval' => $f['RequiresApproval'],
        'Visibility' => $f['Visibility'], 'MaxPlusOnes' => $_POST['max_guests'] ?? '',
    ];
    $formTypes = array_map(fn($t) => ['orig' => $t['orig'], 'name' => $t['name'], 'cap' => $t['cap'], 'desc' => $t['desc'], 'remove' => $t['remove']], $types);
    $formQuestions = $questions;
} elseif ($editing) {
    $form = [
        'Title' => $event['Title'], 'Description' => $event['Description'], 'VenueID' => $event['VenueID'],
        'Start' => to_input_datetime($event['StartTime']), 'End' => to_input_datetime($event['EndTime']),
        'Deadline' => to_input_datetime($event['RSVPDeadline']), 'Capacity' => $event['Capacity'],
        'RequiresApproval' => (int) $event['RequiresApproval'], 'Visibility' => $event['Visibility'],
        'MaxPlusOnes' => $event['MaxPlusOnes'],
    ];
    $formTypes = [];
    foreach ($event['types'] as $t) {
        $formTypes[] = ['orig' => $t['TypeName'], 'name' => $t['TypeName'], 'cap' => $t['TypeCapacity'], 'desc' => $t['Description'], 'remove' => false];
    }
    $formQuestions = [];
    foreach ($event['questions'] as $q) {
        $formQuestions[] = ['id' => (int) $q['QuestionID'], 'text' => $q['QuestionText'], 'req' => (int) $q['IsRequired'], 'remove' => false];
    }
} else {
    $form = ['Title' => '', 'Description' => '', 'VenueID' => null, 'Start' => '', 'End' => '', 'Deadline' => '',
             'Capacity' => '', 'RequiresApproval' => 0, 'Visibility' => 'Public', 'MaxPlusOnes' => 0];
    $formTypes = [['orig' => '', 'name' => 'General', 'cap' => '', 'desc' => '', 'remove' => false]];
    $formQuestions = [];
}
if (!$formTypes) {
    $formTypes = [['orig' => '', 'name' => '', 'cap' => '', 'desc' => '', 'remove' => false]];
}

$canEdit = !$editing || $event['EventStatus'] === 'Scheduled';
$locked = $editing && $event['RSVPCount'] > 0;          // approval and visibility locked
$startTotal = $editing ? $event['TicketTotal'] : 0;

$title = $editing ? 'Edit event' : 'Create event';
require __DIR__ . '/includes/header.php';
?>
<p><a href="org.php?id=<?= e($orgId) ?>">&larr; Back to <?= e($orgName) ?></a></p>
<h1><?= $editing ? 'Edit event' : 'Create event' ?></h1>

<?php foreach ($errors as $msg): ?>
    <div class="msg-error"><?= e($msg) ?></div>
<?php endforeach; ?>

<?php if (!$canEdit): ?>
    <div class="msg-error">Only scheduled events can be edited. This event is <?= e($event['EventStatus']) ?>.</div>
<?php else: ?>

<?php if ($editing): ?>
    <p><?= e($event['SpotsTaken']) ?> of <?= e($event['Capacity']) ?> spots taken. <?= e($event['RSVPCount']) ?> RSVPs.</p>
<?php endif; ?>

<form method="post" action="<?= e($selfUrl) ?>">
    <input type="hidden" name="action" value="save">

    <label for="title">Title</label>
    <input id="title" name="title" maxlength="150" required value="<?= e($form['Title']) ?>">

    <label for="description">Description (optional)</label>
    <textarea id="description" name="description" maxlength="1000" rows="4"><?= e($form['Description']) ?></textarea>

    <label for="venue">Venue</label>
    <select id="venue" name="venue" required>
        <option value="">Choose a venue</option>
        <?php foreach ($venues as $v): ?>
            <option value="<?= e($v['VenueID']) ?>" <?= ((int) $form['VenueID'] === (int) $v['VenueID']) ? 'selected' : '' ?>>
                <?= e($v['VenueName']) ?> (max <?= e($v['MaxCapacity']) ?>)
            </option>
        <?php endforeach; ?>
    </select>

    <label for="start">Start</label>
    <input id="start" type="datetime-local" name="start" required value="<?= e($form['Start']) ?>">
    <label for="end">End</label>
    <input id="end" type="datetime-local" name="end" required value="<?= e($form['End']) ?>">
    <label for="deadline">RSVP deadline</label>
    <input id="deadline" type="datetime-local" name="deadline" required value="<?= e($form['Deadline']) ?>">

    <label for="capacity">Capacity</label>
    <input id="capacity" type="number" name="capacity" min="1" required value="<?= e($form['Capacity']) ?>">

    <label>
        <input type="checkbox" name="approval" value="1" style="width:auto"
            <?= $form['RequiresApproval'] ? 'checked' : '' ?> <?= $locked ? 'disabled' : '' ?>>
        Requires approval
    </label>

    <label for="visibility">Visibility</label>
    <select id="visibility" name="visibility" <?= $locked ? 'disabled' : '' ?>>
        <?php foreach (['Public', 'NYU-only', 'Invite-only'] as $vis): ?>
            <option value="<?= e($vis) ?>" <?= $form['Visibility'] === $vis ? 'selected' : '' ?>><?= e($vis) ?></option>
        <?php endforeach; ?>
    </select>
    <?php if ($locked): ?>
        <input type="hidden" name="visibility" value="<?= e($event['Visibility']) ?>">
        <p><small>Approval and visibility are locked because this event already has RSVPs.</small></p>
    <?php endif; ?>

    <label for="max_guests">Max guests per RSVP</label>
    <input id="max_guests" type="number" name="max_guests" min="0" required value="<?= e($form['MaxPlusOnes']) ?>">

    <h2>Ticket types</h2>
    <table>
        <thead><tr><th>Name</th><th>Capacity</th><th>Description</th><th>Remove</th></tr></thead>
        <tbody id="types">
        <?php foreach ($formTypes as $i => $t):
            $inUse = $editing && $t['orig'] !== '' && isset($event['types'][$t['orig']]) && $event['types'][$t['orig']]['RSVPs'] > 0;
            $minCap = $inUse ? (int) $event['types'][$t['orig']]['SpotsTaken'] : 1; ?>
            <tr>
                <td>
                    <input type="hidden" name="tt[<?= $i ?>][orig]" value="<?= e($t['orig']) ?>">
                    <input name="tt[<?= $i ?>][name]" maxlength="50" value="<?= e($t['name']) ?>" <?= $inUse ? 'readonly' : '' ?>>
                    <?php if ($inUse): ?><br><small>In use: <?= e($event['types'][$t['orig']]['RSVPs']) ?> RSVPs</small><?php endif; ?>
                </td>
                <td><input class="tt-cap" type="number" name="tt[<?= $i ?>][cap]" min="<?= max(1, $minCap) ?>" value="<?= e($t['cap']) ?>"></td>
                <td><input name="tt[<?= $i ?>][desc]" maxlength="255" value="<?= e($t['desc']) ?>"></td>
                <td><?php if (!$inUse): ?><input class="tt-remove" type="checkbox" name="tt[<?= $i ?>][remove]" value="1" style="width:auto" <?= $t['remove'] ? 'checked' : '' ?>><?php endif; ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <button type="button" id="add-type">+ Add ticket type</button>
    <p id="ticket-total">Ticket total: <span id="total-value"><?= e($startTotal) ?></span> of <span id="total-cap"><?= e($form['Capacity']) ?></span></p>

    <h2>Questions</h2>
    <?php if ($locked): ?><p><small>This event already has RSVPs, so new questions cannot be required.</small></p><?php endif; ?>
    <table>
        <thead><tr><th>Question</th><th>Required</th><th>Remove</th></tr></thead>
        <tbody id="questions">
        <?php foreach ($formQuestions as $i => $q):
            $answered = $editing && $q['id'] !== 0 && isset($event['questions'][$q['id']]) && $event['questions'][$q['id']]['Answers'] > 0; ?>
            <tr>
                <td>
                    <input type="hidden" name="q[<?= $i ?>][id]" value="<?= e($q['id']) ?>">
                    <input name="q[<?= $i ?>][text]" maxlength="255" value="<?= e($q['text']) ?>" <?= $answered ? 'readonly' : '' ?>>
                    <?php if ($answered): ?><br><small>Locked: <?= e($event['questions'][$q['id']]['Answers']) ?> answers</small><?php endif; ?>
                </td>
                <td>
                    <?php if ($answered): ?>
                        <?= $q['req'] ? 'Yes' : 'No' ?>
                        <?php if ($q['req']): ?><input type="hidden" name="q[<?= $i ?>][req]" value="1"><?php endif; ?>
                    <?php else: ?>
                        <input type="checkbox" name="q[<?= $i ?>][req]" value="1" style="width:auto" <?= $q['req'] ? 'checked' : '' ?>>
                    <?php endif; ?>
                </td>
                <td><?php if (!$answered): ?><input type="checkbox" name="q[<?= $i ?>][remove]" value="1" style="width:auto" <?= $q['remove'] ? 'checked' : '' ?>><?php endif; ?></td>
            </tr>
        <?php endforeach; ?>
        </tbody>
    </table>
    <button type="button" id="add-question">+ Add question</button>

    <p><button type="submit"><?= $editing ? 'Save changes' : 'Create event' ?></button></p>
</form>

<?php if ($editing): ?>
    <form method="post" action="<?= e($selfUrl) ?>" onsubmit="return confirm('Cancel this event? All RSVPs will be cancelled.');">
        <input type="hidden" name="action" value="cancel">
        <button type="submit" style="background:#c62828">Cancel this event</button>
    </form>
<?php endif; ?>

<script>
// Running total of the ticket type capacities; turns red when it goes over the event capacity.
function updateTotal() {
    let total = 0;
    document.querySelectorAll('#types tr').forEach(function (row) {
        const remove = row.querySelector('.tt-remove');
        const cap = row.querySelector('.tt-cap');
        if (cap && !(remove && remove.checked)) {
            total += parseInt(cap.value, 10) || 0;
        }
    });
    const capacity = parseInt(document.getElementById('capacity').value, 10) || 0;
    document.getElementById('total-value').textContent = total;
    document.getElementById('total-cap').textContent = capacity;
    document.getElementById('ticket-total').style.color = (total > capacity) ? '#c62828' : '';
    document.getElementById('ticket-total').style.fontWeight = (total > capacity) ? 'bold' : '';
}
let typeIndex = <?= count($formTypes) ?>;
let questionIndex = <?= count($formQuestions) ?>;
const newQuestionsCanBeRequired = <?= $locked ? 'false' : 'true' ?>;

document.getElementById('add-type').addEventListener('click', function () {
    const i = typeIndex++;
    const row = document.createElement('tr');
    row.innerHTML =
        '<td><input type="hidden" name="tt[' + i + '][orig]" value="">' +
        '<input name="tt[' + i + '][name]" maxlength="50"></td>' +
        '<td><input class="tt-cap" type="number" name="tt[' + i + '][cap]" min="1"></td>' +
        '<td><input name="tt[' + i + '][desc]" maxlength="255"></td>' +
        '<td><input class="tt-remove" type="checkbox" name="tt[' + i + '][remove]" value="1" style="width:auto"></td>';
    document.getElementById('types').appendChild(row);
});
document.getElementById('add-question').addEventListener('click', function () {
    const i = questionIndex++;
    const row = document.createElement('tr');
    row.innerHTML =
        '<td><input type="hidden" name="q[' + i + '][id]" value="0">' +
        '<input name="q[' + i + '][text]" maxlength="255"></td>' +
        '<td>' + (newQuestionsCanBeRequired
            ? '<input type="checkbox" name="q[' + i + '][req]" value="1" style="width:auto">'
            : 'No') + '</td>' +
        '<td><input type="checkbox" name="q[' + i + '][remove]" value="1" style="width:auto"></td>';
    document.getElementById('questions').appendChild(row);
});
document.getElementById('types').addEventListener('input', updateTotal);
document.getElementById('types').addEventListener('change', updateTotal);
document.getElementById('capacity').addEventListener('input', updateTotal);
updateTotal();
</script>

<?php endif; ?>
<?php require __DIR__ . '/includes/footer.php'; ?>
