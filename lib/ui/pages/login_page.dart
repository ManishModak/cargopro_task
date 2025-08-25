import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';

/// LoginPage (View) handles the UI for phone authentication
/// This is the View layer in MVVM that only handles UI and delegates
/// all business logic to the AuthController (ViewModel)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Get.theme.colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: EdgeInsets.all(kIsWeb ? 32.0 : 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1,
                            ),
                            _buildHeader(),
                            const SizedBox(height: 48),
                            Obx(
                              () => _authController.isCodeSent
                                  ? _buildOtpSection()
                                  : _buildPhoneSection(),
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height * 0.1,
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header section with app branding
  Widget _buildHeader() {
    return Column(
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
        const SizedBox(height: 24),
        Text(
          'Welcome to CargoPro',
          style: Get.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Get.theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Please verify your phone number to continue',
          style: Get.textTheme.bodyLarge?.copyWith(
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Phone number input section
  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Phone Number',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Get.theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+1 234 567 8900',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Get.theme.colorScheme.surface,
          ),
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter your phone number';
            }
            if (!_authController.isValidPhoneNumber(value!)) {
              return 'Please enter a valid phone number with country code';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 24),

        _buildSendOtpButton(),
      ],
    );
  }

  /// OTP verification section
  Widget _buildOtpSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Verification Code',
          style: Get.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Get.theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code sent to ${_authController.formatPhoneNumber(_phoneController.text)}',
          style: Get.textTheme.bodyMedium?.copyWith(
            color: Get.theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),

        const SizedBox(height: 16),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: InputDecoration(
            hintText: '123456',
            prefixIcon: const Icon(Icons.sms),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Get.theme.colorScheme.surface,
            counterText: '', // Hide character counter
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter the verification code';
            }
            if (value!.length != 6) {
              return 'Please enter a 6-digit code';
            }
            return null;
          },
          onChanged: (value) => setState(() {}),
        ),
        const SizedBox(height: 24),

        // Verify OTP Button
        Obx(
          () => ElevatedButton.icon(
            onPressed: _authController.isLoading ? null : () => _verifyOtp(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Get.theme.colorScheme.primary,
              foregroundColor: Get.theme.colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: _authController.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.verified_user, size: 18),
            label: Text(
              _authController.isLoading ? 'Verifying...' : 'Verify Code',
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Resend OTP Button
        TextButton.icon(
          onPressed: () => _authController.resendOtp(),
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('Resend Code'),
        ),

        const SizedBox(height: 16),

        // Back to Phone Number
        OutlinedButton.icon(
          onPressed: () => _authController.resetState(),
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Change Phone Number'),
        ),
      ],
    );
  }

  /// Unified Send OTP button for both web and mobile
  Widget _buildSendOtpButton() {
    return Obx(
      () => ElevatedButton.icon(
        onPressed: _authController.isLoading ? null : () => _sendOtp(),
        style: ElevatedButton.styleFrom(
          backgroundColor: Get.theme.colorScheme.primary,
          foregroundColor: Get.theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: _authController.isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.sms, size: 18),
        label: Text(_authController.isLoading ? 'Sending...' : 'Send OTP'),
      ),
    );
  }

  /// Footer with terms and conditions
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Text(
        'By continuing, you agree to our Terms of Service and Privacy Policy',
        style: Get.textTheme.bodySmall?.copyWith(
          color: Get.theme.colorScheme.onSurface.withOpacity(0.6),
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Sends OTP to the entered phone number
  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      _authController.sendOtp(_phoneController.text.trim());
    }
  }

  /// Verifies the entered OTP
  void _verifyOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      _authController.verifyOtp(_otpController.text.trim());
    }
  }
}
