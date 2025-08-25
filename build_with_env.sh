#!/bin/bash

# Build script with environment variables for Flutter Firebase app
# Usage: ./build_with_env.sh [web|android|ios]

# Load environment variables from .env file if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Set default platform to web if not specified
PLATFORM=${1:-web}

echo "Building for platform: $PLATFORM"
echo "Using Firebase Project ID: $FIREBASE_PROJECT_ID"

case $PLATFORM in
    web)
        flutter build web \
            --dart-define=FIREBASE_WEB_API_KEY="$FIREBASE_WEB_API_KEY" \
            --dart-define=FIREBASE_WEB_APP_ID="$FIREBASE_WEB_APP_ID" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_AUTH_DOMAIN="$FIREBASE_AUTH_DOMAIN" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
            --dart-define=FIREBASE_MEASUREMENT_ID="$FIREBASE_MEASUREMENT_ID"
        ;;
    android)
        flutter build apk \
            --dart-define=FIREBASE_ANDROID_API_KEY="$FIREBASE_ANDROID_API_KEY" \
            --dart-define=FIREBASE_ANDROID_APP_ID="$FIREBASE_ANDROID_APP_ID" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET"
        ;;
    ios)
        flutter build ios \
            --dart-define=FIREBASE_IOS_API_KEY="$FIREBASE_IOS_API_KEY" \
            --dart-define=FIREBASE_IOS_APP_ID="$FIREBASE_IOS_APP_ID" \
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$FIREBASE_MESSAGING_SENDER_ID" \
            --dart-define=FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID" \
            --dart-define=FIREBASE_STORAGE_BUCKET="$FIREBASE_STORAGE_BUCKET" \
            --dart-define=FIREBASE_IOS_BUNDLE_ID="$FIREBASE_IOS_BUNDLE_ID"
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        echo "Available platforms: web, android, ios"
        exit 1
        ;;
esac

echo "Build completed for $PLATFORM"
