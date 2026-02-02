#!/usr/bin/env node

/**
 * Default Data Initialization Script
 * 
 * This script initializes default data in Firestore for the Kirana Grocery App:
 * 1. Creates app configuration document with default values
 * 2. Creates default product categories
 * 
 * Prerequisites:
 * - Firebase Admin SDK credentials (serviceAccountKey.json)
 * - Node.js v14 or higher
 * - firebase-admin package installed
 * 
 * Usage:
 *   node scripts/initialize_default_data.js
 * 
 * Environment Variables:
 *   FIREBASE_PROJECT_ID - Firebase project ID (optional if in serviceAccountKey.json)
 *   SERVICE_ACCOUNT_PATH - Path to service account key (default: ./serviceAccountKey.json)
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Configuration
const SERVICE_ACCOUNT_PATH = process.env.SERVICE_ACCOUNT_PATH || './serviceAccountKey.json';
const PROJECT_ID = process.env.FIREBASE_PROJECT_ID;

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
};

function log(message, color = colors.reset) {
  console.log(`${color}${message}${colors.reset}`);
}

function logSuccess(message) {
  log(`✓ ${message}`, colors.green);
}

function logError(message) {
  log(`✗ ${message}`, colors.red);
}

function logWarning(message) {
  log(`⚠ ${message}`, colors.yellow);
}

function logInfo(message) {
  log(`ℹ ${message}`, colors.cyan);
}

function logHeader(message) {
  log(`\n${'='.repeat(60)}`, colors.bright);
  log(message, colors.bright);
  log('='.repeat(60), colors.bright);
}

// Initialize Firebase Admin SDK
function initializeFirebase() {
  try {
    // Check if service account file exists
    if (!fs.existsSync(SERVICE_ACCOUNT_PATH)) {
      logError(`Service account key not found at: ${SERVICE_ACCOUNT_PATH}`);
      logInfo('Please download your service account key from Firebase Console:');
      logInfo('  1. Go to Project Settings → Service Accounts');
      logInfo('  2. Click "Generate new private key"');
      logInfo('  3. Save as serviceAccountKey.json in project root');
      process.exit(1);
    }

    const serviceAccount = require(path.resolve(SERVICE_ACCOUNT_PATH));

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      projectId: PROJECT_ID || serviceAccount.project_id,
    });

    logSuccess('Firebase Admin SDK initialized');
    return admin.firestore();
  } catch (error) {
    logError(`Failed to initialize Firebase: ${error.message}`);
    process.exit(1);
  }
}

// Default app configuration values
const DEFAULT_APP_CONFIG = {
  deliveryCharge: 20.0,
  freeDeliveryThreshold: 200.0,
  maxCartValue: 3000.0,
  orderCapacityWarningThreshold: 2,
  orderCapacityBlockThreshold: 10,
  updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  updatedBy: 'system',
};

// Default categories
const DEFAULT_CATEGORIES = [
  {
    name: 'Groceries',
    description: 'Essential grocery items and daily needs',
  },
  {
    name: 'Fruits & Vegetables',
    description: 'Fresh fruits and vegetables',
  },
  {
    name: 'Dairy & Eggs',
    description: 'Milk, cheese, yogurt, and eggs',
  },
  {
    name: 'Snacks & Beverages',
    description: 'Snacks, drinks, and refreshments',
  },
  {
    name: 'Personal Care',
    description: 'Personal hygiene and care products',
  },
];

// Create app configuration document
async function createAppConfig(db) {
  logHeader('Creating App Configuration');

  try {
    const configRef = db.collection('config').doc('app_settings');
    const configDoc = await configRef.get();

    if (configDoc.exists) {
      logWarning('App configuration already exists');
      logInfo('Current configuration:');
      const data = configDoc.data();
      console.log(JSON.stringify(data, null, 2));
      
      const readline = require('readline').createInterface({
        input: process.stdin,
        output: process.stdout,
      });

      return new Promise((resolve) => {
        readline.question('\nOverwrite existing configuration? (yes/no): ', (answer) => {
          readline.close();
          if (answer.toLowerCase() === 'yes' || answer.toLowerCase() === 'y') {
            configRef.set(DEFAULT_APP_CONFIG).then(() => {
              logSuccess('App configuration updated');
              resolve(true);
            });
          } else {
            logInfo('Keeping existing configuration');
            resolve(false);
          }
        });
      });
    }

    await configRef.set(DEFAULT_APP_CONFIG);
    logSuccess('App configuration created successfully');
    logInfo('Configuration values:');
    console.log(JSON.stringify(DEFAULT_APP_CONFIG, null, 2));
    return true;
  } catch (error) {
    logError(`Failed to create app configuration: ${error.message}`);
    throw error;
  }
}

// Create default categories
async function createDefaultCategories(db) {
  logHeader('Creating Default Categories');

  const results = {
    created: [],
    skipped: [],
    errors: [],
  };

  for (const category of DEFAULT_CATEGORIES) {
    try {
      // Check if category with same name already exists
      const existingQuery = await db
        .collection('categories')
        .where('name', '==', category.name)
        .limit(1)
        .get();

      if (!existingQuery.empty) {
        logWarning(`Category "${category.name}" already exists`);
        results.skipped.push(category.name);
        continue;
      }

      // Create new category
      const categoryRef = db.collection('categories').doc();
      const categoryData = {
        id: categoryRef.id,
        name: category.name,
        description: category.description,
        productCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      await categoryRef.set(categoryData);
      logSuccess(`Created category: ${category.name}`);
      results.created.push(category.name);
    } catch (error) {
      logError(`Failed to create category "${category.name}": ${error.message}`);
      results.errors.push({ name: category.name, error: error.message });
    }
  }

  return results;
}

// Verify created data
async function verifyData(db) {
  logHeader('Verifying Created Data');

  let allValid = true;

  // Verify app configuration
  try {
    const configDoc = await db.collection('config').doc('app_settings').get();
    if (configDoc.exists) {
      logSuccess('App configuration exists');
      const data = configDoc.data();
      
      // Verify required fields
      const requiredFields = [
        'deliveryCharge',
        'freeDeliveryThreshold',
        'maxCartValue',
        'orderCapacityWarningThreshold',
        'orderCapacityBlockThreshold',
        'updatedAt',
        'updatedBy',
      ];

      for (const field of requiredFields) {
        if (data[field] === undefined) {
          logError(`  Missing field: ${field}`);
          allValid = false;
        } else {
          logSuccess(`  ${field}: ${data[field]}`);
        }
      }
    } else {
      logError('App configuration does not exist');
      allValid = false;
    }
  } catch (error) {
    logError(`Failed to verify app configuration: ${error.message}`);
    allValid = false;
  }

  // Verify categories
  try {
    const categoriesSnapshot = await db.collection('categories').get();
    const categoryCount = categoriesSnapshot.size;

    if (categoryCount === 0) {
      logError('No categories found');
      allValid = false;
    } else {
      logSuccess(`Found ${categoryCount} categories`);
      
      categoriesSnapshot.forEach((doc) => {
        const data = doc.data();
        logInfo(`  - ${data.name} (${data.productCount} products)`);
      });
    }
  } catch (error) {
    logError(`Failed to verify categories: ${error.message}`);
    allValid = false;
  }

  return allValid;
}

// Main execution
async function main() {
  logHeader('Kirana Grocery App - Default Data Initialization');
  logInfo('This script will initialize default data in Firestore');
  logInfo('');

  try {
    // Initialize Firebase
    const db = initializeFirebase();

    // Create app configuration
    await createAppConfig(db);

    // Create default categories
    const categoryResults = await createDefaultCategories(db);

    // Display summary
    logHeader('Summary');
    logInfo(`Categories created: ${categoryResults.created.length}`);
    if (categoryResults.created.length > 0) {
      categoryResults.created.forEach((name) => logSuccess(`  - ${name}`));
    }

    if (categoryResults.skipped.length > 0) {
      logInfo(`Categories skipped: ${categoryResults.skipped.length}`);
      categoryResults.skipped.forEach((name) => logWarning(`  - ${name}`));
    }

    if (categoryResults.errors.length > 0) {
      logInfo(`Categories with errors: ${categoryResults.errors.length}`);
      categoryResults.errors.forEach((item) => 
        logError(`  - ${item.name}: ${item.error}`)
      );
    }

    // Verify all data
    const isValid = await verifyData(db);

    if (isValid) {
      logHeader('✓ Initialization Complete');
      logSuccess('All default data has been created successfully!');
      logInfo('');
      logInfo('Next steps:');
      logInfo('  1. Verify data in Firebase Console');
      logInfo('  2. Create admin account (see INITIAL_ADMIN_SETUP.md)');
      logInfo('  3. Add products to categories');
      logInfo('  4. Test app functionality');
      process.exit(0);
    } else {
      logHeader('⚠ Initialization Complete with Warnings');
      logWarning('Some data may be missing or invalid');
      logInfo('Please check the errors above and verify in Firebase Console');
      process.exit(1);
    }
  } catch (error) {
    logHeader('✗ Initialization Failed');
    logError(`Error: ${error.message}`);
    logError(error.stack);
    process.exit(1);
  }
}

// Run the script
if (require.main === module) {
  main();
}

module.exports = {
  createAppConfig,
  createDefaultCategories,
  verifyData,
};
