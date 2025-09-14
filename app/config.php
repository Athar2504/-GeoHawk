<?php
$servername = "localhost";
$username = "uz4bnaiuqjugp"; // your DB username
$password = "ragcompany@347"; // your DB password
$dbname = "dbmothq9lg0wsv"; // your DB name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>