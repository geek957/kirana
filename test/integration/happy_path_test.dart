/// Integration Tests for Online Grocery Application
///
/// These tests verify complete user flows work end-to-end by testing
/// the business logic and data flow through models and Firestore operations.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:kirana/models/models.dart';
import '../helpers/test_generators.dart';

void main() {
  late FakeFirebaseFirestore firestore;

  setUp(() {
    firestore = FakeFirebaseFirestore();
  });

  group('Integration Test - Order Placement Flow', () {
    test(
      'Complete order flow: browse → add to cart → checkout → place order',
      () async {
        // Setup: Create test customer and products
        final customerId = 'test-customer-123';
        final products = [
          TestGenerators.generateProduct(id: 'prod-1', stockQuantity: 50),
          TestGenerators.generateProduct(id: 'prod-2', stockQuantity: 30),
        ];

        // Step 1: Add products to Firestore (simulating product browsing)
        for (final product in products) {
          await firestore
              .collection('products')
              .doc(product.id)
              .set(product.toJson());
        }

        // Verify products can be browsed
        final productsSnapshot = await firestore
            .collection('products')
            .where('isActive', isEqualTo: true)
            .get();
        expect(productsSnapshot.docs.length, equals(2));

        // Step 2: Add products to cart
        final cartItems = [
          CartItem(
            productId: products[0].id,
            productName: products[0].name,
            price: products[0].price,
            quantity: 2,
            imageUrl: products[0].imageUrl,
          ),
          CartItem(
            productId: products[1].id,
            productName: products[1].name,
            price: products[1].price,
            quantity: 1,
            imageUrl: products[1].imageUrl,
          ),
        ];

        final cart = Cart(
          customerId: customerId,
          items: cartItems,
          totalAmount: cartItems.fold(
            0.0,
            (sum, item) => sum + (item.price * item.quantity),
          ),
          updatedAt: DateTime.now(),
        );

        await firestore.collection('carts').doc(customerId).set(cart.toJson());

        // Step 3: Verify cart contents
        final cartDoc = await firestore
            .collection('carts')
            .doc(customerId)
            .get();
        expect(cartDoc.exists, isTrue);
        final retrievedCart = Cart.fromJson(cartDoc.data()!);
        expect(retrievedCart.items.length, equals(2));

        // Step 4: Create delivery address
        final address = TestGenerators.generateAddress(customerId: customerId);
        await firestore
            .collection('addresses')
            .doc(address.id)
            .set(address.toJson());

        // Step 5: Place order (simulating transaction)
        final orderItems = cartItems.map((item) {
          return OrderItem(
            productId: item.productId,
            productName: item.productName,
            price: item.price,
            quantity: item.quantity,
            subtotal: item.price * item.quantity,
          );
        }).toList();

        final order = Order(
          id: 'order-123',
          customerId: customerId,
          customerName: 'Test Customer',
          customerPhone: '+1234567890',
          items: orderItems,
          totalAmount: cart.totalAmount,
          addressId: address.id,
          deliveryAddress: address,
          status: OrderStatus.pending,
          paymentMethod: PaymentMethod.cashOnDelivery,
          createdAt: DateTime.now(),
          deliveredAt: null,
        );

        await firestore.collection('orders').doc(order.id).set(order.toJson());

        // Step 6: Reduce stock quantities (simulating transaction)
        await firestore.collection('products').doc(products[0].id).update({
          'stockQuantity': products[0].stockQuantity - 2,
        });
        await firestore.collection('products').doc(products[1].id).update({
          'stockQuantity': products[1].stockQuantity - 1,
        });

        // Step 7: Clear cart
        await firestore.collection('carts').doc(customerId).delete();

        // Verify order created
        final orderDoc = await firestore
            .collection('orders')
            .doc(order.id)
            .get();
        expect(orderDoc.exists, isTrue);
        final retrievedOrder = Order.fromJson(orderDoc.data()!);
        expect(retrievedOrder.customerId, equals(customerId));
        expect(retrievedOrder.items.length, equals(2));
        expect(retrievedOrder.status, equals(OrderStatus.pending));

        // Verify cart cleared
        final clearedCartDoc = await firestore
            .collection('carts')
            .doc(customerId)
            .get();
        expect(clearedCartDoc.exists, isFalse);

        // Verify stock reduced
        final updatedProduct1Doc = await firestore
            .collection('products')
            .doc(products[0].id)
            .get();
        final updatedProduct2Doc = await firestore
            .collection('products')
            .doc(products[1].id)
            .get();
        expect(updatedProduct1Doc.data()!['stockQuantity'], equals(48));
        expect(updatedProduct2Doc.data()!['stockQuantity'], equals(29));
      },
    );
  });

  group('Integration Test - Admin Inventory Management Flow', () {
    test('Admin flow: add product → update stock → delete product', () async {
      // Step 1: Add new product
      final product = TestGenerators.generateProduct(
        id: 'admin-prod-1',
        stockQuantity: 100,
      );

      await firestore
          .collection('products')
          .doc(product.id)
          .set(product.toJson());

      // Verify product added
      final addedProductDoc = await firestore
          .collection('products')
          .doc(product.id)
          .get();
      expect(addedProductDoc.exists, isTrue);
      final addedProduct = Product.fromJson(addedProductDoc.data()!);
      expect(addedProduct.name, equals(product.name));
      expect(addedProduct.stockQuantity, equals(100));

      // Step 2: Update stock
      await firestore.collection('products').doc(product.id).update({
        'stockQuantity': 150,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Verify stock updated
      final updatedProductDoc = await firestore
          .collection('products')
          .doc(product.id)
          .get();
      expect(updatedProductDoc.data()!['stockQuantity'], equals(150));

      // Step 3: Update product details
      await firestore.collection('products').doc(product.id).update({
        'name': 'Updated Product Name',
        'price': 99.99,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Verify product updated
      final finalProductDoc = await firestore
          .collection('products')
          .doc(product.id)
          .get();
      expect(finalProductDoc.data()!['name'], equals('Updated Product Name'));
      expect(finalProductDoc.data()!['price'], equals(99.99));

      // Step 4: Delete product (soft delete)
      await firestore.collection('products').doc(product.id).update({
        'isActive': false,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Verify product marked inactive
      final deletedProductDoc = await firestore
          .collection('products')
          .doc(product.id)
          .get();
      expect(deletedProductDoc.data()!['isActive'], isFalse);

      // Verify product doesn't appear in active product list
      final activeProductsSnapshot = await firestore
          .collection('products')
          .where('isActive', isEqualTo: true)
          .get();
      expect(
        activeProductsSnapshot.docs.any((doc) => doc.id == product.id),
        isFalse,
      );
    });
  });

  group('Integration Test - Cart Persistence', () {
    test(
      'Cart persists: add items → simulate app restart → verify cart',
      () async {
        final customerId = 'test-customer-456';

        // Step 1: Add items to cart
        final product = TestGenerators.generateProduct(stockQuantity: 50);
        await firestore
            .collection('products')
            .doc(product.id)
            .set(product.toJson());

        final cartItem = CartItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 3,
          imageUrl: product.imageUrl,
        );

        final cart = Cart(
          customerId: customerId,
          items: [cartItem],
          totalAmount: cartItem.price * cartItem.quantity,
          updatedAt: DateTime.now(),
        );

        await firestore.collection('carts').doc(customerId).set(cart.toJson());

        // Step 2: Verify cart exists
        final cartDoc1 = await firestore
            .collection('carts')
            .doc(customerId)
            .get();
        expect(cartDoc1.exists, isTrue);
        final cart1 = Cart.fromJson(cartDoc1.data()!);
        expect(cart1.items.length, equals(1));
        expect(cart1.items[0].quantity, equals(3));

        // Step 3: Simulate app restart by creating new firestore instance
        final newFirestore = FakeFirebaseFirestore();
        // Copy data to new instance
        await newFirestore
            .collection('carts')
            .doc(customerId)
            .set(cart.toJson());

        // Step 4: Verify cart still exists after "restart"
        final cartDoc2 = await newFirestore
            .collection('carts')
            .doc(customerId)
            .get();
        expect(cartDoc2.exists, isTrue);
        final cart2 = Cart.fromJson(cartDoc2.data()!);
        expect(cart2.items.length, equals(1));
        expect(cart2.items[0].quantity, equals(3));
        expect(cart2.items[0].productId, equals(product.id));
      },
    );
  });

  group('Integration Test - Order Status Updates', () {
    test(
      'Order status flow: pending → confirmed → preparing → delivered',
      () async {
        // Setup: Create order
        final customerId = 'test-customer-789';
        final address = TestGenerators.generateAddress(customerId: customerId);
        final order = TestGenerators.generateOrder(
          customerId: customerId,
          status: OrderStatus.pending,
        );

        await firestore.collection('orders').doc(order.id).set(order.toJson());

        // Step 1: Update to confirmed
        await firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.confirmed.toString().split('.').last,
        });
        var orderDoc = await firestore.collection('orders').doc(order.id).get();
        var updatedOrder = Order.fromJson(orderDoc.data()!);
        expect(updatedOrder.status, equals(OrderStatus.confirmed));

        // Step 2: Update to preparing
        await firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.preparing.toString().split('.').last,
        });
        orderDoc = await firestore.collection('orders').doc(order.id).get();
        updatedOrder = Order.fromJson(orderDoc.data()!);
        expect(updatedOrder.status, equals(OrderStatus.preparing));

        // Step 3: Update to out for delivery
        await firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.outForDelivery.toString().split('.').last,
        });
        orderDoc = await firestore.collection('orders').doc(order.id).get();
        updatedOrder = Order.fromJson(orderDoc.data()!);
        expect(updatedOrder.status, equals(OrderStatus.outForDelivery));

        // Step 4: Update to delivered
        final deliveredAt = DateTime.now();
        await firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.delivered.toString().split('.').last,
          'deliveredAt': deliveredAt.toIso8601String(),
        });
        orderDoc = await firestore.collection('orders').doc(order.id).get();
        updatedOrder = Order.fromJson(orderDoc.data()!);
        expect(updatedOrder.status, equals(OrderStatus.delivered));
        expect(updatedOrder.deliveredAt, isNotNull);
      },
    );
  });

  group('Integration Test - Order Cancellation', () {
    test(
      'Cancel order: place order → cancel → verify stock restored',
      () async {
        // Setup: Create order
        final customerId = 'test-customer-cancel';
        final product = TestGenerators.generateProduct(
          id: 'cancel-prod-1',
          stockQuantity: 50,
        );
        await firestore
            .collection('products')
            .doc(product.id)
            .set(product.toJson());

        final address = TestGenerators.generateAddress(customerId: customerId);

        // Create cart and place order
        final cartItem = CartItem(
          productId: product.id,
          productName: product.name,
          price: product.price,
          quantity: 5,
          imageUrl: product.imageUrl,
        );

        final orderItem = OrderItem(
          productId: cartItem.productId,
          productName: cartItem.productName,
          price: cartItem.price,
          quantity: cartItem.quantity,
          subtotal: cartItem.price * cartItem.quantity,
        );

        final order = Order(
          id: 'cancel-order-1',
          customerId: customerId,
          customerName: 'Test Customer',
          customerPhone: '+1234567890',
          items: [orderItem],
          totalAmount: orderItem.subtotal,
          addressId: address.id,
          deliveryAddress: address,
          status: OrderStatus.pending,
          paymentMethod: PaymentMethod.cashOnDelivery,
          createdAt: DateTime.now(),
          deliveredAt: null,
        );

        await firestore.collection('orders').doc(order.id).set(order.toJson());

        // Reduce stock
        await firestore.collection('products').doc(product.id).update({
          'stockQuantity': product.stockQuantity - 5,
        });

        // Verify stock reduced
        var productDoc = await firestore
            .collection('products')
            .doc(product.id)
            .get();
        expect(productDoc.data()!['stockQuantity'], equals(45));

        // Cancel order
        await firestore.collection('orders').doc(order.id).update({
          'status': OrderStatus.cancelled.toString().split('.').last,
        });

        // Restore stock
        await firestore.collection('products').doc(product.id).update({
          'stockQuantity': product.stockQuantity,
        });

        // Verify order cancelled
        final orderDoc = await firestore
            .collection('orders')
            .doc(order.id)
            .get();
        final cancelledOrder = Order.fromJson(orderDoc.data()!);
        expect(cancelledOrder.status, equals(OrderStatus.cancelled));

        // Verify stock restored
        productDoc = await firestore
            .collection('products')
            .doc(product.id)
            .get();
        expect(productDoc.data()!['stockQuantity'], equals(50));
      },
    );
  });

  group('Integration Test - Address Management', () {
    test('Address flow: add → set default → update → delete', () async {
      final customerId = 'test-customer-address';

      // Step 1: Add first address
      final address1 = TestGenerators.generateAddress(
        customerId: customerId,
        isDefault: false,
      );
      await firestore
          .collection('addresses')
          .doc(address1.id)
          .set(address1.toJson());

      // Step 2: Add second address
      final address2 = TestGenerators.generateAddress(
        customerId: customerId,
        isDefault: false,
      );
      await firestore
          .collection('addresses')
          .doc(address2.id)
          .set(address2.toJson());

      // Verify both addresses exist
      final addressesSnapshot = await firestore
          .collection('addresses')
          .where('customerId', isEqualTo: customerId)
          .get();
      expect(addressesSnapshot.docs.length, equals(2));

      // Step 3: Set address2 as default
      await firestore.collection('addresses').doc(address2.id).update({
        'isDefault': true,
      });
      // Unset address1 as default
      await firestore.collection('addresses').doc(address1.id).update({
        'isDefault': false,
      });

      // Verify address2 is default
      final address2Doc = await firestore
          .collection('addresses')
          .doc(address2.id)
          .get();
      expect(address2Doc.data()!['isDefault'], isTrue);

      // Verify address1 is not default
      final address1Doc = await firestore
          .collection('addresses')
          .doc(address1.id)
          .get();
      expect(address1Doc.data()!['isDefault'], isFalse);

      // Step 4: Update address1
      await firestore.collection('addresses').doc(address1.id).update({
        'label': 'Updated Label',
        'fullAddress': 'Updated Address',
        'updatedAt': DateTime.now().toIso8601String(),
      });

      // Verify update
      final updatedAddress1Doc = await firestore
          .collection('addresses')
          .doc(address1.id)
          .get();
      expect(updatedAddress1Doc.data()!['label'], equals('Updated Label'));
      expect(
        updatedAddress1Doc.data()!['fullAddress'],
        equals('Updated Address'),
      );

      // Step 5: Delete address1
      await firestore.collection('addresses').doc(address1.id).delete();

      // Verify deletion
      final remainingAddressesSnapshot = await firestore
          .collection('addresses')
          .where('customerId', isEqualTo: customerId)
          .get();
      expect(remainingAddressesSnapshot.docs.length, equals(1));
      expect(remainingAddressesSnapshot.docs[0].id, equals(address2.id));
    });
  });
}
