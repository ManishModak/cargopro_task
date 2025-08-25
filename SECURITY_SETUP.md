# Firebase Security Configuration Setup

## Overview
This project uses environment variables to securely manage Firebase API keys and configuration. This prevents sensitive data from being committed to version control.

## Setup Instructions

### 1. Create Environment File
Create a `.env` file in the project root with your Firebase configuration:

```bash
# Firebase Configuration
# Get these values from your Firebase Console

# Web Configuration
FIREBASE_WEB_API_KEY=your_new_web_api_key_here
FIREBASE_WEB_APP_ID=1:924292811472:web:18cccd20375c3c83592cd5

# Android Configuration  
FIREBASE_ANDROID_API_KEY=your_new_android_api_key_here
FIREBASE_ANDROID_APP_ID=1:924292811472:android:c8251e8ab1b7095a592cd5

# iOS Configuration
FIREBASE_IOS_API_KEY=your_new_ios_api_key_here
FIREBASE_IOS_APP_ID=1:924292811472:ios:9c8450f3e5eef44d592cd5

# Shared Configuration
FIREBASE_MESSAGING_SENDER_ID=924292811472
FIREBASE_PROJECT_ID=cargopro-task-69df5
FIREBASE_AUTH_DOMAIN=cargopro-task-69df5.firebaseapp.com
FIREBASE_STORAGE_BUCKET=cargopro-task-69df5.firebasestorage.app
FIREBASE_MEASUREMENT_ID=G-4STCL20ZMD
FIREBASE_IOS_BUNDLE_ID=com.example.cargoproTask
```

### 2. Get Your New Firebase API Keys

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `cargopro-task-69df5`
3. Go to Project Settings → General
4. For each platform, copy the new API keys:
   - **Web**: Copy the `apiKey` from your web app config
   - **Android**: Copy the `api_key` from your Android app config  
   - **iOS**: Copy the `API_KEY` from your iOS app config

### 3. Building the App

Use the provided build scripts that automatically load environment variables:

**Windows (PowerShell):**
```powershell
# Build for web
.\build_with_env.ps1 web

# Build for Android
.\build_with_env.ps1 android

# Build for iOS
.\build_with_env.ps1 ios
```

**Linux/macOS (Bash):**
```bash
# Make script executable
chmod +x build_with_env.sh

# Build for web
./build_with_env.sh web

# Build for Android
./build_with_env.sh android

# Build for iOS
./build_with_env.sh ios
```

### 4. Manual Build (Alternative)

If you prefer to build manually, use `--dart-define` flags:

```bash
flutter build web \
  --dart-define=FIREBASE_WEB_API_KEY="your_web_api_key" \
  --dart-define=FIREBASE_PROJECT_ID="cargopro-task-69df5" \
  # ... other defines
```

## Security Notes

- ✅ The `.env` file is in `.gitignore` and will not be committed
- ✅ Default values in `firebase_options.dart` are empty strings for API keys
- ✅ Non-sensitive configuration (project IDs, domains) have safe defaults
- ⚠️ Never commit actual API keys to version control
- ⚠️ Regenerate API keys if they were ever exposed publicly

## Deployment

For deployment platforms, set environment variables in your deployment configuration:

- **Firebase Hosting**: Use `firebase functions:config:set`
- **GitHub Actions**: Use repository secrets
- **Other CI/CD**: Set environment variables in your pipeline

## Troubleshooting

If you see authentication errors:
1. Verify your `.env` file has the correct API keys
2. Ensure the API keys are regenerated if they were compromised
3. Check that the build script is properly loading environment variables
