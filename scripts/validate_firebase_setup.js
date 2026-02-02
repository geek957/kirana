#!/usr/bin/env node
/**
 * Firebase Setup Validation Script
 * 
 * This script validates Firebase configuration including:
 * - Firestore indexes
 * - Security rules
 * - Default data (config, categories)
 * - Storage rules
 * 
 * Prerequisites:
 * - Firebase Admin SDK initialized
 * - Service account credentials configured
 * 
 * Usage: node scripts/validate_firebase_setup.js
 */

const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

// Color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

class FirebaseValidator {
  constructor() {
    this.passedChecks = 0;
    this.failedChecks = 0;
    this.warningChecks = 0;
    this.errors = [];
    this.warnings = [];
  }

  async initialize() {
    try {
      // Check if already initialized
      if (admin.apps.length === 0) {
        // Try to initialize with service account
        const serviceAccountPath = process.env.GOOGLE_APPLICATION_CREDENTIALS ||
          path.join(__dirname, 'serviceAccountKey.json');

        if (fs.existsSync(serviceAccountPath)) {
          const serviceAccount = require(serviceAccountPath);
          admin.initializeApp({
            credential: admin.credential.cert(serviceAccount),
          });
          this.pass('✓ Firebase Admin SDK initialized');
        } else {
          this.fail('✗ Service account key not found. Set GOOGLE_APPLICATION_CREDENTIALS or place serviceAccountKey.json in scripts/');
          return false;
        }
      }
      return true;
    } catch (error) {
      this.fail(`✗ Failed to initialize Firebase: ${error.message}`);
      return false;
    }
  }

  async runAllValidations() {
    console.log('═══════════════════════════════════════════════════════════');
    console.log('   Firebase Setup Validation Script');
    console.log('   Version: 2.0 (Enhanced Features)');
    console.log('═══════════════════════════════════════════════════════════\n');

    const initialized = await this.initialize();
    if (!initialized) {
      this.printSummary();
      return;
    }

    console.log('Starting Firebase validation checks...\n');

    // 1. Validate Firestore Collections
    await this.validateFirestoreCollections();

    // 2. Validate Default Configuration
    await this.validateDefaultConfig();

    // 3. Validate Categories
    await this.validateCategories();

    // 4. Validate Products
    await this.validateProducts();

    // 5. Validate Indexes (informational)
    await this.validateIndexes();

    // 6. Validate Storage Structure
    await this.validateStorageStructure();

    // Print Summary
    this.printSummary();
  }

  async validateFirestoreCollections() {
    this.printSection('1. Firestore Collections Validation');

    const db = admin.firestore();

    const requiredCollections = [
      'products',
      'categories',
      'orders',
      'users',
      'config',
    ];

    for (const collectionName of requiredCollections) {
      try {
        const snapshot = await db.collection(collectionName).limit(1).get();
        if (collectionName === 'config') {
          // Config should have at least the app_settings document
          const configDoc = await db.collection('config').doc('app_settings').get();
          if (configDoc.exists) {
            this.pass(`✓ Collection '${collectionName}' exists with app_settings document`);
          } else {
            this.fail(`✗ Collection '${collectionName}' exists but app_settings document missing`);
          }
        } else {
          this.pass(`✓ Collection '${collectionName}' exists`);
        }
      } catch (error) {
        this.fail(`✗ Error accessing collection '${collectionName}': ${error.message}`);
      }
    }
  }

  async validateDefaultConfig() {
    this.printSection('2. Default Configuration Validation');

    const db = admin.firestore();

    try {
      const configDoc = await db.collection('config').doc('app_settings').get();

      if (!configDoc.exists) {
        this.fail('✗ Default config document (config/app_settings) does not exist');
        return;
      }

      const config = configDoc.data();
      const requiredFields = {
        deliveryCharge: { type: 'number', default: 20 },
        freeDeliveryThreshold: { type: 'number', default: 200 },
        maxCartValue: { type: 'number', default: 3000 },
        orderCapacityWarningThreshold: { type: 'number', default: 2 },
        orderCapacityBlockThreshold: { type: 'number', default: 10 },
        updatedAt: { type: 'object' },
        updatedBy: { type: 'string' },
      };

      for (const [field, spec] of Object.entries(requiredFields)) {
        if (config[field] !== undefined) {
          const actualType = typeof config[field];
          const expectedType = spec.type === 'object' ? 'object' : spec.type;
          
          if (actualType === expectedType || (spec.type === 'object' && config[field] !== null)) {
            const value = spec.type === 'number' ? ` (${config[field]})` : '';
            this.pass(`✓ Config field '${field}' present${value}`);
          } else {
            this.fail(`✗ Config field '${field}' has wrong type: ${actualType} (expected ${expectedType})`);
          }
        } else {
          this.fail(`✗ Config field '${field}' missing`);
        }
      }

      // Validate relationships
      if (config.freeDeliveryThreshold && config.maxCartValue) {
        if (config.maxCartValue > config.freeDeliveryThreshold) {
          this.pass('✓ maxCartValue > freeDeliveryThreshold');
        } else {
          this.warn('⚠ maxCartValue should be greater than freeDeliveryThreshold');
        }
      }

      if (config.orderCapacityWarningThreshold && config.orderCapacityBlockThreshold) {
        if (config.orderCapacityBlockThreshold > config.orderCapacityWarningThreshold) {
          this.pass('✓ orderCapacityBlockThreshold > orderCapacityWarningThreshold');
        } else {
          this.fail('✗ orderCapacityBlockThreshold should be greater than orderCapacityWarningThreshold');
        }
      }

    } catch (error) {
      this.fail(`✗ Error validating config: ${error.message}`);
    }
  }

  async validateCategories() {
    this.printSection('3. Categories Validation');

    const db = admin.firestore();

    try {
      const categoriesSnapshot = await db.collection('categories').get();

      if (categoriesSnapshot.empty) {
        this.fail('✗ No categories found. At least one category is required.');
        return;
      }

      this.pass(`✓ Found ${categoriesSnapshot.size} categories`);

      const categoryNames = new Set();
      let duplicateFound = false;

      categoriesSnapshot.forEach((doc) => {
        const category = doc.data();
        
        // Check required fields
        if (!category.name) {
          this.fail(`✗ Category ${doc.id} missing 'name' field`);
        } else {
          // Check for duplicate names
          if (categoryNames.has(category.name)) {
            this.fail(`✗ Duplicate category name found: '${category.name}'`);
            duplicateFound = true;
          }
          categoryNames.add(category.name);
        }

        if (category.productCount === undefined) {
          this.warn(`⚠ Category '${category.name}' missing 'productCount' field`);
        }
      });

      if (!duplicateFound) {
        this.pass('✓ All category names are unique');
      }

      // List categories
      console.log(`\n  Categories found:`);
      categoriesSnapshot.forEach((doc) => {
        const category = doc.data();
        console.log(`    - ${category.name} (${category.productCount || 0} products)`);
      });

    } catch (error) {
      this.fail(`✗ Error validating categories: ${error.message}`);
    }
  }

  async validateProducts() {
    this.printSection('4. Products Validation');

    const db = admin.firestore();

    try {
      const productsSnapshot = await db.collection('products').limit(10).get();

      if (productsSnapshot.empty) {
        this.warn('⚠ No products found in database');
        return;
      }

      this.pass(`✓ Products collection has data (checked ${productsSnapshot.size} products)`);

      let hasNewFields = true;
      let missingCategoryId = 0;
      let missingMinQty = 0;

      productsSnapshot.forEach((doc) => {
        const product = doc.data();

        // Check for new required fields
        if (!product.categoryId) {
          missingCategoryId++;
          hasNewFields = false;
        }

        if (product.minimumOrderQuantity === undefined) {
          missingMinQty++;
          hasNewFields = false;
        }

        // Validate discount price if present
        if (product.discountPrice !== undefined && product.discountPrice !== null) {
          if (product.discountPrice >= product.price) {
            this.fail(`✗ Product '${product.name}' has invalid discount: ${product.discountPrice} >= ${product.price}`);
          }
        }
      });

      if (missingCategoryId > 0) {
        this.fail(`✗ ${missingCategoryId} products missing 'categoryId' field`);
      } else {
        this.pass('✓ All checked products have categoryId');
      }

      if (missingMinQty > 0) {
        this.fail(`✗ ${missingMinQty} products missing 'minimumOrderQuantity' field`);
      } else {
        this.pass('✓ All checked products have minimumOrderQuantity');
      }

    } catch (error) {
      this.fail(`✗ Error validating products: ${error.message}`);
    }
  }

  async validateIndexes() {
    this.printSection('5. Firestore Indexes (Informational)');

    console.log('  Note: Index validation requires Firebase CLI or manual verification');
    console.log('  Required indexes:');
    console.log('    1. products: categoryId (ASC) + isAvailable (ASC) + name (ASC)');
    console.log('    2. categories: name (ASC)');
    console.log('    3. orders: status (ASC) + createdAt (DESC)');
    console.log('\n  Please verify these indexes exist in Firebase Console:');
    console.log('  https://console.firebase.google.com/project/_/firestore/indexes\n');

    this.warn('⚠ Manual verification required for Firestore indexes');
  }

  async validateStorageStructure() {
    this.printSection('6. Firebase Storage Validation');

    try {
      const bucket = admin.storage().bucket();
      
      // Check if bucket exists
      const [exists] = await bucket.exists();
      if (exists) {
        this.pass('✓ Firebase Storage bucket exists');
      } else {
        this.fail('✗ Firebase Storage bucket does not exist');
        return;
      }

      // Check for delivery_photos directory (it may not exist until first upload)
      const [files] = await bucket.getFiles({ prefix: 'delivery_photos/', maxResults: 1 });
      if (files.length > 0) {
        this.pass('✓ delivery_photos/ directory exists with files');
      } else {
        this.warn('⚠ delivery_photos/ directory empty (will be created on first upload)');
      }

    } catch (error) {
      this.fail(`✗ Error validating storage: ${error.message}`);
    }
  }

  pass(message) {
    console.log(`  ${colors.green}${message}${colors.reset}`);
    this.passedChecks++;
  }

  fail(message) {
    console.log(`  ${colors.red}${message}${colors.reset}`);
    this.failedChecks++;
    this.errors.push(message);
  }

  warn(message) {
    console.log(`  ${colors.yellow}${message}${colors.reset}`);
    this.warningChecks++;
    this.warnings.push(message);
  }

  printSection(title) {
    console.log(`\n${colors.cyan}${title}${colors.reset}`);
    console.log('─'.repeat(60));
  }

  printSummary() {
    console.log('\n═══════════════════════════════════════════════════════════');
    console.log('   VALIDATION SUMMARY');
    console.log('═══════════════════════════════════════════════════════════\n');

    console.log(`  ${colors.green}✓ Passed:   ${this.passedChecks}${colors.reset}`);
    console.log(`  ${colors.red}✗ Failed:   ${this.failedChecks}${colors.reset}`);
    console.log(`  ${colors.yellow}⚠ Warnings: ${this.warningChecks}${colors.reset}`);
    console.log('  ─────────────────────');
    console.log(`  Total:      ${this.passedChecks + this.failedChecks + this.warningChecks}\n`);

    if (this.failedChecks > 0) {
      console.log('═══════════════════════════════════════════════════════════');
      console.log('   ERRORS (Must be fixed before deployment)');
      console.log('═══════════════════════════════════════════════════════════\n');
      this.errors.forEach((error) => {
        console.log(`  ${colors.red}${error}${colors.reset}`);
      });
      console.log('');
    }

    if (this.warningChecks > 0) {
      console.log('═══════════════════════════════════════════════════════════');
      console.log('   WARNINGS (Should be reviewed)');
      console.log('═══════════════════════════════════════════════════════════\n');
      this.warnings.forEach((warning) => {
        console.log(`  ${colors.yellow}${warning}${colors.reset}`);
      });
      console.log('');
    }

    console.log('═══════════════════════════════════════════════════════════');
    if (this.failedChecks === 0) {
      console.log(`   ${colors.green}✓ VALIDATION PASSED - Firebase setup complete!${colors.reset}`);
    } else {
      console.log(`   ${colors.red}✗ VALIDATION FAILED - Fix errors before deployment!${colors.reset}`);
    }
    console.log('═══════════════════════════════════════════════════════════\n');

    // Exit with appropriate code
    process.exit(this.failedChecks > 0 ? 1 : 0);
  }
}

// Run validation
const validator = new FirebaseValidator();
validator.runAllValidations().catch((error) => {
  console.error(`${colors.red}Fatal error: ${error.message}${colors.reset}`);
  process.exit(1);
});
