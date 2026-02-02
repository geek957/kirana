#!/usr/bin/env dart
/**
 * Default Data Initialization Script (Dart)
 * 
 * This script initializes default data in Firestore for the Kirana Grocery App:
 * 1. Creates app configuration document with default values
 * 2. Creates default product categories
 * 
 * Prerequisites:
 * - Firebase project configured
 * - Firebase Admin SDK credentials
 * - Dart SDK installed
 * 
 * Usage:
 *   dart scripts/initialize_default_data.dart
 * 
 * Note: This script requires Firebase Admin SDK for Dart or uses REST API
 * For production use, consider using the Node.js script instead.
 */

import 'dart:convert';
import 'dart:io';

// ANSI color codes for console output
class Colors {
  static const String reset = '\x1B[0m';
  static const String bright = '\x1B[1m';
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String yellow = '\x1B[33m';
  static const String cyan = '\x1B[36m';
}

void log(String message, [String color = Colors.reset]) {
  print('$color$message${Colors.reset}');
}

void logSuccess(String message) => log('✓ $message', Colors.green);
void logError(String message) => log('✗ $message', Colors.red);
void logWarning(String message) => log('⚠ $message', Colors.yellow);
void logInfo(String message) => log('ℹ $message', Colors.cyan);

void logHeader(String message) {
  print('\n${'=' * 60}');
  log(message, Colors.bright);
  print('=' * 60);
}

// Default app configuration values
const Map<String, dynamic> defaultAppConfig = {
  'deliveryCharge': 20.0,
  'freeDeliveryThreshold': 200.0,
  'maxCartValue': 3000.0,
  'orderCapacityWarningThreshold': 2,
  'orderCapacityBlockThreshold': 10,
  'updatedAt': 'SERVER_TIMESTAMP', // Will be replaced with actual timestamp
  'updatedBy': 'system',
};

// Default categories
const List<Map<String, String>> defaultCategories = [
  {
    'name': 'Groceries',
    'description': 'Essential grocery items and daily needs',
  },
  {'name': 'Fruits & Vegetables', 'description': 'Fresh fruits and vegetables'},
  {'name': 'Dairy & Eggs', 'description': 'Milk, cheese, yogurt, and eggs'},
  {
    'name': 'Snacks & Beverages',
    'description': 'Snacks, drinks, and refreshments',
  },
  {
    'name': 'Personal Care',
    'description': 'Personal hygiene and care products',
  },
];

void printInstructions() {
  logHeader('Kirana Grocery App - Default Data Initialization');
  logInfo('This script provides instructions for initializing default data');
  print('');

  logWarning(
    'Note: This Dart script provides data templates and instructions.',
  );
  logWarning('For automated initialization, use the Node.js script instead.');
  print('');

  logInfo('To initialize data, you have two options:');
  print('');
  print('Option 1: Use Firebase Console (Recommended)');
  print('  See: docs/DEFAULT_DATA_INITIALIZATION.md');
  print('');
  print('Option 2: Use Node.js Script (Automated)');
  print('  Run: node scripts/initialize_default_data.js');
  print('');
}

void printAppConfigTemplate() {
  logHeader('App Configuration Template');
  logInfo('Create this document in Firestore:');
  print('');
  print('Collection: config');
  print('Document ID: app_settings');
  print('');
  print('Fields:');
  print(const JsonEncoder.withIndent('  ').convert(defaultAppConfig));
  print('');
  logInfo(
    'Replace SERVER_TIMESTAMP with current timestamp in Firebase Console',
  );
}

void printCategoriesTemplate() {
  logHeader('Default Categories Template');
  logInfo('Create these documents in the "categories" collection:');
  print('');

  for (var i = 0; i < defaultCategories.length; i++) {
    final category = defaultCategories[i];
    print('Category ${i + 1}: ${category['name']}');
    print('  name: ${category['name']}');
    print('  description: ${category['description']}');
    print('  productCount: 0');
    print('  createdAt: [Current Timestamp]');
    print('  updatedAt: [Current Timestamp]');
    print('  id: [Auto-generated Document ID]');
    print('');
  }
}

void printVerificationChecklist() {
  logHeader('Verification Checklist');
  print('');
  print('After creating the data, verify:');
  print('');
  print('App Configuration:');
  print('  [ ] Document exists at /config/app_settings');
  print('  [ ] deliveryCharge = 20.0');
  print('  [ ] freeDeliveryThreshold = 200.0');
  print('  [ ] maxCartValue = 3000.0');
  print('  [ ] orderCapacityWarningThreshold = 2');
  print('  [ ] orderCapacityBlockThreshold = 10');
  print('  [ ] updatedAt is a valid timestamp');
  print('  [ ] updatedBy = "system"');
  print('');
  print('Categories:');
  print('  [ ] categories collection exists');
  print('  [ ] At least one category exists');
  print('  [ ] Each category has all required fields');
  print('  [ ] productCount = 0 for all categories');
  print('  [ ] Timestamps are valid');
  print('');
}

void printNextSteps() {
  logHeader('Next Steps');
  print('');
  print('1. Create the data in Firebase Console or using Node.js script');
  print('2. Verify all data in Firebase Console');
  print('3. Create admin account (see docs/INITIAL_ADMIN_SETUP.md)');
  print('4. Login to app and verify:');
  print('   - Categories appear in Category Management');
  print('   - App Configuration shows correct values');
  print('   - Can add products to categories');
  print('5. Add your product catalog');
  print('6. Test app functionality');
  print('');
}

void exportToJson() {
  logHeader('Exporting Templates to JSON Files');

  try {
    // Export app config
    final configFile = File('scripts/default_app_config.json');
    configFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(defaultAppConfig),
    );
    logSuccess('Exported: ${configFile.path}');

    // Export categories
    final categoriesFile = File('scripts/default_categories.json');
    categoriesFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(defaultCategories),
    );
    logSuccess('Exported: ${categoriesFile.path}');

    print('');
    logInfo('You can use these JSON files as reference when creating data');
  } catch (e) {
    logError('Failed to export JSON files: $e');
  }
}

void main(List<String> arguments) {
  // Print instructions
  printInstructions();

  // Print templates
  printAppConfigTemplate();
  printCategoriesTemplate();

  // Export to JSON files
  exportToJson();

  // Print verification checklist
  printVerificationChecklist();

  // Print next steps
  printNextSteps();

  logHeader('✓ Template Generation Complete');
  logSuccess('Use the templates above to initialize your data');
  logInfo(
    'For detailed instructions, see: docs/DEFAULT_DATA_INITIALIZATION.md',
  );
  print('');
}
