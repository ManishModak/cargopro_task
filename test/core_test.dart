// Core unit tests for CargoPro Task
// Tests API calls and controller functions with mocks as required by objectives

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:cargopro_task/data/services/api_service.dart';
import 'package:cargopro_task/data/models/object_model.dart';
import 'package:cargopro_task/controllers/object_controller.dart';

import 'core_test.mocks.dart';

// Generate mocks for testing
@GenerateMocks([http.Client, ApiService])
void main() {
  group('Core Unit Tests', () {
    setUp(() {
      Get.testMode = true;
    });

    tearDown(() {
      Get.reset();
    });

    // TEST 1: API Call with Mock
    test(
      'ApiService.getObjects should return objects when API call succeeds',
      () async {
        // Arrange
        final mockClient = MockClient();
        final apiService = ApiService(client: mockClient);

        final mockResponse = [
          {
            'id': '1',
            'name': 'Test Object',
            'data': {'color': 'red'},
          },
        ];

        when(mockClient.get(any, headers: anyNamed('headers'))).thenAnswer(
          (_) async => http.Response(json.encode(mockResponse), 200),
        );

        // Act
        final result = await apiService.getObjects();

        // Assert
        expect(result.length, 1);
        expect(result[0].name, 'Test Object');
        expect(result[0].id, '1');
        verify(mockClient.get(any, headers: anyNamed('headers'))).called(1);
      },
    );

    // TEST 2: Controller Function with Mock
    test(
      'ObjectController.createObject should add object when API succeeds',
      () async {
        // Arrange
        final mockApiService = MockApiService();
        Get.put<ApiService>(mockApiService);

        final controller = ObjectController();
        final testObject = ObjectModel(
          name: 'New Object',
          data: {'test': 'data'},
        );
        final createdObject = ObjectModel(
          id: '123',
          name: 'New Object',
          data: {'test': 'data'},
        );

        when(
          mockApiService.createObject(testObject),
        ).thenAnswer((_) async => createdObject);
        when(
          mockApiService.getObjects(),
        ).thenAnswer((_) async => [createdObject]);

        // Act
        final result = await controller.createObject(testObject);

        // Assert
        expect(result, isTrue);
        expect(controller.objects.length, 1);
        expect(controller.objects[0].id, '123');
        expect(controller.isCreating, isFalse);
        verify(mockApiService.createObject(testObject)).called(1);
      },
    );
  });
}
