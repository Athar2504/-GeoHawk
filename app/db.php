<?php

$servername = 'localhost';
$username = 'uz4bnaiuqjugp';
$password = 'ragcompany@347';
$dbname = 'dbmothq9lg0wsv';

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
