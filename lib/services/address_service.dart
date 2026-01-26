import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/address.dart';
import 'encryption_service.dart';
import 'authorization_service.dart';

class AddressService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();
  final AuthorizationService _authService = AuthorizationService();
  final String _collectionName = 'addresses';

  /// Add a new address for a customer
  Future<Address> addAddress(Address address) async {
    try {
      // Verify user can add address for this customer
      await _authService.requireCustomerDataAccess(address.customerId);

      // Encrypt sensitive fields before storage
      final encryptedFullAddress = await _encryptionService.encryptAddress(
        address.fullAddress,
      );
      final encryptedContactNumber = await _encryptionService
          .encryptPhoneNumber(address.contactNumber);

      final encryptedAddress = address.copyWith(
        fullAddress: encryptedFullAddress,
        contactNumber: encryptedContactNumber,
      );

      final docRef = _firestore.collection(_collectionName).doc(address.id);
      await docRef.set(encryptedAddress.toJson());

      // Return original address with unencrypted data
      return address;
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  /// Get all addresses for a customer
  Future<List<Address>> getCustomerAddresses(String customerId) async {
    try {
      // Verify user can access this customer's addresses
      await _authService.requireCustomerDataAccess(customerId);

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();

      final addresses = <Address>[];
      for (var doc in snapshot.docs) {
        final address = Address.fromJson(doc.data());
        // Decrypt sensitive fields
        final decryptedFullAddress = await _encryptionService.decryptAddress(
          address.fullAddress,
        );
        final decryptedContactNumber = await _encryptionService
            .decryptPhoneNumber(address.contactNumber);
        addresses.add(
          address.copyWith(
            fullAddress: decryptedFullAddress,
            contactNumber: decryptedContactNumber,
          ),
        );
      }

      return addresses;
    } catch (e) {
      throw Exception('Failed to fetch customer addresses: $e');
    }
  }

  /// Get a single address by ID
  Future<Address?> getAddressById(String addressId) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(addressId)
          .get();

      if (!doc.exists) {
        return null;
      }

      final address = Address.fromJson(doc.data() as Map<String, dynamic>);
      // Decrypt sensitive fields
      final decryptedFullAddress = await _encryptionService.decryptAddress(
        address.fullAddress,
      );
      final decryptedContactNumber = await _encryptionService
          .decryptPhoneNumber(address.contactNumber);

      return address.copyWith(
        fullAddress: decryptedFullAddress,
        contactNumber: decryptedContactNumber,
      );
    } catch (e) {
      throw Exception('Failed to fetch address: $e');
    }
  }

  /// Update an existing address
  Future<void> updateAddress(String addressId, Address address) async {
    try {
      // Encrypt sensitive fields before storage
      final encryptedFullAddress = await _encryptionService.encryptAddress(
        address.fullAddress,
      );
      final encryptedContactNumber = await _encryptionService
          .encryptPhoneNumber(address.contactNumber);

      final encryptedAddress = address.copyWith(
        fullAddress: encryptedFullAddress,
        contactNumber: encryptedContactNumber,
      );

      await _firestore
          .collection(_collectionName)
          .doc(addressId)
          .update(encryptedAddress.toJson());
    } catch (e) {
      throw Exception('Failed to update address: $e');
    }
  }

  /// Delete an address (with order check)
  /// Checks if the address is used in any existing orders before deletion
  Future<void> deleteAddress(String addressId) async {
    try {
      // Check if address is used in any orders
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('addressId', isEqualTo: addressId)
          .limit(1)
          .get();

      if (ordersSnapshot.docs.isNotEmpty) {
        throw Exception('Cannot delete address: it is used in existing orders');
      }

      await _firestore.collection(_collectionName).doc(addressId).delete();
    } catch (e) {
      throw Exception('Failed to delete address: $e');
    }
  }

  /// Set an address as the default for a customer
  /// Ensures only one address is marked as default per customer
  Future<void> setDefaultAddress(String customerId, String addressId) async {
    try {
      // Use a batch to ensure atomicity
      final batch = _firestore.batch();

      // First, unset all default addresses for this customer
      final customerAddresses = await getCustomerAddresses(customerId);
      for (var address in customerAddresses) {
        if (address.isDefault) {
          final docRef = _firestore.collection(_collectionName).doc(address.id);
          batch.update(docRef, {
            'isDefault': false,
            'updatedAt': DateTime.now().toIso8601String(),
          });
        }
      }

      // Then set the new default address
      final newDefaultRef = _firestore
          .collection(_collectionName)
          .doc(addressId);
      batch.update(newDefaultRef, {
        'isDefault': true,
        'updatedAt': DateTime.now().toIso8601String(),
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to set default address: $e');
    }
  }

  /// Get the default address for a customer
  Future<Address?> getDefaultAddress(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('customerId', isEqualTo: customerId)
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      final address = Address.fromJson(snapshot.docs.first.data());
      // Decrypt sensitive fields
      final decryptedFullAddress = await _encryptionService.decryptAddress(
        address.fullAddress,
      );
      final decryptedContactNumber = await _encryptionService
          .decryptPhoneNumber(address.contactNumber);

      return address.copyWith(
        fullAddress: decryptedFullAddress,
        contactNumber: decryptedContactNumber,
      );
    } catch (e) {
      throw Exception('Failed to fetch default address: $e');
    }
  }

  /// Stream of addresses for real-time updates
  Stream<List<Address>> getCustomerAddressesStream(String customerId) {
    return _firestore
        .collection(_collectionName)
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final addresses = <Address>[];
          for (var doc in snapshot.docs) {
            final address = Address.fromJson(doc.data());
            // Decrypt sensitive fields
            final decryptedFullAddress = await _encryptionService
                .decryptAddress(address.fullAddress);
            final decryptedContactNumber = await _encryptionService
                .decryptPhoneNumber(address.contactNumber);
            addresses.add(
              address.copyWith(
                fullAddress: decryptedFullAddress,
                contactNumber: decryptedContactNumber,
              ),
            );
          }
          return addresses;
        });
  }
}
