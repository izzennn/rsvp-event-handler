<?php
// S1 Sign up. This page does not call require_login(), and it uses the member account.
require_once __DIR__ . '/includes/auth.php';

if (isset($_SESSION['user_id'])) {
    redirect('events.php');
}

// S1 sign-up checks: returns a message for the email and/or NetID if already used.
function taken_messages($email, $netId)
{
    $messages = [];

    $stmt = db()->prepare('SELECT COUNT(*) AS EmailTaken FROM USER WHERE Email = ?');
    $stmt->execute([$email]);
    if ((int) $stmt->fetch()['EmailTaken'] > 0) {
        $messages[] = 'That email is already used by another account.';
    }

    if ($netId !== null) {
        $stmt = db()->prepare('SELECT COUNT(*) AS NetIDTaken FROM USER WHERE NetID = ?');
        $stmt->execute([$netId]);
        if ((int) $stmt->fetch()['NetIDTaken'] > 0) {
            $messages[] = 'That NetID is already used by another account.';
        }
    }
    return $messages;
}

$userType  = 'NYU';
$netId     = '';
$firstName = '';
$lastName  = '';
$email     = '';
$phones    = [];
$errors    = [];

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $userType  = $_POST['user_type'] ?? '';
    $netId     = trim($_POST['netid'] ?? '');
    $firstName = trim($_POST['first_name'] ?? '');
    $lastName  = trim($_POST['last_name'] ?? '');
    $email     = trim($_POST['email'] ?? '');
    $password  = $_POST['password'] ?? '';   // kept exactly as typed, never escaped before hashing
    $confirm   = $_POST['confirm_password'] ?? '';

    // Phones: drop empty boxes and repeated numbers
    $rawPhones = $_POST['phones'] ?? [];
    if (!is_array($rawPhones)) {
        $rawPhones = [];
    }
    foreach ($rawPhones as $phone) {
        $phone = trim((string) $phone);
        if ($phone !== '' && !in_array($phone, $phones, true)) {
            $phones[] = $phone;
        }
    }

    // ----- Validate in PHP before using the database -----
    if ($userType !== 'NYU' && $userType !== 'External') {
        $errors[] = 'Choose an account type.';
    }

    if ($userType === 'NYU' && $netId === '') {
        $errors[] = 'NYU accounts need a NetID.';
    } elseif ($userType === 'External' && $netId !== '') {
        $errors[] = 'External accounts must leave NetID empty.';
    } elseif (mb_strlen($netId) > 15) {
        $errors[] = 'NetID can be at most 15 characters.';
    }

    if ($firstName === '') {
        $errors[] = 'First name is required.';
    } elseif (mb_strlen($firstName) > 50) {
        $errors[] = 'First name can be at most 50 characters.';
    }

    if ($lastName === '') {
        $errors[] = 'Last name is required.';
    } elseif (mb_strlen($lastName) > 50) {
        $errors[] = 'Last name can be at most 50 characters.';
    }

    if ($email === '') {
        $errors[] = 'Email is required.';
    } elseif (mb_strlen($email) > 100) {
        $errors[] = 'Email can be at most 100 characters.';
    } elseif (filter_var($email, FILTER_VALIDATE_EMAIL) === false) {
        $errors[] = 'Enter a valid email address.';
    }

    if ($password === '') {
        $errors[] = 'Password is required.';
    } elseif (mb_strlen($password) < 8) {
        $errors[] = 'Password must be at least 8 characters.';
    } elseif ($password !== $confirm) {
        $errors[] = 'The two passwords do not match.';
    }

    foreach ($phones as $phone) {
        if (mb_strlen($phone) > 20) {
            $errors[] = 'Each phone number can be at most 20 characters.';
            break;
        }
    }

    // NetID NULL for External accounts (the External version of the S1 INSERT)
    $netIdValue = ($userType === 'NYU') ? $netId : null;

    // ----- Email and NetID must not already be used -----
    if (!$errors) {
        $errors = taken_messages($email, $netIdValue);
    }

    // ----- Create the account and its phones in one transaction -----
    if (!$errors) {
        $db = db();
        $newUserId = null;
        try {
            $db->beginTransaction();

            // S1 "create an account"
            $stmt = $db->prepare(
                'INSERT INTO USER (UserType, NetID, FirstName, LastName, Email, PasswordHash)
                 VALUES (?, ?, ?, ?, ?, ?)'
            );
            $stmt->execute([
                $userType,
                $netIdValue,
                $firstName,
                $lastName,
                $email,
                password_hash($password, PASSWORD_DEFAULT),
            ]);
            $newUserId = (int) $db->lastInsertId();

            // S1 phones: one INSERT per number
            $stmt = $db->prepare('INSERT INTO USER_PHONE (UserID, PhoneNumber) VALUES (?, ?)');
            foreach ($phones as $phone) {
                $stmt->execute([$newUserId, $phone]);
            }

            $db->commit();
        } catch (PDOException $ex) {
            if ($db->inTransaction()) {
                $db->rollBack();
            }
            $newUserId = null;
            $code = db_code($ex);

            if ($code === 1062) {
                // Someone took the email or NetID a moment ago: say which one
                $errors = taken_messages($email, $netIdValue);
                if (!$errors) {
                    $errors[] = 'That email or NetID is already used by another account.';
                }
            } elseif ($code === 4025) {
                // CHECK constraint chk_user_netid
                $errors[] = 'NYU accounts need a NetID, and External accounts must leave it empty.';
            } elseif (rule_error($ex) !== null) {
                $errors[] = rule_error($ex);
            } else {
                $errors[] = 'Something went wrong. Please try again.';
            }
        }

        if ($newUserId !== null) {
            // Log the new user in (same steps as login.php)
            session_regenerate_id(true);
            $_SESSION['user_id'] = $newUserId;
            $_SESSION['first_name'] = $firstName;
            $_SESSION['user_type'] = $userType;

            flash('success', 'Welcome, ' . $firstName . '! Your account is ready.');
            redirect('events.php');
        }
    }
}

// Show at least one phone box
$phoneBoxes = $phones ? $phones : [''];

$title = 'Sign up';
require __DIR__ . '/includes/header.php';
?>
<h1>Sign up</h1>

<?php if ($errors): ?>
    <div class="msg-error">
        <?php foreach ($errors as $message): ?>
            <div><?= e($message) ?></div>
        <?php endforeach; ?>
    </div>
<?php endif; ?>

<form method="post" action="signup.php">
    <label for="user_type">Account type</label>
    <select id="user_type" name="user_type">
        <option value="NYU" <?= $userType === 'NYU' ? 'selected' : '' ?>>NYU</option>
        <option value="External" <?= $userType === 'External' ? 'selected' : '' ?>>External</option>
    </select>

    <label for="netid">NetID (NYU accounts only)</label>
    <input type="text" id="netid" name="netid" maxlength="15" value="<?= e($netId) ?>">

    <label for="first_name">First name</label>
    <input type="text" id="first_name" name="first_name" maxlength="50" value="<?= e($firstName) ?>" required>

    <label for="last_name">Last name</label>
    <input type="text" id="last_name" name="last_name" maxlength="50" value="<?= e($lastName) ?>" required>

    <label for="email">Email</label>
    <input type="email" id="email" name="email" maxlength="100" value="<?= e($email) ?>" required>

    <label for="password">Password (at least 8 characters)</label>
    <input type="password" id="password" name="password" required>

    <label for="confirm_password">Confirm password</label>
    <input type="password" id="confirm_password" name="confirm_password" required>

    <label>Phone numbers (optional)</label>
    <div id="phones">
        <?php foreach ($phoneBoxes as $phone): ?>
            <div><input type="text" name="phones[]" maxlength="20" value="<?= e($phone) ?>"></div>
        <?php endforeach; ?>
    </div>
    <button type="button" id="add-phone">+ Add another phone</button>

    <div><button type="submit">Sign up</button></div>
</form>

<p>Already have an account? <a href="login.php">Log in</a></p>

<script>
document.getElementById('add-phone').addEventListener('click', function () {
    var row = document.createElement('div');
    var box = document.createElement('input');
    box.type = 'text';
    box.name = 'phones[]';
    box.maxLength = 20;
    row.appendChild(box);
    document.getElementById('phones').appendChild(row);
    box.focus();
});
</script>

<?php require __DIR__ . '/includes/footer.php'; ?>
