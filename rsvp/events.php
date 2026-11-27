<?php
// Check that the member is signed in.
require_once __DIR__ . '/includes/auth.php';

$userId = require_login();
$pdo = db();

// Read the search choices.
$search = (isset($_GET['search']) && is_string($_GET['search']))
    ? trim($_GET['search'])
    : '';

$orgId = filter_input(INPUT_GET, 'org', FILTER_VALIDATE_INT);
if ($orgId === false || $orgId === null || $orgId < 1) {
    $orgId = null;
}

$building = (isset($_GET['building']) && is_string($_GET['building']))
    ? trim($_GET['building'])
    : '';

// Keep the date only when it is valid.
$date = (isset($_GET['date']) && is_string($_GET['date']))
    ? $_GET['date']
    : '';

$dateObject = null;
if ($date !== '') {
    $dateObject = DateTime::createFromFormat('!Y-m-d', $date);

    if (!$dateObject || $dateObject->format('Y-m-d') !== $date) {
        $date = '';
        $dateObject = null;
    }
}

// Use only the sort choices shown on the page.
$sort = (isset($_GET['sort']) && is_string($_GET['sort']) && $_GET['sort'] === 'spots')
    ? 'spots'
    : 'date';

$orderBy = ($sort === 'spots')
    ? 'SpotsLeft DESC, e.StartTime'
    : 'e.StartTime';

// Load the choices for the filter menus.
$orgStmt = $pdo->prepare(
    'SELECT OrgID, OrgName FROM ORGANIZATION ORDER BY OrgName'
);
$orgStmt->execute();
$organizations = $orgStmt->fetchAll();

$buildingStmt = $pdo->prepare(
    'SELECT DISTINCT Building FROM VENUE ORDER BY Building'
);
$buildingStmt->execute();
$buildings = $buildingStmt->fetchAll(PDO::FETCH_COLUMN);

// Get events the member is allowed to see.
function getVisibleEvents(
    PDO $pdo,
    int $userId,
    string $search,
    ?int $orgId,
    string $building,
    ?DateTime $dateObject,
    string $orderBy
): array {
    $sql = "
        SELECT e.EventID, e.Title, o.OrgName, e.StartTime, e.EndTime,
               v.VenueName, v.Building, v.Floor, v.RoomNumber,
               e.RequiresApproval, e.Visibility,
               e.Capacity - fn_spots_taken(e.EventID) AS SpotsLeft,
               my.RSVPStatus AS MyStatus
        FROM EVENT e
        INNER JOIN ORGANIZATION o ON o.OrgID = e.OrgID
        INNER JOIN VENUE v ON v.VenueID = e.VenueID
        LEFT JOIN (
            SELECT EventID, RSVPStatus
            FROM RSVP
            WHERE UserID = ?
        ) my ON my.EventID = e.EventID
        WHERE e.EventStatus = 'Scheduled'
          AND e.StartTime > NOW()
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
    ";

    $values = [$userId, $userId, $userId];

    // Add the search and filters the member selected.
    if ($search !== '') {
        $sql .= ' AND (e.Title LIKE ? OR e.Description LIKE ?)';
        $searchValue = '%' . $search . '%';
        $values[] = $searchValue;
        $values[] = $searchValue;
    }

    if ($orgId !== null) {
        $sql .= ' AND e.OrgID = ?';
        $values[] = $orgId;
    }

    if ($building !== '') {
        $sql .= ' AND v.Building = ?';
        $values[] = $building;
    }

    if ($dateObject !== null) {
        $nextDay = clone $dateObject;
        $nextDay->modify('+1 day');

        $sql .= ' AND e.StartTime >= ? AND e.StartTime < ?';
        $values[] = $dateObject->format('Y-m-d');
        $values[] = $nextDay->format('Y-m-d');
    }

    $sql .= ' ORDER BY ' . $orderBy;

    $eventStmt = $pdo->prepare($sql);
    $eventStmt->execute($values);

    return $eventStmt->fetchAll();
}

$events = getVisibleEvents(
    $pdo,
    $userId,
    $search,
    $orgId,
    $building,
    $dateObject,
    $orderBy
);

$title = 'Browse Events';
require_once __DIR__ . '/includes/header.php';
?>

<h1>Browse Events</h1>

<form method="get" action="events.php">
    <label for="search">Search</label>
    <input
        type="search"
        id="search"
        name="search"
        value="<?= e($search) ?>"
    >

    <label for="org">Organization</label>
    <select id="org" name="org">
        <option value="">All organizations</option>
        <?php foreach ($organizations as $organization): ?>
            <option
                value="<?= e($organization['OrgID']) ?>"
                <?= ($orgId === (int) $organization['OrgID']) ? 'selected' : '' ?>
            >
                <?= e($organization['OrgName']) ?>
            </option>
        <?php endforeach; ?>
    </select>

    <label for="building">Building</label>
    <select id="building" name="building">
        <option value="">All buildings</option>
        <?php foreach ($buildings as $buildingOption): ?>
            <option
                value="<?= e($buildingOption) ?>"
                <?= ($building === $buildingOption) ? 'selected' : '' ?>
            >
                <?= e($buildingOption) ?>
            </option>
        <?php endforeach; ?>
    </select>

    <label for="date">Date</label>
    <input
        type="date"
        id="date"
        name="date"
        value="<?= e($date) ?>"
    >

    <label for="sort">Sort by</label>
    <select id="sort" name="sort">
        <option value="date" <?= ($sort === 'date') ? 'selected' : '' ?>>
            Date
        </option>
        <option value="spots" <?= ($sort === 'spots') ? 'selected' : '' ?>>
            Spots left
        </option>
    </select>

    <button type="submit">Search</button>
    <a class="button" href="events.php">Clear</a>
</form>

<?php if (count($events) === 0): ?>
    <p>No events match your search.</p>
<?php else: ?>
    <?php foreach ($events as $event): ?>
        <?php
        $startTime = DateTime::createFromFormat('Y-m-d H:i:s', $event['StartTime']);
        $endTime = DateTime::createFromFormat('Y-m-d H:i:s', $event['EndTime']);

        $startText = $startTime
            ? $startTime->format('M j, Y g:i A')
            : $event['StartTime'];

        $endText = $endTime
            ? $endTime->format('M j, Y g:i A')
            : $event['EndTime'];

        $spotsLeft = (int) $event['SpotsLeft'];
        ?>

        <article>
            <h2>
                <a href="event.php?id=<?= e($event['EventID']) ?>">
                    <?= e($event['Title']) ?>
                </a>
            </h2>

            <p><strong>Organization:</strong> <?= e($event['OrgName']) ?></p>
            <p><strong>Starts:</strong> <?= e($startText) ?></p>
            <p><strong>Ends:</strong> <?= e($endText) ?></p>

            <p>
                <strong>Venue:</strong>
                <?= e($event['VenueName']) ?>,
                building <?= e($event['Building']) ?>,
                floor <?= e($event['Floor']) ?>,
                room <?= e($event['RoomNumber'] ?? 'Not listed') ?>
            </p>

            <p>
                <strong>Spots:</strong>
                <?= ($spotsLeft <= 0) ? 'Full' : e($spotsLeft . ' left') ?>
            </p>

            <?php if ((int) $event['RequiresApproval'] === 1): ?>
                <p>Needs approval</p>
            <?php endif; ?>

            <p><strong>Visibility:</strong> <?= e($event['Visibility']) ?></p>

            <?php if ($event['MyStatus'] !== null): ?>
                <p><strong>Your RSVP:</strong> <?= e($event['MyStatus']) ?></p>
            <?php endif; ?>

            <p>
                <a href="event.php?id=<?= e($event['EventID']) ?>">
                    View event details
                </a>
            </p>
        </article>
        <hr>
    <?php endforeach; ?>
<?php endif; ?>

<?php require_once __DIR__ . '/includes/footer.php'; ?>