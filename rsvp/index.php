<?php
require_once __DIR__ . '/includes/auth.php';

if (isset($_SESSION['user_id'])) {
    redirect('events.php');
}
redirect('login.php');
