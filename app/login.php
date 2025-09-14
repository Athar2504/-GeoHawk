<?php
include 'db.php';

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (!isset($_GET['email']) || !isset($_GET['password'])) {
        echo json_encode(["error" => "Missing email or password"]);
        exit;
    }

    $email = $_GET['email'];
    $password = $_GET['password'];

    // Use prepared statements to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->bind_param("s", $email);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    if ($user) {
        // Verify password using password_hash()
        if (password_verify($password, $user['password'])) {
            unset($user['password']); // Remove password from response
            echo json_encode($user);
        } else {
            echo json_encode(["error" => "Invalid email or password"]);
        }
    } else {
        echo json_encode(["error" => "User not found"]);
    }

    $stmt->close();
} else {
    echo json_encode(["error" => "Invalid request method"]);
}

$conn->close();
?>


<?php
/* // Include the database configuration
require_once 'config.php';

// Set the header for JSON response
header('Content-Type: application/json');

// Get the raw POST data
$data = json_decode(file_get_contents("php://input"));

// Validate the data (basic validation)
if (!isset($data->username) || !isset($data->password)) {
    echo json_encode(["error" => "Username and password are required."]);
    exit;
}

$username = $data->username;
$password = $data->password;

// Prepare SQL query to fetch the user
$sql = "SELECT * FROM users WHERE username = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $username);
$stmt->execute();
$result = $stmt->get_result();

// Check if user exists
if ($result->num_rows > 0) {
    $user = $result->fetch_assoc();

    // Check if the password is correct (assumes passwords are stored in plain text, consider using hashing for security)
    if ($password === $user['password']) {
        // If the password matches, return a success response
        echo json_encode(["success" => "Login successful!", "user" => $user]);
    } else {
        // If the password is incorrect
        echo json_encode(["error" => "Invalid password."]);
    }
} else {
    // If the user does not exist
    echo json_encode(["error" => "User not found."]);
}

// Close connection
$conn->close(); */
?>