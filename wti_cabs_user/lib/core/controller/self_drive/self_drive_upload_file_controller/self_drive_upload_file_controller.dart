import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploadController extends GetxController {
  var uploadingField = RxnString(); // Currently uploading field
  var uploadedFiles = <String, String>{}.obs; // field -> file name
  var previews = <String, String>{}.obs;      // field -> file URL
  var errors = <String, String>{}.obs;        // field -> error message

  static const validTypes = ["image/jpeg", "image/png"];
  static const maxFileSize = 5 * 1024 * 1024; // 5MB

  Future<void> handleFileChange(String field, {required XFile image}) async {
    try {
      print("\n=== Processing image for field: $field ===");
      final file = File(image.path);
      print("Selected file: ${image.name}, path: ${image.path}");

      // MIME type
      final ext = image.path.split('.').last.toLowerCase();
      final mimeType = ext == 'png' ? MediaType('image', 'png') : MediaType('image', 'jpeg');
      print("Detected MIME type: ${mimeType.type}/${mimeType.subtype}");

      if (!validTypes.contains("${mimeType.type}/${mimeType.subtype}")) {
        print("Invalid file type for $field");
        _setError(field, "Upload JPEG or PNG only.");
        return;
      }

      // File size
      final fileSize = await file.length();
      print("File size: $fileSize bytes");
      if (fileSize > maxFileSize) {
        print("File too large for $field");
        _setError(field, "Max file size is 5MB.");
        return;
      }

      uploadingField.value = field;
      print("Uploading started for field: $field");

      // Prepare URI
      final uri = Uri.parse(
        'https://selfdrive.wticabs.com:3005/selfdrive/v1/files/upload?folder=bookingDocuments&acl=public-read&inline=1&key=userDocuments',
      );

      final request = http.MultipartRequest("POST", uri)
        ..files.add(
          await http.MultipartFile.fromPath(
            "file",
            file.path,
            filename: image.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), "_"),
            contentType: mimeType,
          ),
        );

      // Optional headers
      request.headers.addAll({
        'Accept': 'application/json',
        // 'Authorization': 'Bearer <token>', // Uncomment if server requires auth
      });

      print("Sending multipart request to $uri");
      print("Request files: ${request.files.map((f) => f.filename).toList()}");
      print("Request headers: ${request.headers}");

      final response = await request.send();
      print("HTTP response status: ${response.statusCode}");

      final resBody = await response.stream.bytesToString();
      print("Upload response body: $resBody");

      final documentUrl = _extractDocumentUrl(resBody);
      print("Extracted document URL: $documentUrl");

      if (documentUrl.isNotEmpty) {
        uploadedFiles[field] = image.name;
        previews[field] = documentUrl;
        _clearError(field);
        print("Upload successful for $field");
      } else {
        throw Exception("Invalid URL from server");
      }
    } catch (err) {
      print("Upload error for field $field: $err");
      _setError(field, "Upload failed. Please try again.");
    } finally {
      uploadingField.value = null;
      print("Upload finished for field: $field\n");
    }
  }

  // ==== Helpers ====
  void _setError(String field, String message) {
    errors[field] = message;
    print("Error set for $field: $message");
  }

  void _clearError(String field) {
    errors[field] = "";
    print("Error cleared for $field");
  }

  String _extractDocumentUrl(String responseBody) {
    print("Extracting document URL from server response");
    try {
      final json = jsonDecode(responseBody);
      final url = json['publicUrl'] ?? json['url'] ?? json['result']?['url'] ?? "";
      print("Document URL extracted: $url");
      return url;
    } catch (e) {
      print("Error parsing JSON: $e");
      return "";
    }
  }

  bool validateUploads(int selectedTab) {
    errors.clear(); // clear previous errors

    // Emirates Resident
    if (selectedTab == 0) {
      if (!uploadedFiles.containsKey('eidFront')) _setError('eidFront', 'Required');
      if (!uploadedFiles.containsKey('eidBack')) _setError('eidBack', 'Required');
      if (!uploadedFiles.containsKey('dlFront')) _setError('dlFront', 'Required');
      if (!uploadedFiles.containsKey('dlBack')) _setError('dlBack', 'Required');
      if (!uploadedFiles.containsKey('passport')) _setError('passport', 'Required');
    }
    // Tourist
    else {
      if (!uploadedFiles.containsKey('passport')) _setError('passport', 'Required');
    }

    return errors.isEmpty;
  }
}