import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

/// Root widget that manages navigation based on authentication state
/// This is the main routing logic for the MVVM architecture
class Root extends GetWidget<AuthController> {
  const Root({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Show loading screen while checking auth state
      if (controller.user == null && !controller.isLoading) {
        return const LoginPage();
      }

      // Show home page if user is authenticated
      if (controller.user != null) {
        return const HomePage();
      }

      // Show loading screen during authentication
      return const _LoadingScreen();
    });
  }
}

/// Loading screen shown during authentication process
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Get.theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_shipping,
                size: 64,
                color: Get.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'CargoPro',
              style: Get.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Get.theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Get.theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Checking authentication...',
              style: Get.textTheme.bodyMedium?.copyWith(
                color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
