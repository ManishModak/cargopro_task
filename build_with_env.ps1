# PowerShell build script with environment variables for Flutter Firebase app
# Usage: .\build_with_env.ps1 [web|android|ios]

param(
    [string]$Platform = "web"
)

# Load environment variables from .env file if it exists
if (Test-Path ".env") {
    Get-Content ".env" | Where-Object { $_ -match "^\w+=" } | ForEach-Object {
        $parts = $_ -split "=", 2
        [System.Environment]::SetEnvironmentVariable($parts[0], $parts[1], "Process")
    }
}

Write-Host "Building for platform: $Platform"
Write-Host "Using Firebase Project ID: $env:FIREBASE_PROJECT_ID"

switch ($Platform) {
    "web" {
        flutter build web `
            --dart-define=FIREBASE_WEB_API_KEY="$env:FIREBASE_WEB_API_KEY" `
            --dart-define=FIREBASE_WEB_APP_ID="$env:FIREBASE_WEB_APP_ID" `
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$env:FIREBASE_MESSAGING_SENDER_ID" `
            --dart-define=FIREBASE_PROJECT_ID="$env:FIREBASE_PROJECT_ID" `
            --dart-define=FIREBASE_AUTH_DOMAIN="$env:FIREBASE_AUTH_DOMAIN" `
            --dart-define=FIREBASE_STORAGE_BUCKET="$env:FIREBASE_STORAGE_BUCKET" `
            --dart-define=FIREBASE_MEASUREMENT_ID="$env:FIREBASE_MEASUREMENT_ID"
    }
    "android" {
        flutter build apk `
            --dart-define=FIREBASE_ANDROID_API_KEY="$env:FIREBASE_ANDROID_API_KEY" `
            --dart-define=FIREBASE_ANDROID_APP_ID="$env:FIREBASE_ANDROID_APP_ID" `
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$env:FIREBASE_MESSAGING_SENDER_ID" `
            --dart-define=FIREBASE_PROJECT_ID="$env:FIREBASE_PROJECT_ID" `
            --dart-define=FIREBASE_STORAGE_BUCKET="$env:FIREBASE_STORAGE_BUCKET"
    }
    "ios" {
        flutter build ios `
            --dart-define=FIREBASE_IOS_API_KEY="$env:FIREBASE_IOS_API_KEY" `
            --dart-define=FIREBASE_IOS_APP_ID="$env:FIREBASE_IOS_APP_ID" `
            --dart-define=FIREBASE_MESSAGING_SENDER_ID="$env:FIREBASE_MESSAGING_SENDER_ID" `
            --dart-define=FIREBASE_PROJECT_ID="$env:FIREBASE_PROJECT_ID" `
            --dart-define=FIREBASE_STORAGE_BUCKET="$env:FIREBASE_STORAGE_BUCKET" `
            --dart-define=FIREBASE_IOS_BUNDLE_ID="$env:FIREBASE_IOS_BUNDLE_ID"
    }
    default {
        Write-Host "Unknown platform: $Platform"
        Write-Host "Available platforms: web, android, ios"
        exit 1
    }
}

Write-Host "Build completed for $Platform"
