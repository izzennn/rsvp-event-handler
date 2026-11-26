<?php
// S1 Log in. This page does not call require_login(), and it uses the member account.
require_once __DIR__ . '/includes/auth.php';

if (isset($_SESSION['user_id'])) {
    redirect('events.php');
}

$email = '';
$error = null;

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $email = trim($_POST['email'] ?? '');
    $password = $_POST['password'] ?? '';

    if ($email === '' || $password === '') {
        $error = 'Enter your email and password.';
    } else {
        // S1 "Log in": find the account by email
        $stmt = db()->prepare(
            'SELECT UserID, FirstName, LastName, UserType, PasswordHash
             FROM USER
             WHERE Email = ?'
        );
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if ($user !== false && password_verify($password, $user['PasswordHash'])) {
            // A fresh session id at login, so nobody can reuse an old one
            session_regenerate_id(true);
            $_SESSION['user_id'] = (int) $user['UserID'];
            $_SESSION['first_name'] = $user['FirstName'];
            $_SESSION['user_type'] = $user['UserType'];

            flash('success', 'Welcome back, ' . $user['FirstName'] . '.');
            redirect('events.php');
        }

        // Same message for an unknown email and a wrong password
        $error = 'Wrong email or password.';
    }
}

$title = 'Log in';
require __DIR__ . '/includes/header.php';
?>
<h1>Log in</h1>

<?php if ($error !== null): ?>
    <div class="msg-error"><?= e($error) ?></div>
<?php endif; ?>

<form method="post" action="login.php">
    <label for="email">Email</label>
    <input type="email" id="email" name="email" maxlength="100" value="<?= e($email) ?>" required>

    <label for="password">Password</label>
    <input type="password" id="password" name="password" required>

    <button type="submit">Log in</button>
</form>

<p>No account yet? <a href="signup.php">Sign up</a></p>

<?php require __DIR__ . '/includes/footer.php'; ?>
