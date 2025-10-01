import 'dart:convert';
import 'dart:io';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class FileUploadValidController extends GetxController {
  // Reactive state
  var uploadingField = ''.obs;
  var previews = <String, String>{}.obs; // field -> local path or uploaded URL
  var errors = <String, String>{}.obs;   // field -> error message
  var uploadedFiles = <String, String>{}.obs; // field -> file name

  static const validTypes = ["image/jpeg", "image/png"];
  static const int maxFileSize = 5 * 1024 * 1024; // 5MB

  Future<void> handleFileChange(String field, {required XFile? image}) async {
    if (image == null) {
      errors[field] = 'No file selected';
      return;
    }

    final file = File(image.path);
    final extension = path.extension(file.path).toLowerCase();
    final mimeType =
    extension == ".png" ? MediaType("image", "png") : MediaType("image", "jpeg");

    uploadingField.value = field;
    clearError(field);

    // --- Validation ---
    if (!_isValidExtension(extension)) {
      _setError(field, "Upload JPG or PNG only.");
      uploadingField.value = '';
      return;
    }

    final fileSize = await file.length();
    if (fileSize > maxFileSize) {
      _setError(field, "Max file size is 5MB.");
      uploadingField.value = '';
      return;
    }

    // Show local preview immediately
    previews[field] = file.path;

    try {
      // --- Upload ---
      final uri = Uri.parse(
          'https://selfdrive.wticabs.com:3005/selfdrive/v1/files/upload?folder=bookingDocuments&acl=public-read&inline=1&key=userDocuments');

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

      final documentUrl = _extractDocumentUrl(resBody);
      if (documentUrl.isNotEmpty) {
        uploadedFiles[field] = image.name;
        previews[field] = documentUrl; // Replace local path with uploaded URL
        clearError(field);
      } else {
        _setError(field, "Upload failed. Invalid server response.");
      }
    } catch (e) {
      _setError(field, "Upload failed: $e");
    } finally {
      uploadingField.value = '';
    }
  }

  // --- Helpers ---
  bool _isValidExtension(String ext) {
    return [".jpg", ".jpeg", ".png"].contains(ext);
  }

  void _setError(String field, String message) {
    errors[field] = message;
  }

  void clearError(String field) {
    errors.remove(field);
  }

  void clearField(String field) {
    previews.remove(field);
    errors.remove(field);
    uploadedFiles.remove(field);
  }

  String _extractDocumentUrl(String responseBody) {
    try {
      final jsonRes = jsonDecode(responseBody);
      return jsonRes['publicUrl'] ??
          jsonRes['url'] ??
          jsonRes['result']?['url'] ??
          "";
    } catch (e) {
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
