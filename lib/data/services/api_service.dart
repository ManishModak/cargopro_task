import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/object_model.dart';

/// Service class responsible for all HTTP operations with the REST API
/// This is part of the Model layer in MVVM architecture
class ApiService {
  static const String _baseUrl = 'https://api.restful-api.dev/objects';
  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// **READ Operation**: Fetches all objects from the API
  /// Returns a list of ObjectModel instances
  Future<List<ObjectModel>> getObjects() async {
    try {
      final uri = Uri.parse(_baseUrl);

      print('🌐 Fetching objects from: $uri');
      print('📤 Request headers: $_headers');

      final response = await _client.get(uri, headers: _headers);

      print('📡 GET Response status: ${response.statusCode}');
      print('📡 GET Response headers: ${response.headers}');
      print('📡 GET Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final objects = jsonList
            .map((json) => ObjectModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ Successfully fetched ${objects.length} objects');
        return objects;
      } else {
        print('❌ GET failed with status: ${response.statusCode}');
        print('❌ GET error body: ${response.body}');
        throw ApiException(
          'GET failed (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ GET Socket error: $e');
      throw ApiException('No internet connection', 0);
    } on FormatException catch (e) {
      print('❌ GET Format error: $e');
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      print('❌ GET Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('GET error: $e', 0);
    }
  }

  /// **READ Operation**: Fetches a single object by ID
  Future<ObjectModel> getObjectById(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');
      print('🌐 Fetching object with ID: $id');

      final response = await _client.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final object = ObjectModel.fromJson(json);
        print('✅ Successfully fetched object: ${object.name}');
        return object;
      } else if (response.statusCode == 404) {
        throw ApiException('Object not found', 404);
      } else {
        throw ApiException(
          'Failed to fetch object: ${response.statusCode}',
          response.statusCode,
        );
      }
    } on SocketException {
      throw ApiException('No internet connection', 0);
    } on FormatException {
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Unexpected error: $e', 0);
    }
  }

  /// **CREATE Operation**: Creates a new object
  Future<ObjectModel> createObject(ObjectModel object) async {
    try {
      final uri = Uri.parse(_baseUrl);

      // For CREATE, don't include ID in the request
      final requestData = <String, dynamic>{'name': object.name};

      // Only include data if it exists
      if (object.data != null && object.data!.isNotEmpty) {
        requestData['data'] = object.data;
      }

      final body = json.encode(requestData);

      print('🌐 Creating object: ${object.name}');
      print('📤 POST URL: $uri');
      print('📤 POST Headers: $_headers');
      print('📤 POST Body: $body');

      final response = await _client.post(uri, headers: _headers, body: body);

      print('📡 POST Response status: ${response.statusCode}');
      print('📡 POST Response headers: ${response.headers}');
      print('📡 POST Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        final createdObject = ObjectModel.fromJson(responseJson);
        print('✅ Successfully created object with ID: ${createdObject.id}');
        return createdObject;
      } else {
        print('❌ POST failed with status: ${response.statusCode}');
        print('❌ POST error body: ${response.body}');
        throw ApiException(
          'CREATE failed (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ POST Socket error: $e');
      throw ApiException('No internet connection', 0);
    } on FormatException catch (e) {
      print('❌ POST Format error: $e');
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      print('❌ POST Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('CREATE error: $e', 0);
    }
  }

  /// **UPDATE Operation**: Updates an existing object using PUT
  Future<ObjectModel> updateObject(String id, ObjectModel object) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');

      // Create request body without ID (API expects only name and data)
      final requestData = <String, dynamic>{'name': object.name};

      // Only include data if it exists and is not empty
      if (object.data != null && object.data!.isNotEmpty) {
        requestData['data'] = object.data;
      }

      final body = json.encode(requestData);

      print('🌐 Updating object with ID: $id');
      print('📤 PUT URL: $uri');
      print('📤 PUT Headers: $_headers');
      print('📤 PUT Body: $body');

      final response = await _client.put(uri, headers: _headers, body: body);

      print('📡 PUT Response status: ${response.statusCode}');
      print('📡 PUT Response headers: ${response.headers}');
      print('📡 PUT Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseJson = jsonDecode(response.body);
        final updatedObject = ObjectModel.fromJson(responseJson);
        print('✅ Successfully updated object: ${updatedObject.name}');
        return updatedObject;
      } else if (response.statusCode == 404) {
        print('❌ PUT Object not found: $id');
        throw ApiException('Object not found', 404);
      } else {
        print('❌ PUT failed with status: ${response.statusCode}');
        print('❌ PUT error body: ${response.body}');
        throw ApiException(
          'UPDATE failed (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ PUT Socket error: $e');
      throw ApiException('No internet connection', 0);
    } on FormatException catch (e) {
      print('❌ PUT Format error: $e');
      throw ApiException('Invalid response format', 0);
    } catch (e) {
      print('❌ PUT Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('UPDATE error: $e', 0);
    }
  }

  /// **DELETE Operation**: Deletes an object by ID
  Future<bool> deleteObject(String id) async {
    try {
      final uri = Uri.parse('$_baseUrl/$id');

      print('🌐 Deleting object with ID: $id');
      print('📤 DELETE URL: $uri');
      print('📤 DELETE Headers: $_headers');

      final response = await _client.delete(uri, headers: _headers);

      print('📡 DELETE Response status: ${response.statusCode}');
      print('📡 DELETE Response headers: ${response.headers}');
      print('📡 DELETE Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Successfully deleted object with ID: $id');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ DELETE Object not found: $id');
        throw ApiException('Object not found', 404);
      } else {
        print('❌ DELETE failed with status: ${response.statusCode}');
        print('❌ DELETE error body: ${response.body}');
        throw ApiException(
          'DELETE failed (${response.statusCode}): ${response.body}',
          response.statusCode,
        );
      }
    } on SocketException catch (e) {
      print('❌ DELETE Socket error: $e');
      throw ApiException('No internet connection', 0);
    } catch (e) {
      print('❌ DELETE Unexpected error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('DELETE error: $e', 0);
    }
  }

  /// Dispose method to clean up resources
  void dispose() {
    _client.close();
  }
}

/// Custom exception class for API-related errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';

  /// Helper method to get user-friendly error messages
  String get userMessage {
    switch (statusCode) {
      case 0:
        return 'Network error: Please check your internet connection';
      case 400:
        return 'Something went wrong. Please try again';
      case 404:
        return 'The requested item was not found';
      case 500:
        return 'Server error. Please try again later';
      case 503:
        return 'Service unavailable: Please try again later';
      default:
        // Include more details for debugging
        return 'API Error ($statusCode): $message';
    }
  }
}
