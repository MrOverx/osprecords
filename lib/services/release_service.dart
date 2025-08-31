import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:osprecords/models/album_model.dart';
import 'package:osprecords/providers/user_provider.dart';
import 'package:osprecords/utils/constants.dart';
import 'package:osprecords/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReleaseService {
  Future<bool> submitRelease({
    required BuildContext context,
    required AlbumModel album,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user.id;
      if (userId.isEmpty) {
        showSnackBar(context, 'You must be signed in to submit a release.');
        return false;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token') ?? '';
      if (token.isEmpty) {
        showSnackBar(context, 'Missing auth token. Please sign in again.');
        return false;
      }

      final uri = Uri.parse('${Constants.uri}/api/$userId/releases');
      final Map<String, dynamic> payload = album.toJson();
      // Ensure required nested fields exist for server validation
      payload['artists'] = (payload['artists'] as List<dynamic>).map((a) {
        final m = Map<String, dynamic>.from(a as Map<String, dynamic>);
        m['spotifyUrl'] = (m['spotifyUrl'] ?? '').toString();
        m['imageUrl'] = (m['imageUrl'] ?? '').toString();
        m['followers'] = (m['followers'] ?? 0) as int;
        return m;
      }).toList();

      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
        body: jsonEncode(payload),
      );

      if (!context.mounted) return false;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Release submitted successfully');
          return;
        },
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      if (!context.mounted) return false;
      showSnackBar(context, 'Failed to submit release: ${e.toString()}');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchReleases({
    required BuildContext context,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user.id;
      if (userId.isEmpty) {
        showSnackBar(context, 'You must be signed in to view releases.');
        return [];
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token') ?? '';
      if (token.isEmpty) {
        showSnackBar(context, 'Missing auth token. Please sign in again.');
        return [];
      }

      final uri = Uri.parse('${Constants.uri}/api/$userId/releases');
      final response = await http.get(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (!context.mounted) return [];
      if (response.statusCode == 200) {
        final List<dynamic> decoded =
            jsonDecode(response.body) as List<dynamic>;
        return decoded
            .map((e) => Map<String, dynamic>.from(e as Map<String, dynamic>))
            .toList();
      }

      httpErrorHandle(response: response, context: context, onSuccess: () {});
      return [];
    } catch (e) {
      if (!context.mounted) return [];
      showSnackBar(context, 'Failed to fetch releases: ${e.toString()}');
      return [];
    }
  }

  Future<void> deleteRelease({
    required BuildContext context,
    required String releaseId,
  }) async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final userId = userProvider.user.id;
      if (userId.isEmpty) {
        showSnackBar(context, 'You must be signed in to delete a release.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('x-auth-token') ?? '';
      if (token.isEmpty) {
        showSnackBar(context, 'Missing auth token. Please sign in again.');
        return;
      }

      final uri = Uri.parse('${Constants.uri}/api/$userId/releases/$releaseId');
      final response = await http.delete(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'x-auth-token': token,
        },
      );

      if (!context.mounted) return;
      httpErrorHandle(
        response: response,
        context: context,
        onSuccess: () {
          showSnackBar(context, 'Release deleted');
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      showSnackBar(context, 'Failed to delete release: ${e.toString()}');
    }
  }
}
