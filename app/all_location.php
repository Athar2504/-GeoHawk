<?php


include 'db.php';
 
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

$input = json_decode(file_get_contents('php://input'), true);

switch ($method) {
    case 'GET':
        $result = $conn->query("SELECT latitude, longitude, username, description, category, email, flag FROM users WHERE role='shopper'");
        
        $data = [];

        while ($row = $result->fetch_assoc()) {
            $data[] = $row;
        }
        
        echo json_encode($data);
        break; // Add break here to prevent falling into the default case
        
    default:
        echo json_encode(["message" => "Invalid request method"]);
        break;
}

$conn->close();
?>


