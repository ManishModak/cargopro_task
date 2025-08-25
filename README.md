# CargoPro Task - Flutter Cross-Platform App

A Flutter application demonstrating Firebase OTP-based authentication and REST API integration with GetX state management.

## Features

- **Firebase Phone Authentication** (OTP-based login for mobile & web)
- **CRUD Operations** using REST API (https://api.restful-api.dev/objects)
- **Cross-Platform Support** (Mobile & Web)
- **GetX State Management** for navigation and reactive UI
- **Material Design 3** with responsive layouts

## Quick Start

1. Clone the repository
2. Install dependencies: `flutter pub get`
3. Set up Firebase (see Firebase Setup section)
4. Run the app: `flutter run`

## 🚀 Deployment & Submission

### Web Deployment to Firebase Hosting ✅

**Live URL:** https://cargopro-task-69df5.web.app

**Deployment Status:** Successfully deployed and live

**Features Available on Web:**
- Firebase Phone Authentication with reCAPTCHA
- Full CRUD operations (Create, Read, Update, Delete)
- Responsive Material Design 3 UI
- Cross-platform compatibility

### Mobile Installable Build ✅

**📱 Download APK:** [Download Android APK](https://drive.google.com/file/d/1iPklmKKxq28xxZZU11vss-6XSGoIy2dU/view?usp=sharing)

**APK Features:**
- Release build with optimized performance (48.0MB)
- Firebase Phone Authentication
- Full CRUD operations
- Native Android experience

**Installation Instructions:**
1. Download the APK from the Drive link above
2. Enable "Install from Unknown Sources" in Android settings
3. Install the APK file
4. Grant necessary permissions when prompted

### Project Walkthrough Video ✅

**📹 Video Walkthrough:** [5-10 Minute Demo Video](https://drive.google.com/file/d/1TIAAPyhe0acKXxP9yPmyVAcHhGlQq4eq/view?usp=sharing)

**Video Content Covers:**
- **Authentication Flow:** Phone OTP login for mobile & web platforms
- **Architecture Overview:** Project folders, controllers, services, and dependency injection
- **CRUD Operations:** List view, detail view, create, edit (PUT), and delete functionality
- **Advanced Features:** Error handling, optimistic updates, and pagination
- **Deployment Process:** Web build deployment and mobile app build process

**📱 Build Artifacts:**
- **Web Build**: Deployed to Firebase Hosting
- **Android APK**: Available via Drive link above
- **Source Code**: Complete Flutter cross-platform project

## Firebase Setup

### Prerequisites
- Flutter project
- Firebase CLI installed
- Firebase account

### Step-by-Step Setup

#### 1. Create Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

#### 2. Configure Firebase for Flutter
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase for all platforms
flutterfire configure
```

#### 3. Enable Phone Authentication

**In Firebase Console:**
1. Go to Authentication → Sign-in method
2. Enable **Phone** provider
3. Add your domain to authorized domains (for web)

**For Web Platform:**
- reCAPTCHA is automatically handled by Firebase
- No additional setup required

**For Mobile Platform:**
- Android: Add SHA-1 fingerprint to Firebase project
- iOS: Download updated `GoogleService-Info.plist`

#### 4. Configure Platform-Specific Settings

**Android (`android/app/build.gradle`):**
```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Required for Firebase Auth
        targetSdkVersion 34
    }
}
```

**iOS (`ios/Runner/Info.plist`):**
- Ensure URL schemes are configured (done by FlutterFire)

**Web (`web/index.html`):**
- Firebase SDK scripts added automatically by FlutterFire

### Testing Phone Auth

For development/testing, use the development bypass:
- Phone: `+91 99999 99999`
- OTP: `123456`

## Dependencies

### Core Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management & Navigation
  get: ^4.7.2
  
  # Firebase
  firebase_core: ^4.0.0
  firebase_auth: ^6.0.1
  
  # HTTP Client
  http: ^1.5.0
  
  # UI
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Testing (Core unit tests only)
  mockito: ^5.4.4
  build_runner: ^2.4.8
```

### Dependency Purposes

| Package | Purpose | Platform |
|---------|---------|----------|
| `get` | State management, navigation, dependency injection | All |
| `firebase_core` | Firebase SDK initialization | All |
| `firebase_auth` | Phone authentication, user management | All |
| `http` | REST API calls | All |
| `mockito` | Mock objects for core unit tests | Test only |

## Code Structure

```
lib/
├── bindings/
│   └── app_bindings.dart           # Dependency injection setup
├── controllers/
│   ├── auth_controller.dart        # Authentication logic
│   └── object_controller.dart      # CRUD operations logic
├── data/
│   ├── models/
│   │   └── object_model.dart       # Data model with JSON serialization
│   └── services/
│       └── api_service.dart        # HTTP API client
├── ui/
│   ├── pages/
│   │   ├── login_page.dart         # Phone authentication UI
│   │   ├── home_page.dart          # Main dashboard
│   │   ├── object_list_page.dart   # List view with CRUD operations
│   │   ├── object_detail_page.dart # Detail view with edit/delete
│   │   ├── add_object_page.dart    # Create new object
│   │   └── edit_object_page.dart   # Edit existing object
│   └── root.dart                   # Root navigation controller
├── firebase_options.dart           # Generated Firebase configuration
├── main.dart                       # App entry point
└── test/
    ├── core_test.dart              # Unit tests for API + Controller
    └── core_test.mocks.dart        # Generated mocks
```

## Design Choices

### Architecture: MVVM with GetX

**Controllers (ViewModels)**
- `AuthController`: Manages authentication state and Firebase operations
- `ObjectController`: Handles CRUD operations and API state

**Views**
- Stateless widgets that observe controller state
- UI updates automatically via `Obx()` reactive widgets

**Models**
- `ObjectModel`: Data class with JSON serialization
- `ApiException`: Custom exception for API errors

### State Management Strategy

**Reactive Programming with GetX:**
```dart
// Controller
final RxBool _isLoading = false.obs;
bool get isLoading => _isLoading.value;

// View
Obx(() => _controller.isLoading 
  ? CircularProgressIndicator() 
  : ActionButton())
```

**Benefits:**
- Automatic UI updates
- Memory leak prevention
- Simple dependency injection
- Unified navigation management

### Cross-Platform Authentication

**Platform Detection:**
```dart
if (kIsWeb) {
  // Web: Use reCAPTCHA + ConfirmationResult
  _webConfirmationResult = await _auth.signInWithPhoneNumber(phoneNumber);
} else {
  // Mobile: Use native SMS verification
  await _auth.verifyPhoneNumber(/* callbacks */);
}
```

**Why Different Approaches:**
- Web browsers require reCAPTCHA for security
- Mobile platforms have native SMS integration
- Single codebase handles both seamlessly

### Error Handling Strategy

**Layered Error Handling:**
1. **API Level**: Custom `ApiException` with status codes
2. **Controller Level**: User-friendly error messages
3. **UI Level**: Snackbars and error states

**Example:**
```dart
try {
  await apiService.createObject(object);
} on ApiException catch (e) {
  Get.snackbar('Error', e.userMessage);
}
```

## Limitations

### Current Limitations

1. **Phone Authentication**
   - Requires active phone number for testing
   - SMS costs apply in production
   - Some regions may have restrictions

2. **API Dependencies**
   - Relies on external REST API availability (https://restful-api.dev/)
   - API behavior: GET /objects returns only reserved objects (IDs 1-13)
   - User-created objects have dynamic IDs and must be stored locally
   - Only user-created objects can be updated/deleted (reserved objects are read-only)
   - Limited by API rate limits

3. **Testing**
   - Phone auth testing requires Firebase project setup
   - E2E tests not implemented

4. **Platform Support**
   - Web requires modern browser with reCAPTCHA support
   - iOS requires proper certificates for production
   - No desktop platform support

## Future Improvements

### Short Term
- [ ] Offline data caching with local storage
- [ ] Push notifications for real-time updates
- [ ] Advanced search and filtering
- [ ] Export/import functionality

### Medium Term
- [ ] Multi-language support (i18n)
- [ ] Dark/light theme switching
- [ ] Advanced authentication (email, social)
- [ ] Role-based access control

### Long Term
- [ ] Desktop platform support (Windows, macOS, Linux)
- [ ] Real-time collaboration features
- [ ] Advanced analytics and reporting
- [ ] Offline-first architecture with sync

### Technical Improvements
- [ ] Integration test automation
- [ ] Performance optimization for large datasets
- [ ] Advanced error logging and monitoring
- [ ] CI/CD pipeline with automated testing

## Quick Development Commands

```bash
# Install dependencies
flutter pub get

# Generate mocks for core tests
dart run build_runner build

# Run tests
flutter test

# Run on different platforms
flutter run -d chrome      # Web
flutter run -d android     # Android
flutter run -d ios         # iOS

# Build for production
flutter build web
flutter build apk
```

## Testing

```bash
# Run core unit tests (API + Controller with mocks)
flutter test test/core_test.dart
```

**Environment Requirements:** Flutter SDK ≥ 3.32.5, Dart SDK ≥ 3.8.1, Firebase CLI