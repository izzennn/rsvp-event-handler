<?php
// S5 Profile and My Organizations (member page).
require_once __DIR__ . '/includes/auth.php';

$userId = require_login();
$pdo = db();

// ---------- Changes (POST). Every one ends with flash() then redirect(). ----------
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // ----- Save my details (only FirstName, LastName, Email can change) -----
    if ($action === 'save_details') {
        $firstName = trim($_POST['first_name'] ?? '');
        $lastName  = trim($_POST['last_name'] ?? '');
        $email     = trim($_POST['email'] ?? '');

        if ($firstName === '' || $lastName === '' || $email === '') {
            flash('error', 'First name, last name and email are all required.');
        } elseif (mb_strlen($firstName) > 50 || mb_strlen($lastName) > 50) {
            flash('error', 'Names can be at most 50 characters.');
        } elseif (mb_strlen($email) > 100) {
            flash('error', 'Email can be at most 100 characters.');
        } elseif (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
            flash('error', 'Enter a valid email address.');
        } else {
            try {
                // S5 "Save changes", always for the logged-in user
                $stmt = $pdo->prepare('UPDATE USER SET FirstName = ?, LastName = ?, Email = ? WHERE UserID = ?');
                $stmt->execute([$firstName, $lastName, $email, $userId]);
                $_SESSION['first_name'] = $firstName;
                flash('success', 'Your details were saved.');
            } catch (PDOException $ex) {
                if (db_code($ex) === 1062) {
                    flash('error', 'That email is already used by another account.');
                } else {
                    flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
                }
            }
        }
        redirect('profile.php');
    }

    // ----- Add a phone -----
    if ($action === 'add_phone') {
        $phone = trim($_POST['phone'] ?? '');

        if ($phone === '') {
            flash('error', 'Enter a phone number.');
        } elseif (mb_strlen($phone) > 20) {
            flash('error', 'A phone number can be at most 20 characters.');
        } elseif (!preg_match('/^[0-9 +().-]+$/', $phone) || preg_match_all('/[0-9]/', $phone) < 7) {
            // Only digits, spaces and + ( ) - . and at least 7 digits
            flash('error', 'Enter a valid phone number, like (212) 555-0143.');
        } else {
            try {
                $stmt = $pdo->prepare('INSERT INTO USER_PHONE (UserID, PhoneNumber) VALUES (?, ?)');
                $stmt->execute([$userId, $phone]);
                flash('success', 'Phone number added.');
            } catch (PDOException $ex) {
                if (db_code($ex) === 1062) {
                    flash('error', "That number is already saved.");
                } else {
                    flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
                }
            }
        }
        redirect('profile.php');
    }

    // ----- Remove a phone -----
    if ($action === 'remove_phone') {
        $phone = (string) ($_POST['phone'] ?? '');
        try {
            $stmt = $pdo->prepare('DELETE FROM USER_PHONE WHERE UserID = ? AND PhoneNumber = ?');
            $stmt->execute([$userId, $phone]);
            if ($stmt->rowCount() > 0) {
                flash('success', 'Phone number removed.');
            } else {
                flash('error', 'That number is not on your profile.');
            }
        } catch (PDOException $ex) {
            flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
        }
        redirect('profile.php');
    }

    // ----- Leave an organization (never leaves it without an officer) -----
    if ($action === 'leave_org') {
        $orgId = filter_input(INPUT_POST, 'org_id', FILTER_VALIDATE_INT);
        if (!$orgId) {
            flash('error', 'Choose an organization.');
            redirect('profile.php');
        }

        try {
            $pdo->beginTransaction();

            // Team rule 16: the lock is the very next query after beginTransaction()
            $stmt = $pdo->prepare("SELECT UserID FROM ORG_MEMBERSHIP WHERE OrgID = ? AND Role = 'Officer' FOR UPDATE");
            $stmt->execute([$orgId]);
            $officers = array_map('intval', $stmt->fetchAll(PDO::FETCH_COLUMN));

            if (in_array($userId, $officers, true) && count($officers) === 1) {
                $pdo->rollBack();
                flash('error', "You're the only officer. Make someone else an officer first.");
                redirect('profile.php');
            }

            // S5 "Leave an organization"
            $stmt = $pdo->prepare('DELETE FROM ORG_MEMBERSHIP WHERE UserID = ? AND OrgID = ?');
            $stmt->execute([$userId, $orgId]);

            if ($stmt->rowCount() === 0) {
                $pdo->rollBack();
                flash('error', 'You are not a member of that organization.');
                redirect('profile.php');
            }

            $pdo->commit();
            flash('success', 'You left the organization.');
        } catch (PDOException $ex) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
        }
        redirect('profile.php');
    }

    // ----- Create an organization (the creator becomes its first officer) -----
    if ($action === 'create_org') {
        $orgName      = trim($_POST['org_name'] ?? '');
        $contactEmail = trim($_POST['contact_email'] ?? '');
        $description  = trim($_POST['description'] ?? '');

        $error = null;
        if ($orgName === '' || $contactEmail === '') {
            $error = 'Name and contact email are required.';
        } elseif (mb_strlen($orgName) > 100) {
            $error = 'The name can be at most 100 characters.';
        } elseif (mb_strlen($contactEmail) > 100) {
            $error = 'The contact email can be at most 100 characters.';
        } elseif (filter_var($contactEmail, FILTER_VALIDATE_EMAIL) === false) {
            $error = 'Enter a valid contact email.';
        } elseif (mb_strlen($description) > 500) {
            $error = 'The description can be at most 500 characters.';
        }

        if ($error === null) {
            // S5 "check the name is free" (before the transaction)
            $stmt = $pdo->prepare('SELECT COUNT(*) AS NameTaken FROM ORGANIZATION WHERE OrgName = ?');
            $stmt->execute([$orgName]);
            if ((int) $stmt->fetch()['NameTaken'] > 0) {
                $error = 'An organization with that name already exists.';
            }
        }

        if ($error !== null) {
            flash('error', $error);
            redirect('profile.php');
        }

        $newOrgId = null;
        try {
            $pdo->beginTransaction();

            $stmt = $pdo->prepare('INSERT INTO ORGANIZATION (OrgName, ContactEmail, Description) VALUES (?, ?, ?)');
            $stmt->execute([$orgName, $contactEmail, ($description === '') ? null : $description]);
            $newOrgId = (int) $pdo->lastInsertId();

            $stmt = $pdo->prepare("INSERT INTO ORG_MEMBERSHIP (UserID, OrgID, Role, JoinedDate) VALUES (?, ?, 'Officer', CURDATE())");
            $stmt->execute([$userId, $newOrgId]);

            $pdo->commit();
        } catch (PDOException $ex) {
            if ($pdo->inTransaction()) {
                $pdo->rollBack();
            }
            $newOrgId = null;
            if (db_code($ex) === 1062) {
                flash('error', 'An organization with that name already exists.');
            } else {
                flash('error', rule_error($ex) ?? 'Something went wrong, please try again.');
            }
        }

        if ($newOrgId === null) {
            redirect('profile.php');
        }
        flash('success', $orgName . ' was created, and you are its officer.');
        redirect('org.php?id=' . $newOrgId);
    }

    redirect('profile.php');
}

// ---------- Data for the page ----------

// S5 "My details and phone numbers"
$stmt = $pdo->prepare('SELECT UserID, FirstName, LastName, Email, UserType, NetID FROM USER WHERE UserID = ?');
$stmt->execute([$userId]);
$me = $stmt->fetch();

$stmt = $pdo->prepare('SELECT PhoneNumber FROM USER_PHONE WHERE UserID = ? ORDER BY PhoneNumber');
$stmt->execute([$userId]);
$phones = $stmt->fetchAll(PDO::FETCH_COLUMN);

// S5 "My Organizations"
$stmt = $pdo->prepare(
    'SELECT o.OrgID, o.OrgName, o.Description, m.Role, m.JoinedDate
     FROM ORG_MEMBERSHIP m
     INNER JOIN ORGANIZATION o ON o.OrgID = m.OrgID
     WHERE m.UserID = ?
     ORDER BY m.Role DESC, o.OrgName'
);
$stmt->execute([$userId]);
$orgs = $stmt->fetchAll();

// S5 "number of officers" in each of my organizations
$stmt = $pdo->prepare(
    "SELECT OrgID, COUNT(*) AS Officers
     FROM ORG_MEMBERSHIP
     WHERE Role = 'Officer'
       AND OrgID IN (SELECT OrgID FROM ORG_MEMBERSHIP WHERE UserID = ?)
     GROUP BY OrgID
     ORDER BY OrgID"
);
$stmt->execute([$userId]);
$officerCounts = [];
foreach ($stmt->fetchAll() as $row) {
    $officerCounts[(int) $row['OrgID']] = (int) $row['Officers'];
}

$title = 'Profile';
require __DIR__ . '/includes/header.php';
?>
<h1>Profile</h1>

<h2>My details</h2>
<table>
    <tr><th>Name</th><td><?= e($me['FirstName'] . ' ' . $me['LastName']) ?></td></tr>
    <tr><th>Account type</th><td><?= e($me['UserType']) ?></td></tr>
    <tr><th>NetID</th><td><?= e($me['NetID'] ?? 'None (external account)') ?></td></tr>
    <tr><th>Email</th><td><?= e($me['Email']) ?></td></tr>
</table>

<form method="post" action="profile.php">
    <input type="hidden" name="action" value="save_details">
    <label for="first_name">First name</label>
    <input type="text" id="first_name" name="first_name" maxlength="50" value="<?= e($me['FirstName']) ?>" required>
    <label for="last_name">Last name</label>
    <input type="text" id="last_name" name="last_name" maxlength="50" value="<?= e($me['LastName']) ?>" required>
    <label for="email">Email</label>
    <input type="email" id="email" name="email" maxlength="100" value="<?= e($me['Email']) ?>" required>
    <p class="muted">Your NetID and account type cannot be changed.</p>
    <button type="submit">Save changes</button>
</form>

<h2>Phone numbers</h2>
<?php if (!$phones): ?>
    <p class="muted">No phone numbers saved.</p>
<?php else: ?>
    <table>
        <?php foreach ($phones as $phone): ?>
            <tr>
                <td><?= e($phone) ?></td>
                <td>
                    <form method="post" action="profile.php" class="inline">
                        <input type="hidden" name="action" value="remove_phone">
                        <input type="hidden" name="phone" value="<?= e($phone) ?>">
                        <button type="submit">Remove</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>

<form method="post" action="profile.php">
    <input type="hidden" name="action" value="add_phone">
    <label for="phone">Add a phone</label>
    <input type="text" id="phone" name="phone" maxlength="20" required>
    <button type="submit">Add phone</button>
</form>

<h2>My Organizations</h2>
<?php if (!$orgs): ?>
    <p class="muted">You are not in any organization yet.</p>
<?php else: ?>
    <table>
        <tr><th>Organization</th><th>Role</th><th>Joined</th><th></th></tr>
        <?php foreach ($orgs as $org): ?>
            <?php
            $orgId = (int) $org['OrgID'];
            $onlyOfficer = ($org['Role'] === 'Officer' && ($officerCounts[$orgId] ?? 0) <= 1);
            ?>
            <tr>
                <td><?= e($org['OrgName']) ?></td>
                <td><?= e($org['Role']) ?></td>
                <td><?= e(date('M j, Y', strtotime($org['JoinedDate']))) ?></td>
                <td>
                    <?php if ($org['Role'] === 'Officer'): ?>
                        <a class="button" href="org.php?id=<?= e($orgId) ?>">Manage</a>
                    <?php endif; ?>
                    <form method="post" action="profile.php" class="inline"
                          onsubmit="return confirm('Leave this organization?');">
                        <input type="hidden" name="action" value="leave_org">
                        <input type="hidden" name="org_id" value="<?= e($orgId) ?>">
                        <button type="submit" <?= $onlyOfficer ? 'disabled title="You are the only officer. Make someone else an officer first."' : '' ?>>Leave</button>
                    </form>
                </td>
            </tr>
        <?php endforeach; ?>
    </table>
<?php endif; ?>

<h2>Create an organization</h2>
<form method="post" action="profile.php">
    <input type="hidden" name="action" value="create_org">
    <label for="org_name">Name</label>
    <input type="text" id="org_name" name="org_name" maxlength="100" required>
    <label for="contact_email">Contact email</label>
    <input type="email" id="contact_email" name="contact_email" maxlength="100" required>
    <label for="description">Description (optional)</label>
    <textarea id="description" name="description" maxlength="500" rows="3"></textarea>
    <p class="muted">You become the organization's first officer.</p>
    <button type="submit">Create organization</button>
</form>

<?php require __DIR__ . '/includes/footer.php'; ?>
