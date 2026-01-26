import 'package:flutter/foundation.dart';
import '../models/address.dart';
import '../services/address_service.dart';

class AddressProvider with ChangeNotifier {
  final AddressService _addressService = AddressService();

  List<Address> _addresses = [];
  Address? _selectedAddress;
  Address? _defaultAddress;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Address> get addresses => _addresses;
  Address? get selectedAddress => _selectedAddress;
  Address? get defaultAddress => _defaultAddress;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Load all addresses for a customer
  Future<void> loadAddresses(String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _addresses = await _addressService.getCustomerAddresses(customerId);

      // Find and set the default address
      try {
        _defaultAddress = _addresses.firstWhere((address) => address.isDefault);
      } catch (e) {
        // No default address found, use first address if available
        _defaultAddress = _addresses.isNotEmpty ? _addresses.first : null;
      }
    } catch (e) {
      _error = 'Failed to load addresses: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Set up real-time listener for addresses
  void listenToAddresses(String customerId) {
    _addressService
        .getCustomerAddressesStream(customerId)
        .listen(
          (addresses) {
            _addresses = addresses;

            // Update default address
            try {
              _defaultAddress = addresses.firstWhere(
                (address) => address.isDefault,
              );
            } catch (e) {
              // No default address found, use first address if available
              _defaultAddress = addresses.isNotEmpty ? addresses.first : null;
            }

            notifyListeners();
          },
          onError: (error) {
            _error = 'Failed to listen to addresses: $error';
            notifyListeners();
          },
        );
  }

  /// Add a new address
  Future<bool> addAddress(Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressService.addAddress(address);

      // Reload addresses to get updated list
      await loadAddresses(address.customerId);

      return true;
    } catch (e) {
      _error = 'Failed to add address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Update an existing address
  Future<bool> updateAddress(String addressId, Address address) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressService.updateAddress(addressId, address);

      // Reload addresses to get updated list
      await loadAddresses(address.customerId);

      return true;
    } catch (e) {
      _error = 'Failed to update address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete an address
  Future<bool> deleteAddress(String addressId, String customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressService.deleteAddress(addressId);

      // Reload addresses to get updated list
      await loadAddresses(customerId);

      return true;
    } catch (e) {
      _error = 'Failed to delete address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Set an address as default
  Future<bool> setDefaultAddress(String customerId, String addressId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _addressService.setDefaultAddress(customerId, addressId);

      // Reload addresses to get updated list
      await loadAddresses(customerId);

      return true;
    } catch (e) {
      _error = 'Failed to set default address: $e';
      notifyListeners();
      return false;
    }
  }

  /// Get a single address by ID
  Future<Address?> getAddressById(String addressId) async {
    try {
      return await _addressService.getAddressById(addressId);
    } catch (e) {
      _error = 'Failed to fetch address: $e';
      notifyListeners();
      return null;
    }
  }

  /// Get the default address for a customer
  Future<Address?> getDefaultAddress(String customerId) async {
    try {
      final address = await _addressService.getDefaultAddress(customerId);
      _defaultAddress = address;
      notifyListeners();
      return address;
    } catch (e) {
      _error = 'Failed to fetch default address: $e';
      notifyListeners();
      return null;
    }
  }

  /// Select an address (for checkout, etc.)
  void selectAddress(Address address) {
    _selectedAddress = address;
    notifyListeners();
  }

  /// Clear selected address
  void clearSelectedAddress() {
    _selectedAddress = null;
    notifyListeners();
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data (for logout)
  void clear() {
    _addresses = [];
    _selectedAddress = null;
    _defaultAddress = null;
    _error = null;
    notifyListeners();
  }
}
