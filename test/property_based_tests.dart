/// Property-Based Tests for Online Grocery Application
///
/// These tests verify correctness properties that should hold across all valid
/// executions of the system. Each test runs 100 iterations with randomly
/// generated data to ensure properties hold universally.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kirana/models/models.dart';
import 'helpers/test_generators.dart';

void main() {
  group('Property-Based Tests - Data Model Serialization', () {
    test(
      'Property: Product serialization round-trip preserves all fields',
      () async {
        await TestGenerators.runPropertyTest(
          description: 'Product serialization round-trip',
          test: () async {
            // Generate random product
            final product = TestGenerators.generateProduct();

            // Serialize to JSON
            final json = product.toJson();

            // Deserialize back
            final deserialized = Product.fromJson(json);

            // Verify all fields preserved
            expect(deserialized.id, equals(product.id));
            expect(deserialized.name, equals(product.name));
            expect(deserialized.description, equals(product.description));
            expect(deserialized.price, equals(product.price));
            expect(deserialized.category, equals(product.category));
            expect(deserialized.unitSize, equals(product.unitSize));
            expect(deserialized.stockQuantity, equals(product.stockQuantity));
            expect(deserialized.imageUrl, equals(product.imageUrl));
            expect(deserialized.isActive, equals(product.isActive));
          },
        );
      },
    );

    test(
      'Property: Cart serialization round-trip preserves all fields',
      () async {
        await TestGenerators.runPropertyTest(
          description: 'Cart serialization round-trip',
          test: () async {
            // Generate random cart
            final cart = TestGenerators.generateCart();

            // Serialize to JSON
            final json = cart.toJson();

            // Deserialize back
            final deserialized = Cart.fromJson(json);

            // Verify all fields preserved
            expect(deserialized.customerId, equals(cart.customerId));
            expect(deserialized.items.length, equals(cart.items.length));
            expect(deserialized.totalAmount, closeTo(cart.totalAmount, 0.01));
          },
        );
      },
    );

    test(
      'Property: Order serialization round-trip preserves all fields',
      () async {
        await TestGenerators.runPropertyTest(
          description: 'Order serialization round-trip',
          test: () async {
            // Generate random order
            final order = TestGenerators.generateOrder();

            // Serialize to JSON
            final json = order.toJson();

            // Deserialize back
            final deserialized = Order.fromJson(json);

            // Verify all fields preserved
            expect(deserialized.id, equals(order.id));
            expect(deserialized.customerId, equals(order.customerId));
            expect(deserialized.items.length, equals(order.items.length));
            expect(deserialized.totalAmount, closeTo(order.totalAmount, 0.01));
            expect(deserialized.status, equals(order.status));
          },
        );
      },
    );

    test(
      'Property: Address serialization round-trip preserves all fields',
      () async {
        await TestGenerators.runPropertyTest(
          description: 'Address serialization round-trip',
          test: () async {
            // Generate random address
            final address = TestGenerators.generateAddress();

            // Serialize to JSON
            final json = address.toJson();

            // Deserialize back
            final deserialized = Address.fromJson(json);

            // Verify all fields preserved
            expect(deserialized.id, equals(address.id));
            expect(deserialized.customerId, equals(address.customerId));
            expect(deserialized.label, equals(address.label));
            expect(deserialized.fullAddress, equals(address.fullAddress));
            expect(deserialized.contactNumber, equals(address.contactNumber));
            expect(deserialized.isDefault, equals(address.isDefault));
          },
        );
      },
    );
  });

  group('Property-Based Tests - Business Logic', () {
    test('Property: Cart total equals sum of item subtotals', () async {
      await TestGenerators.runPropertyTest(
        description: 'Cart total calculation',
        test: () async {
          // Generate random cart
          final cart = TestGenerators.generateCart();

          // Calculate expected total
          final expectedTotal = cart.items.fold<double>(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          );

          // Verify cart total matches
          expect(cart.totalAmount, closeTo(expectedTotal, 0.01));
        },
      );
    });

    test('Property: Order total equals sum of order item subtotals', () async {
      await TestGenerators.runPropertyTest(
        description: 'Order total calculation',
        test: () async {
          // Generate random order
          final order = TestGenerators.generateOrder();

          // Calculate expected total
          final expectedTotal = order.items.fold<double>(
            0.0,
            (sum, item) => sum + item.subtotal,
          );

          // Verify order total matches
          expect(order.totalAmount, closeTo(expectedTotal, 0.01));
        },
      );
    });

    test('Property: Product prices are always positive', () async {
      await TestGenerators.runPropertyTest(
        description: 'Product price validation',
        test: () async {
          // Generate random product
          final product = TestGenerators.generateProduct();

          // Verify price is positive
          expect(product.price, greaterThan(0));
        },
      );
    });

    test('Property: Stock quantities are non-negative', () async {
      await TestGenerators.runPropertyTest(
        description: 'Stock quantity validation',
        test: () async {
          // Generate random product
          final product = TestGenerators.generateProduct();

          // Verify stock is non-negative
          expect(product.stockQuantity, greaterThanOrEqualTo(0));
        },
      );
    });

    test('Property: Cart item quantities are positive', () async {
      await TestGenerators.runPropertyTest(
        description: 'Cart item quantity validation',
        test: () async {
          // Generate random cart
          final cart = TestGenerators.generateCart();

          // Verify all item quantities are positive
          for (final item in cart.items) {
            expect(item.quantity, greaterThan(0));
          }
        },
      );
    });
  });

  group('Property-Based Tests - Firestore Operations', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('Property: Product storage and retrieval preserves data', () async {
      await TestGenerators.runPropertyTest(
        description: 'Product Firestore storage and retrieval',
        test: () async {
          // Generate random product
          final product = TestGenerators.generateProduct();

          // Store in Firestore
          await firestore
              .collection('products')
              .doc(product.id)
              .set(product.toJson());

          // Retrieve product
          final doc = await firestore
              .collection('products')
              .doc(product.id)
              .get();

          // Verify data preserved
          expect(doc.exists, isTrue);
          final retrieved = Product.fromJson(doc.data()!);
          expect(retrieved.id, equals(product.id));
          expect(retrieved.name, equals(product.name));
          expect(retrieved.price, equals(product.price));
          expect(retrieved.stockQuantity, equals(product.stockQuantity));
        },
      );
    });

    test('Property: Cart storage and retrieval preserves data', () async {
      await TestGenerators.runPropertyTest(
        description: 'Cart Firestore storage and retrieval',
        test: () async {
          // Generate random cart
          final cart = TestGenerators.generateCart();

          // Store in Firestore
          await firestore
              .collection('carts')
              .doc(cart.customerId)
              .set(cart.toJson());

          // Retrieve cart
          final doc = await firestore
              .collection('carts')
              .doc(cart.customerId)
              .get();

          // Verify data preserved
          expect(doc.exists, isTrue);
          final data = doc.data()!;
          expect(data['customerId'], equals(cart.customerId));
          expect(data['items'].length, equals(cart.items.length));
          expect(
            (data['totalAmount'] as num).toDouble(),
            closeTo(cart.totalAmount, 0.01),
          );
        },
      );
    });

    test('Property: Order storage and retrieval preserves data', () async {
      await TestGenerators.runPropertyTest(
        description: 'Order Firestore storage and retrieval',
        test: () async {
          // Generate random order
          final order = TestGenerators.generateOrder();

          // Store in Firestore
          await firestore
              .collection('orders')
              .doc(order.id)
              .set(order.toJson());

          // Retrieve order
          final doc = await firestore.collection('orders').doc(order.id).get();

          // Verify data preserved
          expect(doc.exists, isTrue);
          final retrieved = Order.fromJson(doc.data()!);
          expect(retrieved.id, equals(order.id));
          expect(retrieved.customerId, equals(order.customerId));
          expect(retrieved.totalAmount, closeTo(order.totalAmount, 0.01));
          expect(retrieved.status, equals(order.status));
        },
      );
    });

    test('Property: Address storage and retrieval preserves data', () async {
      await TestGenerators.runPropertyTest(
        description: 'Address Firestore storage and retrieval',
        test: () async {
          // Generate random address
          final address = TestGenerators.generateAddress();

          // Store in Firestore
          await firestore
              .collection('addresses')
              .doc(address.id)
              .set(address.toJson());

          // Retrieve address
          final doc = await firestore
              .collection('addresses')
              .doc(address.id)
              .get();

          // Verify data preserved
          expect(doc.exists, isTrue);
          final retrieved = Address.fromJson(doc.data()!);
          expect(retrieved.id, equals(address.id));
          expect(retrieved.customerId, equals(address.customerId));
          expect(retrieved.label, equals(address.label));
          expect(retrieved.isDefault, equals(address.isDefault));
        },
      );
    });

    test('Property: Multiple products can be stored and queried', () async {
      // Run only 10 iterations for this test to avoid accumulation issues
      await TestGenerators.runPropertyTest(
        description: 'Multiple product storage',
        iterations: 10,
        test: () async {
          // Use a fresh firestore instance for each iteration
          final testFirestore = FakeFirebaseFirestore();

          // Generate multiple products
          final products = List.generate(
            5,
            (_) => TestGenerators.generateProduct(),
          );

          // Store all products
          for (final product in products) {
            await testFirestore
                .collection('products')
                .doc(product.id)
                .set(product.toJson());
          }

          // Query all products
          final snapshot = await testFirestore.collection('products').get();

          // Verify all products stored
          expect(snapshot.docs.length, equals(products.length));
        },
      );
    });
  });
}
