import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

/// AuthController (ViewModel) manages authentication state and logic
/// This is the ViewModel layer in MVVM architecture that handles:
/// - User authentication state
/// - OTP sending and verification
/// - Login/logout functionality
/// - Cross-platform support (mobile & web)
class AuthController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Reactive state variables using GetX
  final Rx<User?> _user = Rx<User?>(null);
  final RxBool _isLoading = false.obs;
  final RxBool _isCodeSent = false.obs;
  final RxString _verificationId = ''.obs;
  final RxInt _resendToken = 0.obs;
  final RxString _phoneNumber = ''.obs;
  // Web confirmation result for OTP verification
  ConfirmationResult? _webConfirmationResult;

  // Getters for accessing state
  User? get user => _user.value;
  bool get isLoading => _isLoading.value;
  bool get isCodeSent => _isCodeSent.value;
  bool get isLoggedIn => _user.value != null;
  String get phoneNumber => _phoneNumber.value;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state changes
    _user.bindStream(_auth.authStateChanges());
  }

  /// Sends OTP to the provided phone number
  /// Handles both mobile and web platforms
  Future<void> sendOtp(String phoneNumber) async {
    try {
      _isLoading.value = true;
      _phoneNumber.value = phoneNumber;

      // 🚀 DEVELOPMENT BYPASS: Skip Firebase for blocked devices
      if (phoneNumber == '+91 99999 99999') {
        await _simulateOtpForDevelopment();
        return;
      }

      if (kIsWeb) {
        // WEB PLATFORM - Uses Firebase automatic reCAPTCHA
        await _sendOtpWeb(phoneNumber);
      } else {
        // MOBILE PLATFORM - Uses native SMS verification
        await _sendOtpMobile(phoneNumber);
      }
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Error',
        'Failed to send OTP: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Web-specific OTP sending with reCAPTCHA
  Future<void> _sendOtpWeb(String phoneNumber) async {
    try {
      // Use Firebase's automatic reCAPTCHA for web (free version)
      _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);

      _isLoading.value = false;
      _isCodeSent.value = true;

      Get.snackbar(
        'OTP Sent 📱',
        'Verification code has been sent to $phoneNumber',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      _handleAuthError(e);
    }
  }

  /// Mobile-specific OTP sending (native SMS)
  Future<void> _sendOtpMobile(String phoneNumber) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-verification for Android (when possible)
        print('📱 Auto-verification completed for Android');
        await _signInWithCredential(credential);
      },
      verificationFailed: (FirebaseAuthException e) {
        print('❌ Mobile verification failed: ${e.message}');
        _isLoading.value = false;
        _handleAuthError(e);
      },
      codeSent: (String verificationId, int? resendToken) {
        print('📤 SMS sent to mobile device');
        _isLoading.value = false;
        _isCodeSent.value = true;
        _verificationId.value = verificationId;
        _resendToken.value = resendToken ?? 0;

        Get.snackbar(
          'OTP Sent 📱',
          'Verification code has been sent to $phoneNumber',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Get.theme.colorScheme.primary,
          colorText: Get.theme.colorScheme.onPrimary,
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print('⏰ Code auto-retrieval timeout');
        _verificationId.value = verificationId;
      },
      timeout: const Duration(seconds: 60),
    );
  }

  /// Verifies the OTP entered by user
  /// Handles both web (ConfirmationResult) and mobile (PhoneAuthCredential) platforms
  Future<void> verifyOtp(String otpCode) async {
    try {
      _isLoading.value = true;

      // 🚀 DEVELOPMENT BYPASS: Accept 123456 for test phone number
      if (_phoneNumber.value == '+91 99999 99999' && otpCode == '123456') {
        await _simulateSuccessfulAuth();
        return;
      }

      if (kIsWeb && _webConfirmationResult != null) {
        // WEB PLATFORM - Use ConfirmationResult from reCAPTCHA flow
        print('🌐 Verifying OTP on web platform');
        final UserCredential result = await _webConfirmationResult!.confirm(
          otpCode,
        );
        _handleSuccessfulAuth(result);
      } else {
        // MOBILE PLATFORM - Use traditional PhoneAuthCredential
        print('📱 Verifying OTP on mobile platform');
        final credential = PhoneAuthProvider.credential(
          verificationId: _verificationId.value,
          smsCode: otpCode,
        );
        await _signInWithCredential(credential);
      }
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      _handleAuthError(e);
    } catch (e) {
      _isLoading.value = false;
      Get.snackbar(
        'Invalid OTP',
        'Please check the code and try again',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Signs in with the phone credential (mobile platform)
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      _handleSuccessfulAuth(userCredential);
    } on FirebaseAuthException catch (e) {
      _isLoading.value = false;
      _handleAuthError(e);
    }
  }

  /// Handles successful authentication for both platforms
  void _handleSuccessfulAuth(UserCredential userCredential) {
    _isLoading.value = false;

    if (userCredential.user != null) {
      final platform = kIsWeb ? '🌐 Web' : '📱 Mobile';

      Get.snackbar(
        'Welcome! $platform',
        'Successfully logged in via ${kIsWeb ? 'reCAPTCHA + SMS' : 'SMS'}',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );

      // Reset all authentication state
      _resetAuthState();
    }
  }

  /// Resets authentication state after successful login
  void _resetAuthState() {
    _isCodeSent.value = false;
    _verificationId.value = '';
    _webConfirmationResult = null;
  }

  /// Resends OTP to the same phone number
  Future<void> resendOtp() async {
    if (_phoneNumber.value.isNotEmpty) {
      await sendOtp(_phoneNumber.value);
    }
  }

  /// Signs out the current user
  Future<void> logout() async {
    try {
      await _auth.signOut();

      // Reset all authentication state
      _resetAuthState();
      _phoneNumber.value = '';

      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.primary,
        colorText: Get.theme.colorScheme.onPrimary,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to logout: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Get.theme.colorScheme.error,
        colorText: Get.theme.colorScheme.onError,
      );
    }
  }

  /// Handles Firebase authentication errors with user-friendly messages
  void _handleAuthError(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'invalid-phone-number':
        message = 'Please enter a valid phone number';
        break;
      case 'too-many-requests':
        message = 'Too many attempts. Please try again later';
        break;
      case 'invalid-verification-code':
        message = 'Invalid verification code. Please try again';
        break;
      case 'session-expired':
        message = 'Session expired. Please request a new code';
        break;
      case 'quota-exceeded':
        message = 'SMS quota exceeded. Please try again later';
        break;
      case 'captcha-check-failed':
        message = 'reCAPTCHA verification failed. Please try again';
        break;
      case 'invalid-app-credential':
        message = 'Invalid app credentials. Please contact support';
        break;
      case 'invalid-verification-id':
        message = 'Verification session expired. Please restart';
        break;
      case 'missing-verification-code':
        message = 'Please enter the verification code';
        break;
      default:
        message = kIsWeb
            ? 'Web authentication failed: ${e.message}'
            : 'Mobile authentication failed: ${e.message}';
    }

    Get.snackbar(
      'Authentication Error',
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.error,
      colorText: Get.theme.colorScheme.onError,
      duration: const Duration(seconds: 4),
    );
  }

  /// Validates phone number format
  bool isValidPhoneNumber(String phone) {
    // Remove all non-digit characters
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');

    // Should start with + and have at least 10 digits
    return cleaned.startsWith('+') && cleaned.length >= 11;
  }

  /// Formats phone number for display
  String formatPhoneNumber(String phone) {
    if (phone.length <= 4) return phone;
    return '${phone.substring(0, phone.length - 4)}****';
  }

  /// Reset authentication state (useful for testing)
  void resetState() {
    _isCodeSent.value = false;
    _verificationId.value = '';
    _phoneNumber.value = '';
    _isLoading.value = false;
    _webConfirmationResult = null;
  }

  /// 🚀 DEVELOPMENT ONLY: Simulate OTP sending for blocked devices
  Future<void> _simulateOtpForDevelopment() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoading.value = false;
    _isCodeSent.value = true;

    Get.snackbar(
      '🚀 DEV MODE: OTP Sent',
      'Test OTP: 123456 (Development bypass active)',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 4),
    );
  }

  /// 🚀 DEVELOPMENT ONLY: Simulate successful authentication
  Future<void> _simulateSuccessfulAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    _isLoading.value = false;

    // Create a fake user for development
    _user.value = _auth.currentUser ?? await _createFakeUser();

    Get.snackbar(
      '🚀 DEV MODE: Login Success',
      'Development bypass authentication completed',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Get.theme.colorScheme.primary,
      colorText: Get.theme.colorScheme.onPrimary,
      duration: const Duration(seconds: 3),
    );

    _resetAuthState();
  }

  /// 🚀 DEVELOPMENT ONLY: Create fake user for testing
  Future<User?> _createFakeUser() async {
    try {
      // Sign in anonymously for development testing
      final result = await _auth.signInAnonymously();
      return result.user;
    } catch (e) {
      print('Development auth fallback failed: $e');
      return null;
    }
  }
}
