# Deployment & Build Guide

Complete guide for building and deploying the Flutter Expense Tracker on Android and iOS platforms.

## Pre-requisites Checklist

Before you begin, ensure you have:

- [ ] Flutter SDK 3.0.0 or higher installed
- [ ] Dart SDK 3.0.0 or higher (included with Flutter)
- [ ] Git installed and configured
- [ ] For Android: Android Studio with SDK Platform 21+ and Build Tools 33+
- [ ] For iOS: Xcode 12.0+ on a Mac machine
- [ ] Sufficient disk space (min 5GB for build artifacts)

## Android Deployment

### Step 1: Verify Android SDK Setup

```bash
# Check Flutter and Android setup
flutter doctor -v

# Expected output should show:
# ✓ Flutter
# ✓ Android toolchain
# ✓ Android Studio
```

### Step 2: Configure Build Properties

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 33
    
    defaultConfig {
        applicationId "com.example.expense_tracker"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            // Configure with your keystore (for distribution)
            storeFile file(System.getenv("KEYSTORE_PATH") ?: "debug.keystore")
            storePassword System.getenv("KEYSTORE_PASSWORD")
            keyAlias System.getenv("KEY_ALIAS")
            keyPassword System.getenv("KEY_PASSWORD")
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

### Step 3: Build Debug APK (for testing)

```bash
# Build debug APK
flutter build apk --debug

# Output location:
# build/app/outputs/apk/debug/app-debug.apk

# Install on connected device/emulator
adb install -r build/app/outputs/apk/debug/app-debug.apk

# Launch app
adb shell am start -n com.example.expense_tracker/.MainActivity
```

### Step 4: Build Release APK (for distribution)

```bash
# Create a keystore if you don't have one
keytool -genkey -v -keystore ~/expense_tracker.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias expense_tracker_key

# Set environment variables
export KEYSTORE_PATH=~/expense_tracker.jks
export KEYSTORE_PASSWORD=<your-password>
export KEY_ALIAS=expense_tracker_key
export KEY_PASSWORD=<your-password>

# Build release APK
flutter build apk --release

# Output: build/app/outputs/apk/release/app-release.apk
# File size: ~50-80MB (includes Flutter runtime)
```

### Step 5: Build App Bundle for Play Store

```bash
# Build signed AAB (Android App Bundle)
flutter build appbundle --release

# Output: build/app/outputs/bundle/release/app-release.aab
# File size: ~40-60MB (Play Store optimizes downloads per device)

# Verify bundle
bundletool validate --bundle=build/app/outputs/bundle/release/app-release.aab

# Generate APKs for testing
bundletool build-apks \
  --bundle=build/app/outputs/bundle/release/app-release.aab \
  --output=app.apks \
  --ks=~/expense_tracker.jks \
  --ks-pass=pass:<password> \
  --ks-key-alias=expense_tracker_key \
  --key-pass=pass:<password>

# Install on test device
bundletool install-apks \
  --apks=app.apks \
  --adb=<path-to-adb>
```

### Step 6: Upload to Google Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Create new app or select existing
3. Navigate to "Release > Production"
4. Click "Create new release"
5. Upload `app-release.aab`
6. Fill in release notes
7. Review content rating
8. Click "Review release"
9. Click "Start rollout to Production"

### Troubleshooting Android Builds

**Issue: `INSTALLATION_FAILED_INSUFFICIENT_STORAGE`**
```bash
# Clear Android build cache
rm -rf android/.gradle
flutter clean
flutter pub get
flutter build apk --release
```

**Issue: `Gradle build failed`**
```bash
# Update Gradle wrapper
cd android
./gradlew wrapper --gradle-version 7.6
cd ..
flutter clean
flutter build apk --release
```

**Issue: `Manifest merge failed`**
- Check `android/app/src/main/AndroidManifest.xml` for conflicting permissions
- Ensure no duplicate `<uses-permission>` tags

## iOS Deployment

### Step 1: Verify iOS Setup

```bash
# Check iOS development environment
flutter doctor -v

# Install iOS dependencies
cd ios
pod install --repo-update
cd ..
```

### Step 2: Configure iOS Build Properties

Edit `ios/Runner.xcodeproj` settings or use Xcode:

1. Open `ios/Runner.xcworkspace` (not .xcodeproj)
2. Select "Runner" project
3. Under "Build Settings":
   - iOS Deployment Target: 11.0
   - Bundle Identifier: `com.example.expense_tracker`
   - Team ID: Your Apple Developer Team ID

### Step 3: Build Debug for Simulator

```bash
# List available simulators
xcrun simctl list devices available

# Start a simulator
xcrun simctl boot "iPhone 14"
open /Applications/Simulator.app

# Build and run on simulator
flutter run -d "iPhone 14"

# Or manually build
flutter build ios --debug --simulator
```

### Step 4: Build Release for Device

```bash
# Connect iPhone to Mac
# Trust the device when prompted

# Build for physical device
flutter build ios --release

# Output: build/ios/iphoneos/Runner.app
# This is an unsigned build suitable for beta testing
```

### Step 5: Archive and Distribute via App Store

```bash
# Build release (creates archive-ready bundle)
flutter build ios --release

# Open in Xcode for archiving
open ios/Runner.xcworkspace

# In Xcode:
# 1. Select "Runner" project
# 2. Change scheme to "Release"
# 3. Select "Generic iOS Device"
# 4. Product > Archive
# 5. Organizer window opens
# 6. Click "Distribute App"
# 7. Choose "App Store Connect"
# 8. Follow wizard to upload

# Alternative: Use command line
cd ios
xcodebuild -workspace Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -derivedDataPath build \
  -archivePath build/Runner.xcarchive \
  archive

# Then create IPA
xcodebuild \
  -exportArchive \
  -archivePath build/Runner.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath build
```

### Step 6: Upload to App Store

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Select your app
3. Go to "App Store > Prepare for Submission"
4. Click "+" to create new build
5. Upload IPA via Xcode Organizer
6. Fill in app information (screenshots, description, etc.)
7. Add release notes
8. Select content rating
9. Click "Submit for Review"

### iOS Build Troubleshooting

**Issue: `Pod install` fails**
```bash
cd ios
rm Podfile.lock
pod install --repo-update
cd ..
```

**Issue: `Build output` shows warnings**
```bash
# Update pods
cd ios
pod update
cd ..

# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*
flutter clean
flutter build ios --release
```

**Issue: Signing error**
```bash
# Verify team ID is set in Xcode
# Product > Scheme > Edit Scheme > Build tab
# Check signing certificate is valid:
security find-identity -v -p codesigning
```

## Testing Before Release

### Test Checklist

- [ ] App launches without crashes
- [ ] Database initializes successfully
- [ ] Add expense form works end-to-end
- [ ] Validation errors display correctly
- [ ] Photo picker works (camera and gallery)
- [ ] Charts render with sample data
- [ ] Statistics calculate correctly
- [ ] Delete operation confirms before removing
- [ ] Navigation between screens works
- [ ] App survives with 1000+ expenses
- [ ] Date validation rejects invalid dates
- [ ] Amount validation rejects invalid amounts
- [ ] Empty state displays when no expenses

### Performance Testing

```bash
# Run performance profiler
flutter run --profile

# Monitor memory usage
dart devtools

# Build size analysis
flutter build apk --release -- --analyze-size
flutter build ios --release -- --analyze-size
```

### Manual Testing Scenarios

1. **Create Expense**
   - Open app > Tap FAB > Fill form > Save
   - Verify expense appears in list
   - Verify statistics update

2. **Edit Expense**
   - Tap existing expense > Edit > Change fields > Save
   - Verify changes appear immediately

3. **Delete Expense**
   - Tap existing expense > Tap delete > Confirm
   - Verify expense removed from list

4. **Date Validation**
   - Try date before 2024-01-01: Should show error
   - Try future date: Should show error
   - Select valid date: Should allow save

5. **Amount Validation**
   - Try amount = 0: Should show error
   - Try negative amount: Should show error
   - Try amount > 1,000,000: Should show error
   - Try valid amount: Should allow save

6. **Photo Upload**
   - Add expense > Tap photo button > Select camera > Take photo
   - Verify photo preview displays
   - Verify photo is saved with expense
   - Edit expense > Change/remove photo
   - Verify changes persist

7. **Statistics**
   - Create 10 expenses with different dates and categories
   - Verify weekly average calculates
   - Verify monthly bar chart shows all months
   - Verify category pie chart shows all categories
   - Verify top 5 list sorts by amount

8. **Offline Functionality**
   - Disable network (airplane mode)
   - App should work without network
   - Verify database still accessible
   - Re-enable network: App still works

## Build Outputs Summary

### Android Artifacts
- **Debug APK**: `build/app/outputs/apk/debug/app-debug.apk` (~80MB)
- **Release APK**: `build/app/outputs/apk/release/app-release.apk` (~50MB)
- **App Bundle**: `build/app/outputs/bundle/release/app-release.aab` (~40MB)

### iOS Artifacts
- **Simulator Build**: `build/ios/iphonesimulator/Runner.app/` (~150MB)
- **Device Build**: `build/ios/iphoneos/Runner.app/` (~120MB)
- **Archive**: `build/Runner.xcarchive/` (~250MB+)

## Version Management

### Incrementing Versions

**For Android** - Edit `android/app/build.gradle`:
```gradle
defaultConfig {
    versionCode 2      // Increment for each release
    versionName "1.0.1" // Increment patch for bug fixes, minor for features
}
```

**For iOS** - Edit `ios/Runner.xcodeproj`:
1. Select Runner project
2. Select Runner target
3. Go to "Build Settings"
4. Update "Marketing Version" (corresponds to versionName)
5. Update "Build Number" (corresponds to versionCode)

### Version Scheme (Semantic Versioning)
- **Major.Minor.Patch** (e.g., 1.0.0, 1.1.0, 1.0.1)
- **Major**: Breaking changes
- **Minor**: New features (backward compatible)
- **Patch**: Bug fixes

## Continuous Integration (Optional)

### GitHub Actions Example

Create `.github/workflows/build.yml`:

```yaml
name: Build and Test

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.10.0'
    
    - run: flutter pub get
    - run: flutter test
    - run: flutter build apk --release
    - run: flutter build appbundle --release
    
    - uses: actions/upload-artifact@v3
      with:
        name: android-apk
        path: build/app/outputs/apk/release/
```

## Post-Release Checklist

- [ ] Monitor crash reports in Play Console / App Store Connect
- [ ] Respond to user reviews and feedback
- [ ] Track download/install metrics
- [ ] Monitor app performance metrics
- [ ] Plan next release based on user feedback
- [ ] Archive build artifacts
- [ ] Update version numbers for next development cycle

## Rollback Procedures

### If Critical Bug Found After Release

**Android Play Store:**
1. Go to Play Console
2. Navigate to Release > Production
3. Click "Stop rollout" (if still rolling out)
4. Upload fixed AAB as new release
5. Click "Review release" > "Start rollout"

**iOS App Store:**
1. Go to App Store Connect
2. Select app > TestFlight (if available)
3. Upload fixed build
4. After testing, submit for review
5. Once approved, submit to App Store
6. Request removal of buggy version if needed

## Support & Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Android Studio Documentation](https://developer.android.com/studio)
- [Xcode Documentation](https://developer.apple.com/xcode/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)

---

**Last Updated**: 2024-06-06
**Status**: Production Ready
