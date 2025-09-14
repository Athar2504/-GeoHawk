<?php
include 'db.php';

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (isset($_GET['email']) && isset($_GET['flag'])) {
        $email = $_GET['email'];
        $flag = $_GET['flag'];

        // Use prepared statements to avoid SQL injection
        $stmt = $conn->prepare("SELECT email FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($result->num_rows > 0) {
            $updateStmt = $conn->prepare("UPDATE users SET flag = ? WHERE email = ?");
            $updateStmt->bind_param("ss", $flag, $email);
            $updateStmt->execute();

            echo json_encode(["message" => "Flag status updated successfully"]);
        } else {
            echo json_encode(["message" => "User not found"]);
        }

        $stmt->close();
    } else {
        echo json_encode(["message" => "Missing required parameters: email and flag"]);
    }
} else {
    echo json_encode(["message" => "Invalid request method"]);
}

$conn->close();
?>
