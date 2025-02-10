import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:teatcher_smarter/models_for_api/sentence_model.dart';

class ApiSentensService {
  final String baseUrl;
  late http.Client _client;
  final Duration timeout = const Duration(seconds: 3);

  ApiSentensService(this.baseUrl) {
    _client = http.Client();
  }

  // Fetch data from the API
  Future<List<SentenceModel>> fetchData() async {
    try {
      print('Attempting to connect to: $baseUrl');
      final response = await _client.get(
        Uri.parse(baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData
            .map((sentens) => SentenceModel.fromJson(sentens))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error fetching data: $e');
    }
  }

  // Fetch data using ETag to check for changes
  Future<(List<SentenceModel>, String?)> fetchDataWithEtag(String? eTag) async {
    try {
      print('Attempting to connect to: $baseUrl with ETag: $eTag');
      final headers = <String, String>{'Accept': 'application/json'};

      // Add ETag to the headers if available
      if (eTag != null) {
        headers['If-None-Match'] = eTag;
      }

      // Make GET request to the server with headers
      final response = await _client
          .get(
            Uri.parse(baseUrl),
            headers: headers,
          )
          .timeout(timeout);

      print('Response status code: ${response.statusCode}');
      if (response.statusCode != 304) {
        print('Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        // Fetch new ETag from response headers
        final newEtag = response.headers['etag'];

        // Parse the JSON response
        final List<dynamic> jsonData = json.decode(response.body);

        // Map the JSON to a list of SentenceModel objects and return it with the new ETag
        return (
          jsonData.map((sentence) => SentenceModel.fromJson(sentence)).toList(),
          newEtag
        );
      } else if (response.statusCode == 304) {
        // No changes, return empty list and the same ETag
        print('Data not changed (304), returning empty list and old ETag.');
        return (<SentenceModel>[], eTag);
      } else {
        throw Exception(
            'Failed to fetch data with ETag: ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('Socket Exception: $e');
      throw Exception(
          'Cannot connect to server. Please check if the server is running.');
    } on TimeoutException catch (e) {
      print('Timeout Exception: $e');
      throw Exception(
          'Connection timed out. Please check your network connection.');
    } catch (e) {
      print('Error details: $e');
      throw Exception('Error syncing data: $e');
    }
  }
}
