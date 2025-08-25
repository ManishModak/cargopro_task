import 'dart:convert';
import 'package:get/get.dart';
import '../data/models/object_model.dart';
import '../data/services/api_service.dart';

/// ObjectController (ViewModel) manages CRUD operations and object state
/// This is the ViewModel layer in MVVM architecture that handles:
/// - Object list management with reactive state
/// - Create, Read, Update, Delete operations
/// - Loading states and error handling
/// - Pagination and data synchronization
class ObjectController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  // Reactive state variables using GetX
  final RxList<ObjectModel> _objects = <ObjectModel>[].obs;
  final RxList<ObjectModel> _userCreatedObjects =
      <ObjectModel>[].obs; // Track user-created objects
  final RxBool _isLoading = false.obs;
  final RxBool _isCreating = false.obs;
  final RxBool _isUpdating = false.obs;
  final RxBool _isDeleting = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxBool _hasError = false.obs;
  final Rx<ObjectModel?> _selectedObject = Rx<ObjectModel?>(null);

  // Pagination state variables
  final RxBool _isLoadingMore = false.obs;
  final RxBool _hasMoreData = true.obs;
  final RxInt _currentPage = 1.obs;
  final RxInt _pageSize = 10.obs;
  final RxInt _totalObjects = 0.obs;
  final RxList<ObjectModel> _allObjects =
      <ObjectModel>[].obs; // Store all objects

  // Getters for accessing state
  List<ObjectModel> get objects => _objects;
  bool get isLoading => _isLoading.value;
  bool get isCreating => _isCreating.value;
  bool get isUpdating => _isUpdating.value;
  bool get isDeleting => _isDeleting.value;
  String get errorMessage => _errorMessage.value;
  bool get hasError => _hasError.value;
  ObjectModel? get selectedObject => _selectedObject.value;
  bool get isEmpty => _objects.isEmpty && !_isLoading.value;

  // Pagination getters
  bool get isLoadingMore => _isLoadingMore.value;
  bool get hasMoreData => _hasMoreData.value;
  int get currentPage => _currentPage.value;
  int get pageSize => _pageSize.value;
  int get totalObjects => _totalObjects.value;
  int get totalPages => (_totalObjects.value / _pageSize.value).ceil();

  /// Helper method to check if an object is user-created (can be edited/deleted)
  bool isUserCreated(String id) {
    // Reserved objects have IDs 1-13, user-created have dynamic IDs
    final numericId = int.tryParse(id);
    return numericId == null || numericId > 13;
  }

  @override
  void onInit() {
    super.onInit();
    print(
      '🔧 ObjectController: Initializing (user-created: ${_userCreatedObjects.length})',
    );
    // Automatically fetch objects when controller is initialized
    // Skip in test mode to avoid GetX snackbar issues
    if (!Get.testMode) {
      fetchObjects();
    }
  }

  /// **READ Operation**: Fetches all objects from the API
  Future<void> fetchObjects({bool showLoading = true}) async {
    try {
      if (showLoading) _isLoading.value = true;
      _hasError.value = false;
      _errorMessage.value = '';

      // Reset pagination state for fresh fetch
      _resetPagination();

      print('🔄 ObjectController: Fetching objects...');

      // Fetch all objects without pagination
      final fetchedObjects = await _apiService.getObjects();

      // API returns only reserved objects (1-13) in GET /objects
      // We need to merge with user-created objects stored locally
      print(
        '🔍 ObjectController: Before merge - User-created objects: ${_userCreatedObjects.length}',
      );
      for (var obj in _userCreatedObjects) {
        print('  - User object: ${obj.id} (${obj.name})');
      }

      final combinedObjects = [..._userCreatedObjects, ...fetchedObjects];
      _allObjects.assignAll(combinedObjects);
      _totalObjects.value = combinedObjects.length;

      // Apply pagination to display first page
      _applyPagination();

      print(
        '✅ Successfully fetched ${fetchedObjects.length} reserved objects + ${_userCreatedObjects.length} user-created = ${combinedObjects.length} total',
      );
    } on ApiException catch (e) {
      _hasError.value = true;
      _errorMessage.value = e.userMessage;

      print('❌ ObjectController: API Error - ${e.message}');

      if (!Get.testMode) {
        Get.snackbar(
          'Error Loading Objects',
          e.userMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Unexpected error occurred';

      print('❌ ObjectController: Unexpected error - $e');

      if (!Get.testMode) {
        Get.snackbar(
          'Error',
          'Failed to load objects. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (showLoading) _isLoading.value = false;
    }
  }

  /// Applies pagination to the current objects list
  void _applyPagination() {
    final startIndex = (_currentPage.value - 1) * _pageSize.value;
    final endIndex = startIndex + _pageSize.value;

    if (startIndex < _allObjects.length) {
      final pageObjects = _allObjects.sublist(
        startIndex,
        endIndex > _allObjects.length ? _allObjects.length : endIndex,
      );
      _objects.assignAll(pageObjects);
    } else {
      _objects.clear();
    }

    // Check if there are more pages
    _hasMoreData.value = endIndex < _allObjects.length;
  }

  /// Loads more objects for pagination (client-side)
  Future<void> loadMoreObjects() async {
    if (_isLoadingMore.value || !_hasMoreData.value) return;

    try {
      _isLoadingMore.value = true;
      _hasError.value = false;
      _errorMessage.value = '';

      final nextPage = _currentPage.value + 1;
      _currentPage.value = nextPage;

      print('🔄 ObjectController: Loading page $nextPage...');

      // Apply pagination for the next page
      _applyPagination();

      print('✅ Loaded page $nextPage. Total displayed: ${_objects.length}');
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to load more objects';

      print('❌ ObjectController: Load more unexpected error - $e');

      if (!Get.testMode) {
        Get.snackbar(
          'Error',
          'Failed to load more objects. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      }
    } finally {
      _isLoadingMore.value = false;
    }
  }

  /// Navigates to a specific page
  void goToPage(int pageNumber) {
    if (pageNumber < 1 || pageNumber > totalPages) return;

    print('🔄 ObjectController: Navigating to page $pageNumber');
    _currentPage.value = pageNumber;
    _applyPagination();
  }

  /// Changes the page size and refetches objects
  Future<void> changePageSize(int newPageSize) async {
    if (newPageSize <= 0 || newPageSize == _pageSize.value) return;

    print(
      '🔄 ObjectController: Changing page size from ${_pageSize.value} to $newPageSize',
    );

    _pageSize.value = newPageSize;
    _currentPage.value = 1;
    _hasMoreData.value = true;

    // Reapply pagination with new page size
    _applyPagination();
  }

  /// Resets pagination state
  void _resetPagination() {
    _currentPage.value = 1;
    _hasMoreData.value = true;
    _totalObjects.value = 0;
    _allObjects.clear();
    _objects.clear();
  }

  /// **CREATE Operation**: Creates a new object
  Future<bool> createObject(ObjectModel object) async {
    try {
      _isCreating.value = true;
      _hasError.value = false;

      print('🔄 ObjectController: Creating object "${object.name}"...');

      final createdObject = await _apiService.createObject(object);

      // Store user-created object locally since API doesn't return it in GET /objects
      _userCreatedObjects.insert(0, createdObject);
      print(
        '📝 ObjectController: Stored user-created object. Total user-created: ${_userCreatedObjects.length}',
      );

      print('✅ ObjectController: Created object with ID: ${createdObject.id}');

      // Show success snackbar immediately (before navigation)
      if (!Get.testMode) {
        Get.snackbar(
          'Created! ✅',
          '"${createdObject.name}" added successfully',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
          duration: const Duration(seconds: 3),
        );
      }

      // Refresh to show updated list (reserved + user-created objects)
      await fetchObjects(showLoading: false);

      return true;
    } on ApiException catch (e) {
      print('❌ ObjectController: Create failed - ${e.message}');

      if (!Get.testMode) {
        Get.snackbar(
          'Creation Failed',
          e.userMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      }

      return false;
    } finally {
      _isCreating.value = false;
    }
  }

  /// **READ Operation**: Fetches a single object by ID and sets as selected
  Future<void> selectObject(String id) async {
    try {
      _isLoading.value = true;
      _hasError.value = false;

      print('🔄 ObjectController: Fetching object with ID: $id');

      final object = await _apiService.getObjectById(id);
      _selectedObject.value = object;

      print('✅ ObjectController: Selected object "${object.name}"');
    } on ApiException catch (e) {
      _hasError.value = true;
      _errorMessage.value = e.userMessage;

      if (!Get.testMode) {
        Get.snackbar(
          'Error',
          e.userMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } catch (e) {
      _hasError.value = true;
      _errorMessage.value = 'Failed to load object details';

      if (!Get.testMode) {
        Get.snackbar(
          'Error',
          'Failed to load object details',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
        );
      }
    } finally {
      _isLoading.value = false;
    }
  }

  /// Sets the selected object
  void setSelectedObject(ObjectModel object) {
    _selectedObject.value = object;
  }

  /// Clears the selected object
  void clearSelection() {
    _selectedObject.value = null;
  }

  /// Refreshes the object list (pull-to-refresh)
  Future<void> refreshObjects() async {
    print('🔄 ObjectController: Refreshing objects...');
    _resetPagination();
    await fetchObjects(showLoading: false);
  }

  /// Clears all error states
  void clearError() {
    _hasError.value = false;
    _errorMessage.value = '';
  }

  /// Validates JSON string input for data field
  bool isValidJson(String jsonString) {
    if (jsonString.trim().isEmpty) return true; // Empty is valid

    try {
      final decoded = json.decode(jsonString);
      return decoded is Map<String, dynamic>;
    } catch (e) {
      return false;
    }
  }

  /// Parses JSON string to Map<String, dynamic>
  Map<String, dynamic>? parseJsonData(String jsonString) {
    if (jsonString.trim().isEmpty) return null;

    try {
      final decoded = json.decode(jsonString);
      return decoded as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Converts Map to formatted JSON string for display
  String formatJsonForDisplay(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return '{}';

    try {
      const encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      // Fallback to basic formatting if JsonEncoder fails
      try {
        return jsonEncode(data);
      } catch (e2) {
        return data.toString();
      }
    }
  }

  /// Get example JSON string for form hints
  String getExampleJsonHint() {
    return '''{\n  "color": "Silver",\n  "capacity": "512 GB",\n  "price": 2399\n}''';
  }

  /// **UPDATE Operation**: Updates an existing object (only user-created objects)
  Future<bool> updateObject(String id, ObjectModel object) async {
    try {
      _isUpdating.value = true;

      // Check if this is a reserved object that cannot be updated
      if (!isUserCreated(id)) {
        print('❌ ObjectController: Cannot update reserved object with ID: $id');
        if (!Get.testMode) {
          Get.snackbar(
            'Update Not Allowed',
            'Reserved objects (ID 1-13) cannot be modified',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            duration: const Duration(seconds: 3),
          );
        }
        return false;
      }

      print('🔄 ObjectController: Updating object with ID: $id');

      final updatedObject = await _apiService.updateObject(id, object);

      // Update in user-created objects list
      final userIndex = _userCreatedObjects.indexWhere((obj) => obj.id == id);
      if (userIndex != -1) {
        _userCreatedObjects[userIndex] = updatedObject;
      }

      // Update in main objects list
      final index = _allObjects.indexWhere((obj) => obj.id == id);
      if (index != -1) {
        _allObjects[index] = updatedObject;
      }

      // Update selected object if it's the same one
      if (_selectedObject.value?.id == id) {
        _selectedObject.value = updatedObject;
      }

      print('✅ ObjectController: Updated "${updatedObject.name}"');

      return true;
    } on ApiException catch (e) {
      print('❌ ObjectController: Update failed - ${e.message}');

      if (!Get.testMode) {
        Get.snackbar(
          'Update Failed',
          e.userMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      }

      return false;
    } finally {
      _isUpdating.value = false;
    }
  }

  /// **DELETE Operation**: Deletes an object (only user-created objects)
  Future<bool> deleteObject(String id) async {
    try {
      _isDeleting.value = true;

      // Check if this is a reserved object that cannot be deleted
      if (!isUserCreated(id)) {
        print('❌ ObjectController: Cannot delete reserved object with ID: $id');
        if (!Get.testMode) {
          Get.snackbar(
            'Delete Not Allowed',
            'Reserved objects (ID 1-13) cannot be deleted',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.error,
            colorText: Get.theme.colorScheme.onError,
            duration: const Duration(seconds: 3),
          );
        }
        return false;
      }

      print('🔄 ObjectController: Deleting object with ID: $id');

      // Find the object before deletion for potential rollback
      final objectIndex = _allObjects.indexWhere((obj) => obj.id == id);
      final userObjectIndex = _userCreatedObjects.indexWhere(
        (obj) => obj.id == id,
      );

      if (objectIndex == -1) {
        throw Exception('Object not found in local list');
      }

      final objectToDelete = _allObjects[objectIndex];

      // Optimistic update: Remove from both lists immediately
      _allObjects.removeAt(objectIndex);
      if (userObjectIndex != -1) {
        _userCreatedObjects.removeAt(userObjectIndex);
      }

      // Clear selection if the deleted object was selected
      if (_selectedObject.value?.id == id) {
        _selectedObject.value = null;
      }

      try {
        // Perform API deletion
        await _apiService.deleteObject(id);

        print('✅ ObjectController: Deleted "${objectToDelete.name}"');

        return true;
      } catch (e) {
        // Rollback optimistic update on API failure
        _allObjects.insert(objectIndex, objectToDelete);
        if (userObjectIndex != -1) {
          _userCreatedObjects.insert(userObjectIndex, objectToDelete);
        }
        rethrow;
      }
    } on ApiException catch (e) {
      print('❌ ObjectController: Delete failed - ${e.message}');

      if (!Get.testMode) {
        Get.snackbar(
          'Deletion Failed',
          e.userMessage,
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Get.theme.colorScheme.error,
          colorText: Get.theme.colorScheme.onError,
          duration: const Duration(seconds: 3),
        );
      }

      return false;
    } finally {
      _isDeleting.value = false;
    }
  }

  /// Gets object count for display
  String get objectCountText {
    final count = _objects.length;
    if (count == 0) return 'No objects';
    if (count == 1) return '1 object';
    return '$count objects';
  }
}
