import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploadValidController extends GetxController {

  final selectedTab = 0.obs; // 0 = Resident, 1 = Tourist

  // Reactive state
  var uploadingField = ''.obs;
  var localPreviews = <String, String>{}.obs; // field -> local path
  var uploadedPreviews = <String, String>{}.obs; // field -> uploaded URL
  var errors = <String, String>{}.obs;   // field -> error message
  var uploadedFiles = <String, String>{}.obs; // field -> file name

  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  Future<void> handleFileChange(String field, {required XFile? image}) async {
    print("=== handleFileChange called for field: $field ===");

    if (image == null) {
      print("No file selected for field: $field");
      errors[field] = 'No file selected';
      return;
    }

    final file = File(image.path);
    final extension = path.extension(file.path).toLowerCase();
    final mimeType =
    extension == ".png" ? MediaType("image", "png") : MediaType("image", "jpeg");

    print("Picked file path: ${file.path}, extension: $extension, mimeType: $mimeType");

    uploadingField.value = field;
    clearError(field);

    // --- Validation ---
    if (!_isValidExtension(extension)) {
      _setError(field, "Upload JPG or PNG only.");
      print("Invalid file extension for field: $field");
      uploadingField.value = '';
      return;
    }

    final fileSize = await file.length();
    print("File size for $field: $fileSize bytes");
    if (fileSize > maxFileSize) {
      _setError(field, "Max file size is 5MB.");
      print("File too large for field: $field");
      uploadingField.value = '';
      return;
    }

    // Show local preview immediately
    localPreviews[field] = file.path;
    print("Local preview set for $field: ${file.path}");

    try {
      // --- Upload ---
      final uri = Uri.parse(
          'https://selfdrive.wticabs.com:3005/selfdrive/v1/files/upload?folder=bookingDocuments&acl=public-read&inline=1&key=userDocuments');
      print("Uploading $field to $uri");

      final request = http.MultipartRequest("POST", uri)
        ..files.add(await http.MultipartFile.fromPath(
          "file",
          file.path,
          filename: image.name.replaceAll(RegExp(r'[^a-zA-Z0-9_.]'), "_"),
          contentType: mimeType,
        ));

      request.headers.addAll({'Accept': 'application/json'});

      final response = await request.send();
      final resBody = await response.stream.bytesToString();

      print("Upload response for $field: $resBody");

      final documentUrl = _extractDocumentUrl(resBody);
      if (documentUrl.isNotEmpty) {
        uploadedFiles[field] = image.name;
        uploadedPreviews[field] = documentUrl; // replace preview with uploaded URL
        clearError(field);
        print("Upload successful for $field, URL: $documentUrl");
      } else {
        _setError(field, "Upload failed. Invalid server response.");
        print("Upload failed for $field: Invalid server response");
      }
    } catch (e) {
      _setError(field, "Upload failed: $e");
      print("Upload failed for $field: $e");
    } finally {
      uploadingField.value = '';
      print("Uploading field reset for $field");
    }
  }

  // --- Helpers ---
  bool _isValidExtension(String ext) {
    return [".jpg", ".jpeg", ".png"].contains(ext);
  }

  void _setError(String field, String message) {
    errors[field] = message;
    print("Error set for $field: $message");
  }

  void clearError(String field) {
    errors.remove(field);
    print("Error cleared for $field");
  }

  void clearField(String field) {
    localPreviews.remove(field);
    uploadedPreviews.remove(field);
    errors.remove(field);
    uploadedFiles.remove(field);
    print("Cleared all data for field: $field");
  }

  String _extractDocumentUrl(String responseBody) {
    try {
      final jsonRes = jsonDecode(responseBody);
      final url = jsonRes['publicUrl'] ??
          jsonRes['url'] ??
          jsonRes['result']?['url'] ??
          "";
      print("Extracted document URL: $url");
      return url;
    } catch (e) {
      print("Failed to parse upload response: $e");
      return "";
    }
  }

  bool validateUploads(int selectedTab) {
    errors.clear(); // clear previous errors
    print("Validating uploads for tab: $selectedTab");

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
      if (!uploadedFiles.containsKey('visa')) _setError('visa', 'Required');
      if (!uploadedFiles.containsKey('hcdl')) _setError('hcdl', 'Required');
      if (!uploadedFiles.containsKey('idp')) _setError('idp', 'Required');
    }

    print("Validation errors: ${errors.toString()}");
    return errors.isEmpty;
  }
}
