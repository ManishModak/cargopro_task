import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/object_controller.dart';
import '../data/services/api_service.dart';

/// App-level dependency injection setup
/// Initializes all controllers and services needed throughout the app
class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize API Service as a singleton
    Get.lazyPut<ApiService>(() => ApiService(), fenix: true);

    // Initialize AuthController as a singleton
    Get.lazyPut<AuthController>(() => AuthController(), fenix: true);

    // Initialize ObjectController as a permanent singleton to preserve user-created objects
    Get.put<ObjectController>(ObjectController(), permanent: true);
  }
}
