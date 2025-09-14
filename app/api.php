<?php

include 'db.php';

header("Content-Type: application/json");

 $method = $_SERVER['REQUEST_METHOD'];
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        if (isset($_GET['email'])) {
			
            $email    = $_GET['email'];
			$password = $_GET['password'];
			
            $result = $conn->query("SELECT id,email,username,description,password,role,longitude,latitude,category,flag FROM users WHERE email='$email' and password='$password'");
            $users = $result->fetch_assoc();
			
        echo json_encode($users);
			
        } else {

			$users="No Data Found";
			echo json_encode($users);
			break;	
			
        }
}

$conn->close();
 
 
?>
<?php
/* include 'db.php';

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

$conn->close(); */
?>
