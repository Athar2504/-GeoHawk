<?php 

include 'db.php';

header("Content-Type: application/json");

$method = $_SERVER['REQUEST_METHOD'];

if ($method == 'POST') {
    if (isset($_POST['email']) && isset($_FILES['images'])) {
        $email = $_POST['email'];
        $images = $_FILES['images'];

        // Validate user email
        $result = $conn->query("SELECT email FROM users WHERE email='$email'");
        $data = $result->fetch_assoc();

        if ($data) {
            // Define upload directory
            $uploadDir = __DIR__ . DIRECTORY_SEPARATOR . 'uploads' . DIRECTORY_SEPARATOR;
            if (!file_exists($uploadDir) && !mkdir($uploadDir, 0777, true) && !is_dir($uploadDir)) {
                echo json_encode(["message" => "Failed to create upload directory"]);
                exit();
            }

            $uploadedImages = [];

            // Handle single/multiple file uploads correctly
            $isMultiple = is_array($images['name']);
            $totalFiles = $isMultiple ? count($images['name']) : 1;

            // Limit to 3 images
            if ($totalFiles > 3) {
                echo json_encode(["message" => "You can upload up to 3 images only."]);
                exit();
            }

            for ($i = 0; $i < $totalFiles; $i++) {
                // Correct file path handling
                $fileTmpName = $isMultiple ? $images["tmp_name"][$i] : $images["tmp_name"];
                $fileError = $isMultiple ? $images['error'][$i] : $images['error'];
                $fileName = $isMultiple ? basename($images['name'][$i]) : basename($images['name']);

                // Ensure file upload is successful
                if ($fileError !== UPLOAD_ERR_OK) {
                    echo json_encode(["message" => "File upload error: " . $fileError]);
                    exit();
                }

                // Generate unique file name
                $imageName = uniqid() . "_" . $fileName;
                $imagePath = $uploadDir . $imageName;

                // Move the uploaded file
                if (move_uploaded_file($fileTmpName, $imagePath)) {
                    $uploadedImages[] = '/app/uploads/' . $imageName; // Store relative path
                }
            }

            if (!empty($uploadedImages)) {
                // Convert images array to JSON for better handling
                $imagePaths = json_encode($uploadedImages);

                // Store images in the database
                $stmt = $conn->prepare("UPDATE users SET profile_images = ? WHERE email = ?");
                $stmt->bind_param("ss", $imagePaths, $email);
                $stmt->execute();

                echo json_encode(["message" => "Images uploaded successfully", "images" => $uploadedImages]);
            } else {
                echo json_encode(["message" => "Failed to upload images"]);
            }
        } else {
            echo json_encode(["message" => "User Email Id Not Found"]);
        }
    } else {
        echo json_encode(["message" => "Missing email or images"]);
    }
} else {
    echo json_encode(["message" => "Invalid request method"]);
}

$conn->close();

?>
