<?php
// Check that the member is signed in.
require_once __DIR__ . '/includes/auth.php';

$userId = require_login();
$pdo = db();

// Send the member back if the event number is missing or invalid.
$eventId = filter_input(INPUT_GET, 'id', FILTER_VALIDATE_INT);
if ($eventId === false || $eventId === null || $eventId < 1) {
    redirect('events.php');
}

// Find the event only when this member is allowed to view it.
function getVisibleEvent(PDO $pdo, int $eventId, int $userId): ?array
{
    $stmt = $pdo->prepare("
        SELECT e.EventID, e.Title, e.Description, o.OrgName AS HostedBy,
               e.StartTime, e.EndTime, e.RSVPDeadline,
               v.VenueName, v.Building, v.Floor, v.RoomNumber,
               e.RequiresApproval, e.Visibility, e.MaxPlusOnes,
               e.EventStatus, e.Capacity,
               fn_spots_taken(e.EventID) AS SpotsTaken,
               CASE WHEN e.RSVPDeadline >= NOW() THEN 1 ELSE 0 END AS DeadlineOpen
        FROM EVENT e
        INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
        INNER JOIN VENUE v ON v.VenueID = e.VenueID
        WHERE e.EventID = ?
          AND (
                e.Visibility = 'Public'
                OR (
                    e.Visibility = 'NYU-only'
                    AND (SELECT UserType FROM USER WHERE UserID = ?) = 'NYU'
                )
                OR (
                    e.Visibility = 'Invite-only'
                    AND e.EventID IN (
                        SELECT EventID
                        FROM INVITATION
                        WHERE InviteeID = ?
                          AND InvitationStatus <> 'Declined'
                    )
                )
          )
    ");
    $stmt->execute([$eventId, $userId, $userId]);

    $event = $stmt->fetch();
    return ($event === false) ? null : $event;
}

// Format a date from the database for display.
function formatEventTime(string $value): string
{
    $dateTime = DateTime::createFromFormat('Y-m-d H:i:s', $value);

    return $dateTime
        ? $dateTime->format('M j, Y g:i A')
        : $value;
}

$event = getVisibleEvent($pdo, $eventId, $userId);

if ($event === null) {
    http_response_code(404);
    $pageTitle = 'Event not available';
    require_once __DIR__ . '/includes/header.php';
    ?>
    <h1>Event not available</h1>
    <div class="msg-error">You can't view this event.</div>
    <p><a href="events.php">Back to Browse Events</a></p>
    <?php
    require_once __DIR__ . '/includes/footer.php';
    exit;
}

// Read the information needed for the event page.
$userStmt = $pdo->prepare('SELECT UserType FROM USER WHERE UserID = ?');
$userStmt->execute([$userId]);
$userType = (string) $userStmt->fetchColumn();

$typeStmt = $pdo->prepare("
    SELECT TypeName, Description, TypeCapacity,
           TypeCapacity - fn_type_spots_taken(EventID, TypeName) AS SpotsLeft
    FROM TICKET_TYPE
    WHERE EventID = ?
    ORDER BY TypeCapacity DESC
");
$typeStmt->execute([$eventId]);
$ticketTypes = $typeStmt->fetchAll();

$questionStmt = $pdo->prepare("
    SELECT QuestionID, QuestionText, IsRequired
    FROM RSVP_QUESTION
    WHERE EventID = ?
    ORDER BY QuestionID
");
$questionStmt->execute([$eventId]);
$questions = $questionStmt->fetchAll();

$rsvpStmt = $pdo->prepare("
    SELECT r.RSVPID, r.TypeName, r.SubmittedAt, r.RSVPStatus,
           a.Reason AS DeclineReason
    FROM RSVP r
    LEFT JOIN APPROVAL a ON a.RSVPID = r.RSVPID
    WHERE r.EventID = ? AND r.UserID = ?
");
$rsvpStmt->execute([$eventId, $userId]);
$existingRsvp = $rsvpStmt->fetch();

$existingGuests = [];
if ($existingRsvp !== false) {
    $guestStmt = $pdo->prepare("
        SELECT GuestNo, GuestName
        FROM PLUS_ONE
        WHERE RSVPID = ?
        ORDER BY GuestNo
    ");
    $guestStmt->execute([$existingRsvp['RSVPID']]);
    $existingGuests = $guestStmt->fetchAll();
}

// Decide whether this member can submit an RSVP.
$hasExistingRsvp = ($existingRsvp !== false);
$deadlineOpen = ((int) $event['DeadlineOpen'] === 1);
$isNyuOnlyForNyuMember = (
    $event['Visibility'] !== 'NYU-only' || $userType === 'NYU'
);

$canSubmitRsvp = (
    $event['EventStatus'] === 'Scheduled'
    && $deadlineOpen
    && !$hasExistingRsvp
    && $isNyuOnlyForNyuMember
);

// Save a new RSVP.
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    if ($hasExistingRsvp) {
        flash('error', 'You already have an RSVP for this event.');
        redirect('event.php?id=' . $eventId);
    }

    if ($event['EventStatus'] !== 'Scheduled') {
        $message = ($event['EventStatus'] === 'Cancelled')
            ? 'This event was cancelled.'
            : 'This event is not open for RSVPs.';
        flash('error', $message);
        redirect('event.php?id=' . $eventId);
    }

    if (!$deadlineOpen) {
        flash('error', 'The RSVP deadline has passed.');
        redirect('event.php?id=' . $eventId);
    }

    if (!$isNyuOnlyForNyuMember) {
        flash('error', 'Only NYU users can RSVP to this event.');
        redirect('event.php?id=' . $eventId);
    }

    // Check that the chosen ticket belongs to this event.
    $ticketTypeName = (
        isset($_POST['ticket_type']) && is_string($_POST['ticket_type'])
    ) ? trim($_POST['ticket_type']) : '';

    $selectedTicket = null;
    foreach ($ticketTypes as $ticketType) {
        if ($ticketType['TypeName'] === $ticketTypeName) {
            $selectedTicket = $ticketType;
            break;
        }
    }

    $validationError = null;
    if ($selectedTicket === null) {
        $validationError = 'Choose a ticket type for this event.';
    }

    // Check the guest names and email addresses.
    $postedGuests = $_POST['guests'] ?? [];
    if (!is_array($postedGuests)) {
        $postedGuests = [];
        $validationError = 'Enter valid guest details.';
    }

    $postedGuests = array_values($postedGuests);
    $guests = [];

    if (count($postedGuests) > (int) $event['MaxPlusOnes']) {
        $validationError = 'This event allows fewer guests than you entered.';
    }

    foreach ($postedGuests as $guest) {
        if ($validationError !== null) {
            break;
        }

        if (!is_array($guest)) {
            $validationError = 'Enter valid guest details.';
            break;
        }

        $guestName = (
            isset($guest['name']) && is_string($guest['name'])
        ) ? trim($guest['name']) : '';

        $guestEmail = (
            isset($guest['email']) && is_string($guest['email'])
        ) ? trim($guest['email']) : '';

        if ($guestName === '') {
            $validationError = 'Enter a name for each guest.';
        } elseif (mb_strlen($guestName) > 100) {
            $validationError = 'Guest names can be at most 100 characters.';
        } elseif (mb_strlen($guestEmail) > 100) {
            $validationError = 'Guest emails can be at most 100 characters.';
        } elseif (
            $guestEmail !== ''
            && filter_var($guestEmail, FILTER_VALIDATE_EMAIL) === false
        ) {
            $validationError = 'Enter a valid guest email.';
        } else {
            $guests[] = [
                'name' => $guestName,
                'email' => ($guestEmail === '') ? null : $guestEmail
            ];
        }
    }

    // Save answers only for this event's questions.
    $postedAnswers = $_POST['answers'] ?? [];
    if (!is_array($postedAnswers)) {
        $postedAnswers = [];
    }

    $answers = [];
    foreach ($questions as $question) {
        if ($validationError !== null) {
            break;
        }

        $questionId = (int) $question['QuestionID'];
        $rawAnswer = $postedAnswers[$questionId] ?? '';

        if (!is_string($rawAnswer)) {
            $validationError = 'Enter a text answer for each question.';
            break;
        }

        $answer = trim($rawAnswer);

        if ((int) $question['IsRequired'] === 1 && $answer === '') {
            $validationError = 'Answer every required question.';
        } elseif (mb_strlen($answer) > 500) {
            $validationError = 'Answers can be at most 500 characters.';
        } elseif ($answer !== '') {
            $answers[$questionId] = $answer;
        }
    }

    if ($validationError !== null) {
        flash('error', $validationError);
        redirect('event.php?id=' . $eventId);
    }

    try {
        $pdo->beginTransaction();

        // Lock the event before checking its capacity.
        $lockStmt = $pdo->prepare("
            SELECT Capacity, RequiresApproval
            FROM EVENT
            WHERE EventID = ?
            FOR UPDATE
        ");
        $lockStmt->execute([$eventId]);
        $lockedEvent = $lockStmt->fetch();

        if ($lockedEvent === false) {
            throw new RuntimeException('The event could not be found.');
        }

        // Read the current ticket capacity after locking the event.
        $typeCapacityStmt = $pdo->prepare("
            SELECT TypeCapacity
            FROM TICKET_TYPE
            WHERE EventID = ? AND TypeName = ?
        ");
        $typeCapacityStmt->execute([$eventId, $selectedTicket['TypeName']]);
        $typeCapacity = $typeCapacityStmt->fetchColumn();

        if ($typeCapacity === false) {
            throw new RuntimeException('The ticket type could not be found.');
        }

        // Count the member and guests when choosing the RSVP status.
        $spotsStmt = $pdo->prepare("
            SELECT fn_spots_taken(?) AS EventSpots,
                   fn_type_spots_taken(?, ?) AS TypeSpots
        ");
        $spotsStmt->execute([
            $eventId,
            $eventId,
            $selectedTicket['TypeName']
        ]);
        $spots = $spotsStmt->fetch();

        $groupSize = 1 + count($guests);

        if ((int) $lockedEvent['RequiresApproval'] === 1) {
            $rsvpStatus = 'Pending';
        } elseif (
            (int) $spots['EventSpots'] + $groupSize <= (int) $lockedEvent['Capacity']
            && (int) $spots['TypeSpots'] + $groupSize <= (int) $typeCapacity
        ) {
            $rsvpStatus = 'Confirmed';
        } else {
            $rsvpStatus = 'Waitlisted';
        }

        // Save the RSVP, guests and answers together.
        $insertRsvp = $pdo->prepare("
            INSERT INTO RSVP (EventID, TypeName, UserID, SubmittedAt, RSVPStatus)
            VALUES (?, ?, ?, NOW(), ?)
        ");
        $insertRsvp->execute([
            $eventId,
            $selectedTicket['TypeName'],
            $userId,
            $rsvpStatus
        ]);

        $rsvpId = (int) $pdo->lastInsertId();

        $insertGuest = $pdo->prepare("
            INSERT INTO PLUS_ONE (RSVPID, GuestNo, GuestName, GuestEmail)
            VALUES (?, ?, ?, ?)
        ");

        foreach ($guests as $index => $guest) {
            $insertGuest->execute([
                $rsvpId,
                $index + 1,
                $guest['name'],
                $guest['email']
            ]);
        }

        $insertAnswer = $pdo->prepare("
            INSERT INTO RSVP_ANSWER (RSVPID, QuestionID, AnswerText)
            VALUES (?, ?, ?)
        ");

        foreach ($answers as $questionId => $answer) {
            $insertAnswer->execute([$rsvpId, $questionId, $answer]);
        }

        $pdo->commit();

        if ($rsvpStatus === 'Confirmed') {
            flash('success', "You're going! Your RSVP is confirmed.");
        } elseif ($rsvpStatus === 'Waitlisted') {
            flash(
                'success',
                "The event is full, so you're on the waitlist. You'll move up if a spot opens."
            );
        } else {
            flash(
                'success',
                'Your RSVP was sent. The organizers need to approve it.'
            );
        }

        redirect('event.php?id=' . $eventId);
    } catch (Throwable $error) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }

        $message = 'Something went wrong, please try again.';

        if ($error instanceof PDOException) {
            $ruleMessage = rule_error($error);

            if ($ruleMessage !== null) {
                $message = $ruleMessage;
            } elseif (db_code($error) === 1062) {
                $message = 'You already have an RSVP for this event.';
            }
        }

        flash('error', $message);
        redirect('event.php?id=' . $eventId);
    }
}

$title = 'Event Details';
require_once __DIR__ . '/includes/header.php';

$capacity = (int) $event['Capacity'];
$spotsTaken = (int) $event['SpotsTaken'];
$progressValue = min($spotsTaken, $capacity);
?>

<h1><?= e($event['Title']) ?></h1>

<section>
    <h2>Event information</h2>

    <p><strong>Hosted by:</strong> <?= e($event['HostedBy']) ?></p>
    <p><strong>Description:</strong> <?= nl2br(e($event['Description'] ?? '')) ?></p>
    <p><strong>Starts:</strong> <?= e(formatEventTime($event['StartTime'])) ?></p>
    <p><strong>Ends:</strong> <?= e(formatEventTime($event['EndTime'])) ?></p>
    <p><strong>RSVP deadline:</strong> <?= e(formatEventTime($event['RSVPDeadline'])) ?></p>

    <p>
        <strong>Venue:</strong>
        <?= e($event['VenueName']) ?>,
        building <?= e($event['Building']) ?>,
                floor <?= e($event['Floor']) ?><?php if (isset($event['RoomNumber']) && $event['RoomNumber'] !== ''): ?>, room <?= e($event['RoomNumber']) ?><?php endif; ?>
    </p>

    <?php if ((int) $event['RequiresApproval'] === 1): ?>
        <p>Needs approval</p>
    <?php endif; ?>

    <p><strong>Visibility:</strong> <?= e($event['Visibility']) ?></p>
    <p><strong>Maximum guests:</strong> <?= e($event['MaxPlusOnes']) ?></p>
    <p>
        <strong>Spots taken:</strong>
        <?= e($spotsTaken) ?> of <?= e($capacity) ?>
    </p>
    <progress value="<?= e($progressValue) ?>" max="<?= e($capacity) ?>"></progress>
</section>

<section>
    <h2>Ticket types</h2>

    <?php foreach ($ticketTypes as $ticketType): ?>
        <?php
        $typeSpotsLeft = (int) $ticketType['SpotsLeft'];
        $typeSpotsText = ($typeSpotsLeft <= 0)
            ? 'Full'
            : $typeSpotsLeft . ' spots left';
        ?>

        <p>
            <strong><?= e($ticketType['TypeName']) ?>:</strong>
            <?= e($typeSpotsText) ?>
            <?php if ($ticketType['Description'] !== null): ?>
                <span><?= e($ticketType['Description']) ?></span>
            <?php endif; ?>
        </p>
    <?php endforeach; ?>
</section>

<section>
    <h2>Questions</h2>

    <?php if (count($questions) === 0): ?>
        <p>This event has no RSVP questions.</p>
    <?php else: ?>
        <?php foreach ($questions as $question): ?>
            <p>
                <?= e($question['QuestionText']) ?>
                <?php if ((int) $question['IsRequired'] === 1): ?>
                    <strong>*</strong>
                <?php endif; ?>
            </p>
        <?php endforeach; ?>
    <?php endif; ?>
</section>

<?php if ($hasExistingRsvp): ?>
    <section>
        <h2>Your RSVP</h2>

        <p><strong>Status:</strong> <?= e($existingRsvp['RSVPStatus']) ?></p>
        <p><strong>Ticket type:</strong> <?= e($existingRsvp['TypeName']) ?></p>

        <?php if (count($existingGuests) === 0): ?>
            <p>No guests added.</p>
        <?php else: ?>
            <p><strong>Guests:</strong></p>
            <ul>
                <?php foreach ($existingGuests as $guest): ?>
                    <li><?= e($guest['GuestName']) ?></li>
                <?php endforeach; ?>
            </ul>
        <?php endif; ?>

        <?php if ($existingRsvp['DeclineReason'] !== null): ?>
            <p>
                <strong>Decline reason:</strong>
                <?= e($existingRsvp['DeclineReason']) ?>
            </p>
        <?php endif; ?>
    </section>
<?php elseif ($canSubmitRsvp): ?>
    <section>
        <h2>RSVP</h2>

        <form method="post" action="event.php?id=<?= e($eventId) ?>">
            <fieldset>
                <legend>Choose a ticket type</legend>

                <?php foreach ($ticketTypes as $index => $ticketType): ?>
                    <?php
                    $typeSpotsLeft = (int) $ticketType['SpotsLeft'];
                    $typeSpotsText = ($typeSpotsLeft <= 0)
                        ? 'Full'
                        : $typeSpotsLeft . ' spots left';
                    ?>

                    <label>
                        <input
                            type="radio"
                            name="ticket_type"
                            value="<?= e($ticketType['TypeName']) ?>"
                            <?= ($index === 0) ? 'checked' : '' ?>
                            required
                            style="width: auto; max-width: none;"
                        >
                        <?= e($ticketType['TypeName']) ?>
                        (<?= e($typeSpotsText) ?>)
                    </label>
                <?php endforeach; ?>
            </fieldset>

            <?php if ((int) $event['MaxPlusOnes'] > 0): ?>
                <h3>Guests</h3>
                <div id="guest-fields"></div>

                <button
                    type="button"
                    id="add-guest"
                    data-max-guests="<?= e($event['MaxPlusOnes']) ?>"
                >
                    + Add guest
                </button>
            <?php endif; ?>

            <?php if (count($questions) > 0): ?>
                <h3>Questions</h3>

                <?php foreach ($questions as $question): ?>
                    <label for="answer-<?= e($question['QuestionID']) ?>">
                        <?= e($question['QuestionText']) ?>
                        <?php if ((int) $question['IsRequired'] === 1): ?>
                            <strong>*</strong>
                        <?php endif; ?>
                    </label>

                    <textarea
                        id="answer-<?= e($question['QuestionID']) ?>"
                        name="answers[<?= e($question['QuestionID']) ?>]"
                        maxlength="500"
                        rows="3"
                        <?= ((int) $question['IsRequired'] === 1) ? 'required' : '' ?>
                    ></textarea>
                <?php endforeach; ?>
            <?php endif; ?>

            <button type="submit">Submit RSVP</button>
        </form>
    </section>

    <?php if ((int) $event['MaxPlusOnes'] > 0): ?>
        <script>
            const addGuestButton = document.getElementById('add-guest');
            const guestFields = document.getElementById('guest-fields');
            const maxGuests = Number(addGuestButton.dataset.maxGuests);

            addGuestButton.addEventListener('click', function () {
                const guestNumber =
                    guestFields.querySelectorAll('.guest-row').length + 1;

                if (guestNumber > maxGuests) {
                    return;
                }

                const row = document.createElement('div');
                row.className = 'guest-row';

                const nameLabel = document.createElement('label');
                nameLabel.htmlFor = 'guest-name-' + guestNumber;
                nameLabel.textContent = 'Guest ' + guestNumber + ' name';

                const nameInput = document.createElement('input');
                nameInput.type = 'text';
                nameInput.id = 'guest-name-' + guestNumber;
                nameInput.name = 'guests[' + guestNumber + '][name]';
                nameInput.maxLength = 100;
                nameInput.required = true;

                const emailLabel = document.createElement('label');
                emailLabel.htmlFor = 'guest-email-' + guestNumber;
                emailLabel.textContent = 'Guest ' + guestNumber + ' email';

                const emailInput = document.createElement('input');
                emailInput.type = 'email';
                emailInput.id = 'guest-email-' + guestNumber;
                emailInput.name = 'guests[' + guestNumber + '][email]';
                emailInput.maxLength = 100;

                row.appendChild(nameLabel);
                row.appendChild(nameInput);
                row.appendChild(emailLabel);
                row.appendChild(emailInput);
                guestFields.appendChild(row);

                if (guestNumber >= maxGuests) {
                    addGuestButton.hidden = true;
                }
            });
        </script>
    <?php endif; ?>
<?php elseif ($event['EventStatus'] === 'Cancelled'): ?>
    <p>This event was cancelled.</p>
<?php elseif ($event['EventStatus'] !== 'Scheduled'): ?>
    <p>This event is not open for RSVPs.</p>
<?php elseif (!$deadlineOpen): ?>
    <p>The RSVP deadline has passed.</p>
<?php endif; ?>

<?php require_once __DIR__ . '/includes/footer.php'; ?>