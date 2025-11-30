@echo off
echo ==========================================
echo 🚀 PREPARING DEPLOYMENT
echo ==========================================

:: 1. Auto-increment the build number (e.g., +5 -> +6)
echo 🔢 Incrementing Build Number...
call cider bump build
if %errorlevel% neq 0 (
    echo ⚠️ Cider not found. Install it with: flutter pub global activate cider
    pause
    exit /b
)

echo.
echo 🔨 Building Release APK...
call flutter build apk --release

if %errorlevel% neq 0 (
    echo.
    echo ❌ BUILD FAILED!
    pause
    exit /b %errorlevel%
)

echo.
echo 📤 Uploading to Firebase...
call firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk ^
  --app "1:167700736671:android:f1b0eac50a29ba442390aa" ^
  --groups "alpha-testers" ^
  --release-notes-file "release_notes.txt"

echo.
echo 🎉 DEPLOYMENT COMPLETE! New version is live.
pause