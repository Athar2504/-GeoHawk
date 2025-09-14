<?php
include 'db.php';

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

switch ($method) {
    case 'GET':
        if (isset($_GET['email']) && isset($_GET['description'])) {
            $email = $conn->real_escape_string($_GET['email']);
            $description = $conn->real_escape_string($_GET['description']);

            $result = $conn->query("SELECT email FROM users WHERE email = '$email'");
            $data = $result->fetch_assoc();

            if ($data && $data['email'] === $email) {
                $update = $conn->query("UPDATE users SET description = '$description' WHERE email = '$email'");

                if ($update) {
                    echo json_encode(["message" => "Description updated successfully"]);
                } else {
                    echo json_encode(["message" => "Failed to update description"]);
                }
            } else {
                echo json_encode(["message" => "User email not found"]);
            }
        } else {
            echo json_encode(["message" => "Email and description are required"]);
        }
        break;

    default:
        echo json_encode(["message" => "Invalid request method"]);
        break;
}

$conn->close();
?>
