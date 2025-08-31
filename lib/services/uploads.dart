// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:image_picker/image_picker.dart'; // or file_picker

class UploadResult {
  final String? imagePath;
  final String? audioPath;
  final String? error;
  final int statusCode;

  UploadResult({
    this.imagePath,
    this.audioPath,
    this.error,
    required this.statusCode,
  });
}

class UploadService {
  static Future<UploadResult> uploadFiles({
    required String userId,
    required XFile imageFile,
    required XFile audioFile,
  }) async {
    var uri = Uri.parse('${Constants.uri}/upload/$userId');
    var request = http.MultipartRequest('POST', uri);

    if (kIsWeb) {
      // For web, use fromBytes
      final imageBytes = await imageFile.readAsBytes();
      final audioBytes = await audioFile.readAsBytes();
      print('Uploading image: ${imageFile.name}, bytes: ${imageBytes.length}');
      print('Uploading audio: ${audioFile.name}, bytes: ${audioBytes.length}');

      // Force correct MIME type for image
      String imageMime;
      final imageExt = imageFile.name.split('.').last.toLowerCase();
      if (imageExt == 'jpg' || imageExt == 'jpeg') {
        imageMime = 'image/jpeg';
      } else if (imageExt == 'png') {
        imageMime = 'image/png';
      } else {
        imageMime =
            lookupMimeType(imageFile.name) ?? 'application/octet-stream';
      }

      // Force correct MIME type for audio
      String audioMime;
      final audioExt = audioFile.name.split('.').last.toLowerCase();
      if (audioExt == 'mp3') {
        audioMime = 'audio/mpeg';
      } else if (audioExt == 'flac') {
        audioMime = 'audio/flac';
      } else {
        audioMime =
            lookupMimeType(audioFile.name) ?? 'application/octet-stream';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFile.name,
          contentType: MediaType.parse(imageMime),
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: audioFile.name,
          contentType: MediaType.parse(audioMime),
        ),
      );
    } else {
      // For mobile/desktop, use fromPath
      print('Uploading image from path: ${imageFile.path}');
      print('Uploading audio from path: ${audioFile.path}');

      // Force correct MIME type for image
      String imageMime;
      final imageExt = imageFile.path.split('.').last.toLowerCase();
      if (imageExt == 'jpg' || imageExt == 'jpeg') {
        imageMime = 'image/jpeg';
      } else if (imageExt == 'png') {
        imageMime = 'image/png';
      } else {
        imageMime =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';
      }

      // Force correct MIME type for audio
      String audioMime;
      final audioExt = audioFile.path.split('.').last.toLowerCase();
      if (audioExt == 'mp3') {
        audioMime = 'audio/mpeg';
      } else if (audioExt == 'flac') {
        audioMime = 'audio/flac';
      } else {
        audioMime =
            lookupMimeType(audioFile.path) ?? 'application/octet-stream';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(imageMime),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType.parse(audioMime),
        ),
      );
    }

    final streamedResponse = await request.send();
    final statusCode = streamedResponse.statusCode;
    final respStr = await streamedResponse.stream.bytesToString();
    if (statusCode == 200) {
      final respJson = json.decode(respStr);
      return UploadResult(
        imagePath: respJson['files']?['image'],
        audioPath: respJson['files']?['audio'],
        statusCode: statusCode,
      );
    } else {
      String? errorMsg;
      try {
        final respJson = json.decode(respStr);
        errorMsg = respJson['message'] ?? respStr;
      } catch (_) {
        errorMsg = respStr;
      }
      return UploadResult(error: errorMsg, statusCode: statusCode);
    }
  }

  static Future<UploadResult> uploadFilesWithFields({
    required String userId,
    required XFile imageFile,
    required XFile audioFile,
    required Map<String, String> fields,
  }) async {
    var uri = Uri.parse('${Constants.uri}/upload/$userId');
    var request = http.MultipartRequest('POST', uri);

    // Add metadata fields
    request.fields.addAll(fields);

    if (kIsWeb) {
      final imageBytes = await imageFile.readAsBytes();
      final audioBytes = await audioFile.readAsBytes();

      String imageMime;
      final imageExt = imageFile.name.split('.').last.toLowerCase();
      if (imageExt == 'jpg' || imageExt == 'jpeg') {
        imageMime = 'image/jpeg';
      } else if (imageExt == 'png') {
        imageMime = 'image/png';
      } else {
        imageMime =
            lookupMimeType(imageFile.name) ?? 'application/octet-stream';
      }

      String audioMime;
      final audioExt = audioFile.name.split('.').last.toLowerCase();
      if (audioExt == 'mp3') {
        audioMime = 'audio/mpeg';
      } else if (audioExt == 'flac') {
        audioMime = 'audio/flac';
      } else {
        audioMime =
            lookupMimeType(audioFile.name) ?? 'application/octet-stream';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: imageFile.name,
          contentType: MediaType.parse(imageMime),
        ),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audioBytes,
          filename: audioFile.name,
          contentType: MediaType.parse(audioMime),
        ),
      );
    } else {
      String imageMime;
      final imageExt = imageFile.path.split('.').last.toLowerCase();
      if (imageExt == 'jpg' || imageExt == 'jpeg') {
        imageMime = 'image/jpeg';
      } else if (imageExt == 'png') {
        imageMime = 'image/png';
      } else {
        imageMime =
            lookupMimeType(imageFile.path) ?? 'application/octet-stream';
      }

      String audioMime;
      final audioExt = audioFile.path.split('.').last.toLowerCase();
      if (audioExt == 'mp3') {
        audioMime = 'audio/mpeg';
      } else if (audioExt == 'flac') {
        audioMime = 'audio/flac';
      } else {
        audioMime =
            lookupMimeType(audioFile.path) ?? 'application/octet-stream';
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType.parse(imageMime),
        ),
      );
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          audioFile.path,
          contentType: MediaType.parse(audioMime),
        ),
      );
    }

    final streamedResponse = await request.send();
    final statusCode = streamedResponse.statusCode;
    final respStr = await streamedResponse.stream.bytesToString();
    if (statusCode == 200) {
      final respJson = json.decode(respStr);
      return UploadResult(
        imagePath: respJson['files']?['image'],
        audioPath: respJson['files']?['audio'],
        statusCode: statusCode,
      );
    } else {
      String? errorMsg;
      try {
        final respJson = json.decode(respStr);
        errorMsg = respJson['message'] ?? respStr;
      } catch (_) {
        errorMsg = respStr;
      }
      return UploadResult(error: errorMsg, statusCode: statusCode);
    }
  }
}
