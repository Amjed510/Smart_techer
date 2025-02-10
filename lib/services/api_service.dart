import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../models_for_api/word_model.dart';

class ApiService {
  final String baseUrl;
  final Duration timeout = const Duration(seconds: 3);
  final http.Client _client = http.Client();

  ApiService({required this.baseUrl});

  Future<List<WordModel>> fetchData() async {
    try {
      final response = await _client.get(
        Uri.parse(baseUrl),
        headers: {'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((item) => WordModel.fromJson(item)).toList();
      } else {
        throw Exception('Failed to fetch data: ${response.statusCode}');
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
      throw Exception('Failed to fetch data: $e');
    }
  }

  Future<(List<WordModel>, String?)> fetchDataWithEtag(String? eTag) async {
    try {
      print('Attempting to connect to: $baseUrl with ETag: $eTag');
      final headers = <String, String>{'Accept': 'application/json'};
      if (eTag != null) {
        headers['If-None-Match'] = eTag;
      }

      final response = await _client
          .get(
            Uri.parse(baseUrl),
            headers: headers,
          )
          .timeout(timeout);

      print('Response status code: ${response.statusCode}');
      final newEtag = response.headers['etag'];

      if (response.statusCode == 200) {
        print('Response body: ${response.body}');
        final List<dynamic> jsonData = json.decode(response.body);
        final items = jsonData.map((item) {
          return WordModel.fromJson({
            'id': item['id'],
            'text': item['text'],
            'image': item['image'],
            'level': item['level'],
          });
        }).toList();
        return (items, newEtag);
      } else if (response.statusCode == 304) {
        print('Data not changed (304), returning null list and new ETag.');
        return (<WordModel>[], newEtag ?? eTag);
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
      throw Exception('Failed to fetch data with ETag: $e');
    }
  }
}
