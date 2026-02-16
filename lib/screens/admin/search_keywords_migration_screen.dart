import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/product_service.dart';

/// Admin screen to run search keywords migration
/// This regenerates searchKeywords for all products to support partial matching
class SearchKeywordsMigrationScreen extends StatefulWidget {
  const SearchKeywordsMigrationScreen({Key? key}) : super(key: key);

  @override
  State<SearchKeywordsMigrationScreen> createState() =>
      _SearchKeywordsMigrationScreenState();
}

class _SearchKeywordsMigrationScreenState
    extends State<SearchKeywordsMigrationScreen> {
  bool _isRunning = false;
  bool _isCompleted = false;
  int _totalProducts = 0;
  int _processed = 0;
  int _failed = 0;
  final List<String> _logs = [];
  final List<String> _failedProductIds = [];

  @override
  void initState() {
    super.initState();
    _checkProductCount();
  }

  Future<void> _checkProductCount() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('products').count().get();
      setState(() {
        _totalProducts = snapshot.count ?? 0;
      });
    } catch (e) {
      _addLog('Error counting products: $e');
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add(message);
    });
    print(message); // Also log to console
  }

  Future<void> _runMigration() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _isCompleted = false;
      _processed = 0;
      _failed = 0;
      _logs.clear();
      _failedProductIds.clear();
    });

    _addLog('🚀 Starting Search Keywords Migration');
    _addLog('=' * 50);

    try {
      final firestore = FirebaseFirestore.instance;

      // Fetch all products
      _addLog('📦 Fetching all products from Firestore...');
      final snapshot = await firestore.collection('products').get();
      final totalProducts = snapshot.docs.length;

      setState(() {
        _totalProducts = totalProducts;
      });

      if (totalProducts == 0) {
        _addLog('⚠️  No products found in database');
        setState(() {
          _isRunning = false;
          _isCompleted = true;
        });
        return;
      }

      _addLog('✅ Found $totalProducts products');
      _addLog('🔄 Starting migration...\n');

      // Process products in batches
      const batchSize = 500;
      int totalUpdated = 0;

      for (int i = 0; i < snapshot.docs.length; i += batchSize) {
        final batch = firestore.batch();
        final end = (i + batchSize < snapshot.docs.length)
            ? i + batchSize
            : snapshot.docs.length;

        _addLog('📝 Processing batch ${(i ~/ batchSize) + 1}...');

        for (int j = i; j < end; j++) {
          final doc = snapshot.docs[j];
          final data = doc.data();

          try {
            final name = data['name'] as String?;
            final category = data['category'] as String?;

            if (name == null || category == null) {
              _addLog('⚠️  Skipping product ${doc.id}: Missing name or category');
              setState(() {
                _failed++;
              });
              _failedProductIds.add(doc.id);
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
            setState(() {
              _processed = totalUpdated;
            });

            // Show progress for every 50 products
            if ((totalUpdated % 50) == 0) {
              _addLog('   ✓ Updated $totalUpdated/$totalProducts products');
            }
          } catch (e) {
            _addLog('❌ Error processing product ${doc.id}: $e');
            setState(() {
              _failed++;
            });
            _failedProductIds.add(doc.id);
          }
        }

        // Commit batch
        try {
          await batch.commit();
          _addLog('✅ Batch ${(i ~/ batchSize) + 1} committed successfully\n');
        } catch (e) {
          _addLog('❌ Error committing batch: $e\n');
          setState(() {
            _failed += (end - i);
          });
        }
      }

      // Print summary
      _addLog('=' * 50);
      _addLog('🎉 Migration Complete!\n');
      _addLog('Summary:');
      _addLog('  ✅ Successfully updated: $totalUpdated products');
      _addLog('  ❌ Failed: $_failed products');
      _addLog('  📊 Total processed: $totalProducts products');

      if (_failedProductIds.isNotEmpty) {
        _addLog('\n⚠️  Failed product IDs:');
        for (final id in _failedProductIds) {
          _addLog('     - $id');
        }
      }

      _addLog('\n✨ Next steps:');
      _addLog('  1. Test search functionality in your app');
      _addLog('  2. Try searching "Aas" to find "Aashirvaad" products');
      _addLog('  3. Verify that partial word matching works');

      setState(() {
        _isCompleted = true;
      });
    } catch (e) {
      _addLog('\n❌ Fatal error during migration: $e');
      setState(() {
        _isCompleted = true;
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Keywords Migration'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Search Keywords Migration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This will update searchKeywords for all products to support partial word matching.\n\n'
                      'Example:\n'
                      '• Before: Search "Aas" → No results\n'
                      '• After: Search "Aas" → Finds "Aashirvaad" products ✓',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Total products: $_totalProducts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Progress Card
            if (_isRunning || _isCompleted)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _isCompleted ? 'Completed!' : 'Processing...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _isCompleted
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                          if (_isRunning)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_totalProducts > 0)
                        LinearProgressIndicator(
                          value: _processed / _totalProducts,
                          backgroundColor: Colors.grey.shade300,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        'Progress: $_processed / $_totalProducts products',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (_failed > 0)
                        Text(
                          'Failed: $_failed products',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red.shade700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Run Button
            if (!_isRunning && !_isCompleted)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _totalProducts > 0 ? _runMigration : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run Migration'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),

            // Run Again Button
            if (_isCompleted)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _runMigration,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Run Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Logs
            const Text(
              'Logs:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Expanded(
              child: Card(
                color: Colors.grey.shade900,
                child: _logs.isEmpty
                    ? const Center(
                        child: Text(
                          'No logs yet. Click "Run Migration" to start.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _logs.length,
                        itemBuilder: (context, index) {
                          final log = _logs[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              log,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: log.contains('❌')
                                    ? Colors.red.shade300
                                    : log.contains('✅')
                                        ? Colors.green.shade300
                                        : log.contains('⚠️')
                                            ? Colors.orange.shade300
                                            : Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
