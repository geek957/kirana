import 'dart:math';
import 'package:faker/faker.dart';
import 'package:kirana/models/product.dart';
import 'package:kirana/models/cart.dart';
import 'package:kirana/models/cart_item.dart';
import 'package:kirana/models/customer.dart';
import 'package:kirana/models/order.dart';
import 'package:kirana/models/order_item.dart';
import 'package:kirana/models/address.dart' as app_models;
import 'package:kirana/models/notification.dart';

/// Test data generators for property-based testing
class TestGenerators {
  static final _random = Random();
  static final _faker = Faker();

  /// Generate a random product
  static Product generateProduct({
    String? id,
    bool? isActive,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? _faker.guid.guid(),
      name: _faker.food.dish(),
      description: _faker.lorem.sentence(),
      price: _random.nextDouble() * 100 + 10,
      category: _faker.randomGenerator.element([
        'Fruits',
        'Vegetables',
        'Dairy',
        'Snacks',
        'Beverages',
      ]),
      unitSize: _faker.randomGenerator.element([
        '1kg',
        '500g',
        '1L',
        '500ml',
        '1pack',
      ]),
      stockQuantity: stockQuantity ?? _random.nextInt(100),
      imageUrl: 'https://example.com/image.jpg',
      isActive: isActive ?? true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a list of random products
  static List<Product> generateProducts(int count, {bool? isActive}) {
    return List.generate(count, (_) => generateProduct(isActive: isActive));
  }

  /// Generate a random cart item
  static CartItem generateCartItem({String? productId, int? quantity}) {
    return CartItem(
      productId: productId ?? _faker.guid.guid(),
      productName: _faker.food.dish(),
      price: _random.nextDouble() * 100 + 10,
      quantity: quantity ?? _random.nextInt(10) + 1,
      imageUrl: 'https://example.com/image.jpg',
    );
  }

  /// Generate a random cart
  static Cart generateCart({String? customerId, int? itemCount}) {
    final items = List.generate(
      itemCount ?? _random.nextInt(5) + 1,
      (_) => generateCartItem(),
    );
    final total = items.fold<double>(
      0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return Cart(
      customerId: customerId ?? _faker.guid.guid(),
      items: items,
      totalAmount: total,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a random address
  static app_models.Address generateAddress({
    String? customerId,
    bool? isDefault,
  }) {
    return app_models.Address(
      id: _faker.guid.guid(),
      customerId: customerId ?? _faker.guid.guid(),
      label: _faker.randomGenerator.element(['Home', 'Office', 'Other']),
      fullAddress: _faker.address.streetAddress(),
      landmark: _faker.address.neighborhood(),
      contactNumber: _faker.phoneNumber.us(),
      isDefault: isDefault ?? false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Generate a random customer
  static Customer generateCustomer({bool? isAdmin}) {
    return Customer(
      id: _faker.guid.guid(),
      phoneNumber: _faker.phoneNumber.us(),
      name: _faker.person.name(),
      defaultAddressId: _faker.guid.guid(),
      isAdmin: isAdmin ?? false,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
    );
  }

  /// Generate a random order item
  static OrderItem generateOrderItem() {
    final price = _random.nextDouble() * 100 + 10;
    final quantity = _random.nextInt(10) + 1;
    return OrderItem(
      productId: _faker.guid.guid(),
      productName: _faker.food.dish(),
      price: price,
      quantity: quantity,
      subtotal: price * quantity,
    );
  }

  /// Generate a random order
  static Order generateOrder({
    String? customerId,
    OrderStatus? status,
    int? itemCount,
  }) {
    final items = List.generate(
      itemCount ?? _random.nextInt(5) + 1,
      (_) => generateOrderItem(),
    );
    final total = items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final address = generateAddress(customerId: customerId);

    return Order(
      id: _faker.guid.guid(),
      customerId: customerId ?? _faker.guid.guid(),
      customerName: _faker.person.name(),
      customerPhone: _faker.phoneNumber.us(),
      items: items,
      totalAmount: total,
      addressId: address.id,
      deliveryAddress: address,
      status: status ?? OrderStatus.pending,
      paymentMethod: PaymentMethod.cashOnDelivery,
      createdAt: DateTime.now(),
      deliveredAt: null,
    );
  }

  /// Generate a random notification
  static AppNotification generateNotification({String? customerId}) {
    return AppNotification(
      id: _faker.guid.guid(),
      customerId: customerId ?? _faker.guid.guid(),
      orderId: _faker.guid.guid(),
      type: 'order_status_change',
      title: 'Order Update',
      message: _faker.lorem.sentence(),
      isRead: false,
      createdAt: DateTime.now(),
    );
  }

  /// Run a property test with multiple iterations
  static Future<void> runPropertyTest({
    required String description,
    required Future<void> Function() test,
    int iterations = 100,
  }) async {
    for (var i = 0; i < iterations; i++) {
      try {
        await test();
      } catch (e) {
        throw Exception(
          'Property test failed on iteration ${i + 1}/$iterations: $e',
        );
      }
    }
  }
}
