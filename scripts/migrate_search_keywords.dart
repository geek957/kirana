import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import '../lib/firebase_options.dart';
import '../lib/services/product_service.dart';

/// Migration script to regenerate search keywords for all products
/// This adds prefix support for partial word matching
/// 
/// Usage: flutter run -d macos scripts/migrate_search_keywords.dart
///    or: flutter run -d chrome scripts/migrate_search_keywords.dart
void main(List<String> args) async {
  print('🚀 Starting Search Keywords Migration');
  print('=' * 60);
  
  try {
    // Initialize Flutter bindings (required for Firebase)
    print('🔧 Initializing Flutter bindings...');
    WidgetsFlutterBinding.ensureInitialized();
    print('✅ Flutter bindings initialized\n');
    
    // Initialize Firebase
    print('📱 Initializing Firebase...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized\n');
    
    // Get Firestore instance
    final firestore = FirebaseFirestore.instance;
    
    // Fetch all products
    print('📦 Fetching all products from Firestore...');
    final snapshot = await firestore.collection('products').get();
    final totalProducts = snapshot.docs.length;
    
    if (totalProducts == 0) {
      print('⚠️  No products found in database');
      exit(0);
    }
    
    print('✅ Found $totalProducts products\n');
    
    // Ask for confirmation
    print('⚠️  This will update searchKeywords for all $totalProducts products');
    print('   Old keywords will be replaced with new prefix-based keywords');
    print('   This operation cannot be undone easily.\n');
    
    stdout.write('Continue? (y/n): ');
    final response = stdin.readLineSync()?.toLowerCase().trim();
    
    if (response != 'y' && response != 'yes') {
      print('❌ Migration cancelled by user');
      exit(0);
    }
    
    print('\n🔄 Starting migration...\n');
    
    // Process products in batches
    const batchSize = 500; // Firestore batch limit
    int totalUpdated = 0;
    int totalFailed = 0;
    final failedProducts = <String>[];
    
    for (int i = 0; i < snapshot.docs.length; i += batchSize) {
      final batch = firestore.batch();
      final end = (i + batchSize < snapshot.docs.length) 
          ? i + batchSize 
          : snapshot.docs.length;
      
      print('📝 Processing batch ${(i ~/ batchSize) + 1}...');
      
      for (int j = i; j < end; j++) {
        final doc = snapshot.docs[j];
        final data = doc.data();
        
        try {
          final name = data['name'] as String?;
          final category = data['category'] as String?;
          
          if (name == null || category == null) {
            print('⚠️  Skipping product ${doc.id}: Missing name or category');
            totalFailed++;
            failedProducts.add(doc.id);
            continue;
          }
          
          // Generate new keywords with prefix support
          final newKeywords = ProductService.generateSearchKeywords(
            name,
            category,
          );
          
          // Update product
          batch.update(doc.reference, {
            'searchKeywords': newKeywords,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          
          totalUpdated++;
          
          // Show progress for each product
          if ((totalUpdated % 50) == 0) {
            print('   ✓ Updated $totalUpdated/$totalProducts products');
          }
          
        } catch (e) {
          print('❌ Error processing product ${doc.id}: $e');
          totalFailed++;
          failedProducts.add(doc.id);
        }
      }
      
      // Commit batch
      try {
        await batch.commit();
        print('✅ Batch ${(i ~/ batchSize) + 1} committed successfully\n');
      } catch (e) {
        print('❌ Error committing batch: $e\n');
        totalFailed += (end - i);
      }
    }
    
    // Print summary
    print('=' * 60);
    print('🎉 Migration Complete!\n');
    print('Summary:');
    print('  ✅ Successfully updated: $totalUpdated products');
    print('  ❌ Failed: $totalFailed products');
    print('  📊 Total processed: $totalProducts products');
    
    if (failedProducts.isNotEmpty) {
      print('\n⚠️  Failed product IDs:');
      for (final id in failedProducts) {
        print('     - $id');
      }
    }
    
    print('\n✨ Next steps:');
    print('  1. Test search functionality in your app');
    print('  2. Try searching "Aas" to find "Aashirvaad" products');
    print('  3. Verify that partial word matching works');
    
    exit(0);
    
  } catch (e) {
    print('\n❌ Fatal error during migration: $e');
    exit(1);
  }
}
