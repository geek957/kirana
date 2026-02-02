#!/usr/bin/env dart

/// Pre-Deployment Validation Script
///
/// This script validates that all required Firebase configurations,
/// data structures, and dependencies are in place before deployment.
///
/// Usage: dart scripts/pre_deployment_validation.dart

import 'dart:io';
import 'dart:convert';

void main() async {
  print('═══════════════════════════════════════════════════════════');
  print('   Grocery App - Pre-Deployment Validation Script');
  print('   Version: 2.0 (Enhanced Features)');
  print('═══════════════════════════════════════════════════════════\n');

  final validator = PreDeploymentValidator();
  await validator.runAllValidations();
}

class PreDeploymentValidator {
  int passedChecks = 0;
  int failedChecks = 0;
  int warningChecks = 0;
  List<String> errors = [];
  List<String> warnings = [];

  Future<void> runAllValidations() async {
    print('Starting validation checks...\n');

    // 1. Project Structure Validation
    await _validateProjectStructure();

    // 2. Dependencies Validation
    await _validateDependencies();

    // 3. Android Configuration Validation
    await _validateAndroidConfig();

    // 4. iOS Configuration Validation
    await _validateIOSConfig();

    // 5. Firebase Configuration Files
    await _validateFirebaseConfigFiles();

    // 6. Asset Validation
    await _validateAssets();

    // 7. Model Files Validation
    await _validateModelFiles();

    // 8. Service Files Validation
    await _validateServiceFiles();

    // 9. Provider Files Validation
    await _validateProviderFiles();

    // 10. Screen Files Validation
    await _validateScreenFiles();

    // Print Summary
    _printSummary();
  }

  Future<void> _validateProjectStructure() async {
    _printSection('1. Project Structure Validation');

    final requiredDirs = [
      'lib/models',
      'lib/services',
      'lib/providers',
      'lib/screens/admin',
      'lib/screens/customer',
      'assets/sounds',
      'docs',
      'scripts',
    ];

    for (final dir in requiredDirs) {
      _checkDirectory(dir);
    }
  }

  Future<void> _validateDependencies() async {
    _printSection('2. Dependencies Validation');

    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      _fail('pubspec.yaml not found');
      return;
    }

    final content = await pubspecFile.readAsString();

    final requiredDeps = {
      'image_picker': 'Camera access for delivery photos',
      'geolocator': 'GPS location capture',
      'firebase_messaging': 'Push notifications',
      'flutter_local_notifications': 'Local notification display',
      'audioplayers': 'Notification sound playback',
      'flutter_image_compress': 'Image compression',
      'firebase_storage': 'Delivery photo storage',
      'cloud_firestore': 'Database',
      'firebase_auth': 'Authentication',
    };

    for (final entry in requiredDeps.entries) {
      if (content.contains(entry.key)) {
        _pass('✓ ${entry.key} - ${entry.value}');
      } else {
        _fail('✗ ${entry.key} missing - ${entry.value}');
      }
    }
  }

  Future<void> _validateAndroidConfig() async {
    _printSection('3. Android Configuration Validation');

    // Check AndroidManifest.xml
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    if (!manifestFile.existsSync()) {
      _fail('AndroidManifest.xml not found');
      return;
    }

    final manifestContent = await manifestFile.readAsString();

    final requiredPermissions = [
      'android.permission.CAMERA',
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.ACCESS_COARSE_LOCATION',
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.INTERNET',
    ];

    for (final permission in requiredPermissions) {
      if (manifestContent.contains(permission)) {
        _pass('✓ Permission: $permission');
      } else {
        _fail('✗ Missing permission: $permission');
      }
    }

    // Check FCM metadata
    if (manifestContent.contains(
      'com.google.firebase.messaging.default_notification_channel_id',
    )) {
      _pass('✓ FCM notification channel configured');
    } else {
      _warn('⚠ FCM notification channel not configured');
    }

    // Check google-services.json
    final googleServicesFile = File('android/app/google-services.json');
    if (googleServicesFile.existsSync()) {
      _pass('✓ google-services.json present');
    } else {
      _fail('✗ google-services.json missing');
    }

    // Check build.gradle
    final buildGradleFile = File('android/app/build.gradle');
    if (buildGradleFile.existsSync()) {
      final buildGradleContent = await buildGradleFile.readAsString();
      if (buildGradleContent.contains('minSdkVersion')) {
        final minSdkMatch = RegExp(
          r'minSdkVersion\s+(\d+)',
        ).firstMatch(buildGradleContent);
        if (minSdkMatch != null) {
          final minSdk = int.parse(minSdkMatch.group(1)!);
          if (minSdk >= 21) {
            _pass('✓ minSdkVersion: $minSdk (>= 21)');
          } else {
            _fail('✗ minSdkVersion: $minSdk (should be >= 21)');
          }
        }
      }
    }
  }

  Future<void> _validateIOSConfig() async {
    _printSection('4. iOS Configuration Validation');

    // Check Info.plist
    final infoPlistFile = File('ios/Runner/Info.plist');
    if (!infoPlistFile.existsSync()) {
      _fail('Info.plist not found');
      return;
    }

    final infoPlistContent = await infoPlistFile.readAsString();

    final requiredKeys = {
      'NSCameraUsageDescription': 'Camera permission description',
      'NSLocationWhenInUseUsageDescription': 'Location permission description',
      'UIBackgroundModes': 'Background modes for notifications',
    };

    for (final entry in requiredKeys.entries) {
      if (infoPlistContent.contains(entry.key)) {
        _pass('✓ ${entry.key} - ${entry.value}');
      } else {
        _fail('✗ Missing ${entry.key} - ${entry.value}');
      }
    }

    // Check GoogleService-Info.plist
    final googleServiceFile = File('ios/Runner/GoogleService-Info.plist');
    if (googleServiceFile.existsSync()) {
      _pass('✓ GoogleService-Info.plist present');
    } else {
      _fail('✗ GoogleService-Info.plist missing');
    }
  }

  Future<void> _validateFirebaseConfigFiles() async {
    _printSection('5. Firebase Configuration Files');

    final firebaseFiles = [
      'android/app/google-services.json',
      'ios/Runner/GoogleService-Info.plist',
    ];

    for (final file in firebaseFiles) {
      _checkFile(file);
    }
  }

  Future<void> _validateAssets() async {
    _printSection('6. Asset Validation');

    // Check notification sound
    final soundFile = File('assets/sounds/notification.mp3');
    if (soundFile.existsSync()) {
      final size = await soundFile.length();
      _pass('✓ Notification sound present (${_formatBytes(size)})');

      if (size > 1024 * 1024) {
        // > 1MB
        _warn(
          '⚠ Notification sound is large (${_formatBytes(size)}). Consider optimizing.',
        );
      }
    } else {
      _fail('✗ Notification sound missing: assets/sounds/notification.mp3');
    }

    // Check pubspec.yaml for asset declaration
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      if (content.contains('assets/sounds/notification.mp3') ||
          content.contains('assets/sounds/')) {
        _pass('✓ Sound asset declared in pubspec.yaml');
      } else {
        _fail('✗ Sound asset not declared in pubspec.yaml');
      }
    }
  }

  Future<void> _validateModelFiles() async {
    _printSection('7. Model Files Validation');

    final requiredModels = {
      'lib/models/category.dart': 'Category model',
      'lib/models/app_config.dart': 'App configuration model',
      'lib/models/product.dart': 'Product model (should have new fields)',
      'lib/models/order.dart': 'Order model (should have new fields)',
    };

    for (final entry in requiredModels.entries) {
      _checkFile(entry.key, entry.value);
    }

    // Check if models are exported
    final modelsFile = File('lib/models/models.dart');
    if (modelsFile.existsSync()) {
      final content = await modelsFile.readAsString();
      if (content.contains('category.dart') &&
          content.contains('app_config.dart')) {
        _pass('✓ New models exported in models.dart');
      } else {
        _warn('⚠ New models may not be exported in models.dart');
      }
    }
  }

  Future<void> _validateServiceFiles() async {
    _printSection('8. Service Files Validation');

    final requiredServices = {
      'lib/services/category_service.dart': 'Category management service',
      'lib/services/config_service.dart': 'App configuration service',
      'lib/services/product_service.dart': 'Product service (extended)',
      'lib/services/order_service.dart': 'Order service (extended)',
      'lib/services/notification_service.dart':
          'Notification service (extended)',
    };

    for (final entry in requiredServices.entries) {
      _checkFile(entry.key, entry.value);
    }
  }

  Future<void> _validateProviderFiles() async {
    _printSection('9. Provider Files Validation');

    final requiredProviders = {
      'lib/providers/category_provider.dart': 'Category provider',
      'lib/providers/cart_provider.dart': 'Cart provider (extended)',
      'lib/providers/order_provider.dart': 'Order provider (extended)',
    };

    for (final entry in requiredProviders.entries) {
      _checkFile(entry.key, entry.value);
    }
  }

  Future<void> _validateScreenFiles() async {
    _printSection('10. Screen Files Validation');

    final requiredScreens = {
      'lib/screens/admin/category_management_screen.dart':
          'Category management',
      'lib/screens/admin/app_config_screen.dart': 'App configuration',
      'lib/screens/admin/product_form_screen.dart': 'Product form (extended)',
      'lib/screens/customer/home_screen.dart': 'Home screen (extended)',
      'lib/screens/customer/product_detail_screen.dart':
          'Product detail (extended)',
      'lib/screens/customer/cart_screen.dart': 'Cart screen (extended)',
    };

    for (final entry in requiredScreens.entries) {
      _checkFile(entry.key, entry.value);
    }
  }

  void _checkDirectory(String path) {
    final dir = Directory(path);
    if (dir.existsSync()) {
      _pass('✓ Directory: $path');
    } else {
      _fail('✗ Missing directory: $path');
    }
  }

  void _checkFile(String path, [String? description]) {
    final file = File(path);
    final desc = description != null ? ' - $description' : '';
    if (file.existsSync()) {
      _pass('✓ File: $path$desc');
    } else {
      _fail('✗ Missing file: $path$desc');
    }
  }

  void _pass(String message) {
    print('  $message');
    passedChecks++;
  }

  void _fail(String message) {
    print('  $message');
    failedChecks++;
    errors.add(message);
  }

  void _warn(String message) {
    print('  $message');
    warningChecks++;
    warnings.add(message);
  }

  void _printSection(String title) {
    print('\n$title');
    print('─' * 60);
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _printSummary() {
    print('\n═══════════════════════════════════════════════════════════');
    print('   VALIDATION SUMMARY');
    print('═══════════════════════════════════════════════════════════\n');

    print('  ✓ Passed:   $passedChecks');
    print('  ✗ Failed:   $failedChecks');
    print('  ⚠ Warnings: $warningChecks');
    print('  ─────────────────────');
    print('  Total:      ${passedChecks + failedChecks + warningChecks}\n');

    if (failedChecks > 0) {
      print('═══════════════════════════════════════════════════════════');
      print('   ERRORS (Must be fixed before deployment)');
      print('═══════════════════════════════════════════════════════════\n');
      for (final error in errors) {
        print('  $error');
      }
      print('');
    }

    if (warningChecks > 0) {
      print('═══════════════════════════════════════════════════════════');
      print('   WARNINGS (Should be reviewed)');
      print('═══════════════════════════════════════════════════════════\n');
      for (final warning in warnings) {
        print('  $warning');
      }
      print('');
    }

    print('═══════════════════════════════════════════════════════════');
    if (failedChecks == 0) {
      print('   ✓ VALIDATION PASSED - Ready for deployment!');
    } else {
      print('   ✗ VALIDATION FAILED - Fix errors before deployment!');
    }
    print('═══════════════════════════════════════════════════════════\n');

    // Exit with appropriate code
    exit(failedChecks > 0 ? 1 : 0);
  }
}
