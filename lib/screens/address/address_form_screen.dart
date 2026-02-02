import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../../models/address.dart';
import '../../providers/address_provider.dart';
import '../../providers/auth_provider.dart';

class AddressFormScreen extends StatefulWidget {
  final Address? address;

  const AddressFormScreen({super.key, this.address});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _fullAddressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _contactNumberController = TextEditingController();
  bool _isDefault = false;
  bool _isLoading = false;

  bool get isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _labelController.text = widget.address!.label;
      _fullAddressController.text = widget.address!.fullAddress;
      _landmarkController.text = widget.address!.landmark ?? '';
      _contactNumberController.text = widget.address!.contactNumber;
      _isDefault = widget.address!.isDefault;
    } else {
      // Pre-populate contact number with customer's phone number for new addresses
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      if (authProvider.currentCustomer != null) {
        _contactNumberController.text = authProvider.currentCustomer!.phoneNumber;
      }
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _fullAddressController.dispose();
    _landmarkController.dispose();
    _contactNumberController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateLabel(String? value) {
    final error = _validateRequired(value, 'Label');
    if (error != null) return error;

    if (value!.length < 2 || value.length > 50) {
      return 'Label must be between 2 and 50 characters';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    final error = _validateRequired(value, 'Address');
    if (error != null) return error;

    if (value!.length < 10 || value.length > 200) {
      return 'Address must be between 10 and 200 characters';
    }
    return null;
  }

  String? _validateContactNumber(String? value) {
    final error = _validateRequired(value, 'Contact number');
    if (error != null) return error;

    // Remove any spaces or special characters
    final cleaned = value!.replaceAll(RegExp(r'[^\d+]'), '');

    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid contact number';
    }
    return null;
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final addressProvider = Provider.of<AddressProvider>(
      context,
      listen: false,
    );

    if (authProvider.firebaseUser == null) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final customerId = authProvider.firebaseUser!.uid;
    final now = DateTime.now();

    final address = Address(
      id: isEditing ? widget.address!.id : const Uuid().v4(),
      customerId: customerId,
      label: _labelController.text.trim(),
      fullAddress: _fullAddressController.text.trim(),
      landmark: _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      isDefault: _isDefault,
      createdAt: isEditing ? widget.address!.createdAt : now,
      updatedAt: now,
    );

    bool success;
    if (isEditing) {
      success = await addressProvider.updateAddress(address.id, address);
    } else {
      success = await addressProvider.addAddress(address);
    }

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? 'Address updated successfully'
                  : 'Address added successfully',
            ),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              addressProvider.error ??
                  (isEditing
                      ? 'Failed to update address'
                      : 'Failed to add address'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add Address'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Label field
            TextFormField(
              controller: _labelController,
              decoration: const InputDecoration(
                labelText: 'Label *',
                hintText: 'e.g., Home, Office, Mom\'s House',
                prefixIcon: Icon(Icons.label),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              validator: _validateLabel,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Full address field
            TextFormField(
              controller: _fullAddressController,
              decoration: const InputDecoration(
                labelText: 'Full Address *',
                hintText: 'House/Flat No., Street, Area, City, State, PIN',
                prefixIcon: Icon(Icons.home),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.words,
              validator: _validateAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Landmark field (optional)
            TextFormField(
              controller: _landmarkController,
              decoration: const InputDecoration(
                labelText: 'Landmark (Optional)',
                hintText: 'e.g., Near City Mall, Behind School',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Contact number field
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(
                labelText: 'Contact Number *',
                hintText: '+91 9876543210',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
              ],
              validator: _validateContactNumber,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),

            // Default address toggle
            Card(
              child: SwitchListTile(
                title: const Text('Set as default address'),
                subtitle: const Text(
                  'This address will be selected by default during checkout',
                ),
                value: _isDefault,
                onChanged: _isLoading
                    ? null
                    : (value) {
                        setState(() {
                          _isDefault = value;
                        });
                      },
                secondary: const Icon(Icons.check_circle),
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveAddress,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Address' : 'Save Address',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 16),

            // Help text
            Text(
              '* Required fields',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
