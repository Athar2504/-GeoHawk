<?php
/* include 'db.php';
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method === 'GET') {
    if (isset($_GET['email'], $_GET['longitude'], $_GET['latitude'])) {
        $email = $_GET['email'];
        $longitude = $_GET['longitude'];
        $latitude = $_GET['latitude'];

        // Use prepared statements
        $stmt = $conn->prepare("SELECT email FROM users WHERE email = ?");
        $stmt->bind_param("s", $email);
        $stmt->execute();
        $result = $stmt->get_result();

        if ($data = $result->fetch_assoc()) {
            $update = $conn->prepare("UPDATE users SET longitude = ?, latitude = ? WHERE email = ?");
            $update->bind_param("dds", $longitude, $latitude, $email);
            if ($update->execute()) {
                echo json_encode(["message" => "Address updated successfully"]);
            } else {
                echo json_encode(["error" => "Update failed"]);
            }
            $update->close();
        } else {
            echo json_encode(["message" => "User Email ID not found"]);
        }

        $stmt->close();
    } else {
        echo json_encode(["message" => "Missing required parameters"]);
    }
} else {
    echo json_encode(["message" => "Invalid request method"]);
}

$conn->close(); */
?>

<?php
 include 'db.php';
 
header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];
 
$input = json_decode(file_get_contents('php://input'), true);

switch ($method){
	case 'GET':
	if(isset($_GET['email'])){
		
		$email     = $_GET['email'];
		$longitude = $_GET['longitude'];
		$latitude   = $_GET['latitude'];
		$result = $conn->query("SELECT email FROM users WHERE email='$email'");
		$data = $result->fetch_assoc();
       
		if ($data['email'] == $email) {
			//echo"<pre>"; print_r($data); exit("test");
			$conn->query("UPDATE users SET longitude = '".$longitude."',latitude = '".$latitude."' WHERE email = '".$email."'");
			echo json_encode(["message" => "Address Update successfully"]);
			break;
		}else{
			echo json_encode(["message" => "User Email Id Not Found"]);
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

$conn->close(); 
?>
