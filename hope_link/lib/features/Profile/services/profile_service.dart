import 'dart:convert';
import 'dart:io';
import 'package:hope_link/config/constants/api_endpoints.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfile(String token) async {
    final res = await http.get(
      Uri.parse(ApiEndpoints.getProfile),
      headers: {"Authorization": "Bearer $token"},
    );
    return jsonDecode(res.body);
  }

  static Future<void> updateProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    await http.put(
      Uri.parse(ApiEndpoints.updateProfile),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );
  }

  static Future<void> uploadImage(String token, File file) async {
    try {
      print('Starting image upload...');
      print('File path: ${file.path}');
      print('File exists: ${await file.exists()}');

      // Get file extension and validate it
      final fileExtension = file.path.split('.').last.toLowerCase();
      if (!['jpg', 'jpeg', 'png'].contains(fileExtension)) {
        throw Exception(
          'Invalid file type. Only JPG, JPEG, and PNG are allowed.',
        );
      }

      // Determine the content type based on file extension
      final contentType = fileExtension == 'png' ? 'image/png' : 'image/jpeg';

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(ApiEndpoints.uploadProfilePhoto),
      );

      print('Adding authorization header');
      request.headers["Authorization"] = "Bearer $token";

      print('Creating multipart file with content type: $contentType');
      final multipartFile = await http.MultipartFile.fromPath(
        "profileImage",
        file.path,
        contentType: MediaType(
          'image',
          fileExtension == 'jpg' ? 'jpeg' : fileExtension,
        ),
      );
      request.files.add(multipartFile);

      print('Sending request to: ${ApiEndpoints.uploadProfilePhoto}');
      final streamedResponse = await request.send();

      final responseData = await streamedResponse.stream.bytesToString();
      print('Response status: ${streamedResponse.statusCode}');
      print('Response body: $responseData');

      if (streamedResponse.statusCode != 200) {
        try {
          final error = jsonDecode(responseData);
          throw Exception(
            'Server error (${streamedResponse.statusCode}): ${error['message'] ?? 'Unknown error'}',
          );
        } catch (e) {
          throw Exception(
            'Server error (${streamedResponse.statusCode}): $responseData',
          );
        }
      }

      // Verify the response contains the expected data
      try {
        final responseJson = jsonDecode(responseData);
        if (responseJson['imageUrl'] == null) {
          print('Warning: Server response does not contain imageUrl');
        }
      } catch (e) {
        print('Warning: Could not parse server response as JSON');
      }
    } catch (e) {
      print('Error in uploadImage: ${e.toString()}');
      print('Error type: ${e.runtimeType}');
      if (e is http.ClientException) {
        print('HTTP Client Exception: ${e.message}');
        print('URI: ${e.uri}');
      }
      rethrow;
    }
  }

  static Future<void> uploadCV(String token, File file) async {
    try {
      print('Starting CV upload...');
      print('File path: ${file.path}');
      print('File exists: ${await file.exists()}');

      // Validate file type
      final fileExtension = file.path.split('.').last.toLowerCase();
      if (!['pdf', 'doc', 'docx'].contains(fileExtension)) {
        throw Exception(
          'Invalid file type. Only PDF, DOC, and DOCX are allowed.',
        );
      }

      final request = http.MultipartRequest(
        "POST",
        Uri.parse(ApiEndpoints.uploadCV),
      );

      request.headers["Authorization"] = "Bearer $token";

      final multipartFile = await http.MultipartFile.fromPath(
        "cv", // Field name should be "cv" as per API requirement
        file.path,
        contentType: MediaType(
          'application',
          fileExtension == 'pdf' ? 'pdf' : 'msword', // For .doc and .docx
        ),
      );
      request.files.add(multipartFile);

      print('Sending request to: ${ApiEndpoints.uploadCV}');
      final streamedResponse = await request.send();

      final responseData = await streamedResponse.stream.bytesToString();
      print('Response status: ${streamedResponse.statusCode}');
      print('Response body: $responseData');

      if (streamedResponse.statusCode != 200) {
        try {
          final error = jsonDecode(responseData);
          throw Exception(
            'Server error (${streamedResponse.statusCode}): ${error['message'] ?? 'Unknown error'}',
          );
        } catch (e) {
          throw Exception(
            'Server error (${streamedResponse.statusCode}): $responseData',
          );
        }
      }

      // Verify the response contains the expected data
      try {
        final responseJson = jsonDecode(responseData);
        if (responseJson['cvUrl'] == null) {
          print('Warning: Server response does not contain cvUrl');
        }
      } catch (e) {
        print('Warning: Could not parse server response as JSON');
      }
    } catch (e) {
      print('Error in uploadCV: ${e.toString()}');
      print('Error type: ${e.runtimeType}');
      if (e is http.ClientException) {
        print('HTTP Client Exception: ${e.message}');
        print('URI: ${e.uri}');
      }
      rethrow;
    }
  }
}
