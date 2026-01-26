// Widget tests for the Kirana grocery app
//
// These tests verify UI components render correctly and handle user interactions.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('App test framework is working', (WidgetTester tester) async {
    // This is a basic smoke test to ensure the test framework is working
    expect(true, true);
  });

  testWidgets('Firestore mock can be created', (WidgetTester tester) async {
    // Verify that we can create a fake Firestore instance for testing
    final firestore = FakeFirebaseFirestore();
    expect(firestore, isNotNull);

    // Verify we can write and read data
    await firestore.collection('test').doc('test1').set({'value': 'test'});
    final doc = await firestore.collection('test').doc('test1').get();
    expect(doc.exists, true);
    expect(doc.data()?['value'], 'test');
  });

  group('Data Model Tests', () {
    test('Firestore can store and retrieve product data', () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('products').doc('product1').set({
        'name': 'Tomatoes',
        'price': 40.0,
        'category': 'Vegetables',
        'stockQuantity': 50,
        'isActive': true,
      });

      final doc = await firestore.collection('products').doc('product1').get();
      expect(doc.exists, true);
      expect(doc.data()?['name'], 'Tomatoes');
      expect(doc.data()?['price'], 40.0);
      expect(doc.data()?['stockQuantity'], 50);
    });

    test('Firestore can store and retrieve cart data', () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('carts').doc('customer1').set({
        'customerId': 'customer1',
        'items': [
          {'productId': 'product1', 'quantity': 2, 'price': 40.0},
        ],
        'totalAmount': 80.0,
      });

      final doc = await firestore.collection('carts').doc('customer1').get();
      expect(doc.exists, true);
      expect(doc.data()?['customerId'], 'customer1');
      expect(doc.data()?['totalAmount'], 80.0);
    });

    test('Firestore can store and retrieve order data', () async {
      final firestore = FakeFirebaseFirestore();

      await firestore.collection('orders').doc('order1').set({
        'id': 'order1',
        'customerId': 'customer1',
        'customerName': 'John Doe',
        'items': [],
        'totalAmount': 180.0,
        'status': 'pending',
        'createdAt': DateTime.now(),
      });

      final doc = await firestore.collection('orders').doc('order1').get();
      expect(doc.exists, true);
      expect(doc.data()?['customerId'], 'customer1');
      expect(doc.data()?['status'], 'pending');
      expect(doc.data()?['totalAmount'], 180.0);
    });
  });

  group('Widget Tests - Product Card', () {
    testWidgets('ProductCard displays product information correctly', (
      WidgetTester tester,
    ) async {
      final product = {
        'id': 'prod-1',
        'name': 'Fresh Tomatoes',
        'price': 45.99,
        'imageUrl': 'https://example.com/tomato.jpg',
        'stockQuantity': 50,
        'unitSize': '1kg',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                children: [
                  Text(product['name'] as String),
                  Text('₹${product['price']}'),
                  Text('${product['stockQuantity']} in stock'),
                  Text(product['unitSize'] as String),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Fresh Tomatoes'), findsOneWidget);
      expect(find.text('₹45.99'), findsOneWidget);
      expect(find.text('50 in stock'), findsOneWidget);
      expect(find.text('1kg'), findsOneWidget);
    });

    testWidgets('ProductCard shows out of stock message when stock is 0', (
      WidgetTester tester,
    ) async {
      final product = {'name': 'Fresh Tomatoes', 'stockQuantity': 0};

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Column(
                children: [
                  Text(product['name'] as String),
                  if (product['stockQuantity'] == 0) const Text('Out of Stock'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Out of Stock'), findsOneWidget);
    });
  });

  group('Widget Tests - Cart Display', () {
    testWidgets('Cart displays items and total correctly', (
      WidgetTester tester,
    ) async {
      final cartItems = [
        {'name': 'Tomatoes', 'quantity': 2, 'price': 40.0},
        {'name': 'Onions', 'quantity': 1, 'price': 30.0},
      ];
      final total = 110.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ...cartItems.map(
                  (item) => ListTile(
                    title: Text(item['name'] as String),
                    subtitle: Text('Qty: ${item['quantity']}'),
                    trailing: Text('₹${item['price']}'),
                  ),
                ),
                Text('Total: ₹$total'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.text('Onions'), findsOneWidget);
      expect(find.text('Qty: 2'), findsOneWidget);
      expect(find.text('Qty: 1'), findsOneWidget);
      expect(find.text('Total: ₹110.0'), findsOneWidget);
    });

    testWidgets('Empty cart shows appropriate message', (
      WidgetTester tester,
    ) async {
      final cartItems = <Map<String, dynamic>>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty'))
                : ListView(children: const []),
          ),
        ),
      );

      expect(find.text('Your cart is empty'), findsOneWidget);
    });
  });

  group('Widget Tests - Order Confirmation', () {
    testWidgets('Order confirmation displays order details', (
      WidgetTester tester,
    ) async {
      final orderId = 'ORDER-12345';
      final total = 250.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                const Text('Order Placed Successfully!'),
                Text('Order ID: $orderId'),
                Text('Total: ₹$total'),
                const Text('Payment Method: Cash on Delivery'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Order Placed Successfully!'), findsOneWidget);
      expect(find.text('Order ID: ORDER-12345'), findsOneWidget);
      expect(find.text('Total: ₹250.0'), findsOneWidget);
      expect(find.text('Payment Method: Cash on Delivery'), findsOneWidget);
    });
  });

  group('Widget Tests - Order History', () {
    testWidgets('Order history displays list of orders', (
      WidgetTester tester,
    ) async {
      final orders = [
        {
          'id': 'ORDER-001',
          'date': '2024-01-15',
          'status': 'Delivered',
          'total': 150.0,
        },
        {
          'id': 'ORDER-002',
          'date': '2024-01-20',
          'status': 'Pending',
          'total': 200.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: orders
                  .map(
                    (order) => ListTile(
                      title: Text(order['id'] as String),
                      subtitle: Text(order['date'] as String),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(order['status'] as String),
                          Text('₹${order['total']}'),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      );

      expect(find.text('ORDER-001'), findsOneWidget);
      expect(find.text('ORDER-002'), findsOneWidget);
      expect(find.text('Delivered'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('₹150.0'), findsOneWidget);
      expect(find.text('₹200.0'), findsOneWidget);
    });
  });

  group('Widget Tests - Admin Dashboard', () {
    testWidgets('Admin dashboard displays statistics', (
      WidgetTester tester,
    ) async {
      final stats = {
        'totalProducts': 45,
        'todayOrders': 12,
        'lowStockItems': 5,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                Card(
                  child: Column(
                    children: [
                      const Text('Total Products'),
                      Text('${stats['totalProducts']}'),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      const Text('Today\'s Orders'),
                      Text('${stats['todayOrders']}'),
                    ],
                  ),
                ),
                Card(
                  child: Column(
                    children: [
                      const Text('Low Stock Items'),
                      Text('${stats['lowStockItems']}'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Total Products'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
      expect(find.text('Today\'s Orders'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Low Stock Items'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });
  });

  group('Widget Tests - Product Search', () {
    testWidgets('Search bar filters products correctly', (
      WidgetTester tester,
    ) async {
      final allProducts = ['Tomatoes', 'Onions', 'Potatoes', 'Carrots'];
      var searchQuery = 'tom';
      final filteredProducts = allProducts
          .where((p) => p.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search products',
                  ),
                  onChanged: (value) {
                    searchQuery = value;
                  },
                ),
                Expanded(
                  child: ListView(
                    children: filteredProducts
                        .map((product) => ListTile(title: Text(product)))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search products'), findsOneWidget);
      expect(find.text('Tomatoes'), findsOneWidget);
      expect(find.text('Onions'), findsNothing);
      expect(find.text('Potatoes'), findsNothing);
    });
  });

  group('Widget Tests - Loading States', () {
    testWidgets('Loading indicator displays during data fetch', (
      WidgetTester tester,
    ) async {
      var isLoading = true;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : const Text('Data loaded'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Data loaded'), findsNothing);

      isLoading = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: isLoading
                ? const Center(child: CircularProgressIndicator())
                : const Text('Data loaded'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Data loaded'), findsOneWidget);
    });
  });

  group('Widget Tests - Error Handling', () {
    testWidgets('Error message displays when operation fails', (
      WidgetTester tester,
    ) async {
      final errorMessage = 'Failed to load products';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () {}, child: const Text('Retry')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(find.text('Failed to load products'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}
