<?php
// S1 Log out: auth.php starts the session; empty it, destroy it, go to the login page.
require_once __DIR__ . '/includes/auth.php';

$_SESSION = [];
session_destroy();

redirect('login.php');
