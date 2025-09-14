<?php
include 'db.php';

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (isset($_GET['email'])) {
        // Collect and sanitize input
        $email     = $conn->real_escape_string($_GET['email']);
        $username  = $conn->real_escape_string($_GET['username'] ?? '');
        $password  = $conn->real_escape_string($_GET['password'] ?? '');
        $role      = $conn->real_escape_string($_GET['role'] ?? '');
        $longitude = $conn->real_escape_string($_GET['longitude'] ?? '');
        $latitude  = $conn->real_escape_string($_GET['latitude'] ?? '');
        $category  = $conn->real_escape_string($_GET['category'] ?? '');

        // Check if email already exists
        $stmt = $conn->prepare("SELECT email FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $stmt->store_result();

        if ($stmt->num_rows > 0) {
            echo json_encode(["message" => "Email already registered. Input a different Email"]);
        } else {
            // Insert new user
            $insert = $conn->prepare("INSERT INTO users (email, username, password, role, longitude, latitude, category) VALUES (?, ?, ?, ?, ?, ?, ?)");
            $insert->bind_param("sssssss", $email, $username, $password, $role, $longitude, $latitude, $category);

            if ($insert->execute()) {
                echo json_encode(["message" => "User added successfully"]);
            } else {
                echo json_encode(["message" => "Error inserting user"]);
            }
            $insert->close();
        }

        $stmt->close();
    } else {
        echo json_encode(["message" => "No email provided"]);
    }
} else {
    echo json_encode(["message" => "Invalid request method"]);
}

$conn->close();
?>

<?php

 
/* include 'db.php';
 
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];
 
$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
	case 'GET':
	if(isset($_GET['email'])){
		//echo"<pre>"; print_r($_GET['email']); exit();
		$email        = $_GET['email'];
		$username     = $_GET['username'];
		$password     = $_GET['password'];
		$role         = $_GET['role'];
		$longitude    = $_GET['longitude'];
		$latitude     = $_GET['latitude'];
		$category     = $_GET['category'];
		
		$result = $conn->query("SELECT * FROM users WHERE email='$email'");
		$data = $result->fetch_assoc();
		
		//echo"<pre>"; print_r($data['email']); exit();
		
		if ($data['email'] == $email) {
        echo json_encode(["message" => "Email already registered. Input a different Email"]);
        break; 
		
		} else {
			$conn->query("INSERT INTO users (email, username, password, role, longitude, latitude, category) VALUES ('$email', '$username', '$password', '$role', '$longitude', '$latitude', '$category')");
			
			echo json_encode(["message" => "User added successfully"]);
			break; 
		}
    }else{
		
		$users="No Data Found";
        echo json_encode($users);
	}
    default:
        echo json_encode(["message" => "Invalid request method"]);
    break;
}

$conn->close(); */
?>