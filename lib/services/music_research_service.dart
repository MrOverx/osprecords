// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:osprecords/utils/constants.dart';

class MusicResearchService {
  Future<Map<String, dynamic>> fetchMetadataByUrl(String audioUrl) async {
    final uri = Uri.parse(
      '${Constants.uri}/metadata',
    ).replace(queryParameters: {'url': audioUrl});
    print('Requesting metadata from: $uri');
    final res = await http.get(
      uri,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to fetch metadata: ${res.statusCode} ${res.body}',
      );
    }

    final decoded = jsonDecode(res.body);
    return Map<String, dynamic>.from(decoded as Map<String, dynamic>);
  }
}
