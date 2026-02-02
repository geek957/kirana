import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/app_config.dart';
import '../../services/config_service.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/admin_drawer.dart';
import '../../widgets/loading_indicator.dart';
import '../../utils/routes.dart';

/// Screen for managing app configuration settings
/// Allows admin to configure delivery charges, cart limits, and order capacity thresholds
class AppConfigScreen extends StatefulWidget {
  const AppConfigScreen({super.key});

  @override
  State<AppConfigScreen> createState() => _AppConfigScreenState();
}

class _AppConfigScreenState extends State<AppConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _configService = ConfigService();

  // Form controllers
  final _deliveryChargeController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();
  final _maxCartValueController = TextEditingController();
  final _orderCapacityWarningController = TextEditingController();
  final _orderCapacityBlockController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  AppConfig? _currentConfig;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadConfiguration();
  }

  @override
  void dispose() {
    _deliveryChargeController.dispose();
    _freeDeliveryThresholdController.dispose();
    _maxCartValueController.dispose();
    _orderCapacityWarningController.dispose();
    _orderCapacityBlockController.dispose();
    super.dispose();
  }

  /// Load current configuration from service
  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final config = await _configService.getConfig();
      setState(() {
        _currentConfig = config;
        _deliveryChargeController.text = config.deliveryCharge.toString();
        _freeDeliveryThresholdController.text = config.freeDeliveryThreshold
            .toString();
        _maxCartValueController.text = config.maxCartValue.toString();
        _orderCapacityWarningController.text = config
            .orderCapacityWarningThreshold
            .toString();
        _orderCapacityBlockController.text = config.orderCapacityBlockThreshold
            .toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load configuration: $e';
        _isLoading = false;
      });
    }
  }

  /// Save configuration changes
  Future<void> _saveConfiguration() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Capture context before any async operations
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final authProvider = context.read<AuthProvider>();
    final adminId = authProvider.currentCustomer?.id ?? 'unknown';

    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog();
    if (!confirmed) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedConfig = AppConfig(
        deliveryCharge: double.parse(_deliveryChargeController.text),
        freeDeliveryThreshold: double.parse(
          _freeDeliveryThresholdController.text,
        ),
        maxCartValue: double.parse(_maxCartValueController.text),
        orderCapacityWarningThreshold: int.parse(
          _orderCapacityWarningController.text,
        ),
        orderCapacityBlockThreshold: int.parse(
          _orderCapacityBlockController.text,
        ),
        updatedAt: DateTime.now(),
        updatedBy: adminId,
      );

      await _configService.updateConfig(updatedConfig);

      if (mounted) {
        _showSuccessSnackbar(
          scaffoldMessenger,
          'Configuration updated successfully',
        );
        // Reload to get the latest data
        await _loadConfiguration();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar(
          scaffoldMessenger,
          'Failed to save configuration: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  /// Show confirmation dialog before saving
  Future<bool> _showConfirmationDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Changes'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to update the app configuration?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('This will affect all customers immediately.'),
            const SizedBox(height: 16),
            _buildPreviewItem(
              'Delivery Charge',
              '₹${_deliveryChargeController.text}',
            ),
            _buildPreviewItem(
              'Free Delivery Threshold',
              '₹${_freeDeliveryThresholdController.text}',
            ),
            _buildPreviewItem(
              'Max Cart Value',
              '₹${_maxCartValueController.text}',
            ),
            _buildPreviewItem(
              'Order Capacity Warning',
              '${_orderCapacityWarningController.text} orders',
            ),
            _buildPreviewItem(
              'Order Capacity Block',
              '${_orderCapacityBlockController.text} orders',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackbar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error snackbar
  void _showErrorSnackbar(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Configuration'),
        actions: [
          if (!_isLoading && _currentConfig != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadConfiguration,
              tooltip: 'Refresh',
            ),
        ],
      ),
      drawer: AdminDrawer(currentRoute: Routes.adminAppConfig),
      body: _isLoading
          ? const Center(child: LoadingIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildConfigForm(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConfiguration,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Last updated info
            if (_currentConfig != null) _buildLastUpdatedInfo(),
            const SizedBox(height: 24),

            // Delivery Settings Section
            _buildSectionHeader('Delivery Settings'),
            const SizedBox(height: 16),
            _buildDeliveryChargeField(),
            const SizedBox(height: 16),
            _buildFreeDeliveryThresholdField(),
            const SizedBox(height: 16),
            _buildMaxCartValueField(),
            const SizedBox(height: 32),

            // Order Capacity Settings Section
            _buildSectionHeader('Order Capacity Settings'),
            const SizedBox(height: 16),
            _buildOrderCapacityWarningField(),
            const SizedBox(height: 16),
            _buildOrderCapacityBlockField(),
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfiguration,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save Configuration'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdatedInfo() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Last Updated',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateTime(_currentConfig!.updatedAt),
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'by ${_currentConfig!.updatedBy}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} '
        '${dateTime.hour.toString().padLeft(2, '0')}:'
        '${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildDeliveryChargeField() {
    return Tooltip(
      message:
          'Standard delivery charge applied to all orders. '
          'Set to 0 for free delivery on all orders.',
      child: TextFormField(
        controller: _deliveryChargeController,
        decoration: InputDecoration(
          labelText: 'Delivery Charge (₹)',
          hintText: 'Enter delivery charge amount',
          helperText: 'Standard delivery charge for all orders',
          prefixIcon: const Icon(Icons.local_shipping),
          suffixIcon: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delivery Charge'),
                  content: const Text(
                    'This is the standard delivery charge applied to all orders. '
                    'Orders above the free delivery threshold will have this charge waived. '
                    'Set to 0 to make all deliveries free.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Learn more about delivery charge',
          ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter delivery charge';
          }
          final charge = double.tryParse(value);
          if (charge == null) {
            return 'Please enter a valid number';
          }
          if (charge < 0) {
            return 'Delivery charge cannot be negative';
          }
          if (charge > 1000) {
            return 'Delivery charge cannot exceed ₹1000';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildFreeDeliveryThresholdField() {
    return Tooltip(
      message:
          'Minimum cart value required for free delivery. '
          'Orders above this amount will not be charged delivery fees.',
      child: TextFormField(
        controller: _freeDeliveryThresholdController,
        decoration: InputDecoration(
          labelText: 'Free Delivery Threshold (₹)',
          hintText: 'Enter minimum cart value for free delivery',
          helperText: 'Orders above this amount get free delivery',
          prefixIcon: const Icon(Icons.card_giftcard),
          suffixIcon: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Free Delivery Threshold'),
                  content: const Text(
                    'Set the minimum cart value required for free delivery. '
                    'When a customer\'s cart total reaches or exceeds this amount, '
                    'the delivery charge will be waived. This encourages larger orders.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Learn more about free delivery threshold',
          ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter free delivery threshold';
          }
          final threshold = double.tryParse(value);
          if (threshold == null) {
            return 'Please enter a valid number';
          }
          if (threshold <= 0) {
            return 'Threshold must be greater than 0';
          }
          if (threshold > 10000) {
            return 'Threshold cannot exceed ₹10000';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildMaxCartValueField() {
    return Tooltip(
      message:
          'Maximum allowed cart value. Orders cannot exceed this amount. '
          'This helps manage order capacity and inventory.',
      child: TextFormField(
        controller: _maxCartValueController,
        decoration: InputDecoration(
          labelText: 'Maximum Cart Value (₹)',
          hintText: 'Enter maximum allowed cart value',
          helperText: 'Orders cannot exceed this amount',
          prefixIcon: const Icon(Icons.shopping_cart),
          suffixIcon: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Maximum Cart Value'),
                  content: const Text(
                    'Set the maximum cart value allowed per order. '
                    'This helps manage order capacity and ensures you can fulfill orders. '
                    'Customers will be prevented from checking out if their cart exceeds this limit.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Learn more about maximum cart value',
          ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
        ],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter maximum cart value';
          }
          final maxValue = double.tryParse(value);
          if (maxValue == null) {
            return 'Please enter a valid number';
          }
          final threshold = double.tryParse(
            _freeDeliveryThresholdController.text,
          );
          if (threshold != null && maxValue <= threshold) {
            return 'Max cart value must be greater than free delivery threshold';
          }
          if (maxValue > 100000) {
            return 'Max cart value cannot exceed ₹100000';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOrderCapacityWarningField() {
    return Tooltip(
      message:
          'Number of pending orders that triggers a delivery delay warning. '
          'Customers will see a warning but can still place orders.',
      child: TextFormField(
        controller: _orderCapacityWarningController,
        decoration: InputDecoration(
          labelText: 'Order Capacity Warning Threshold',
          hintText: 'Enter number of pending orders for warning',
          helperText: 'Show "Delivery might be delayed" warning at this count',
          prefixIcon: const Icon(Icons.warning_amber),
          suffixIcon: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Order Capacity Warning'),
                  content: const Text(
                    'When the number of pending orders reaches this threshold, '
                    'customers will see a warning that delivery might be delayed. '
                    'They can still place orders. This helps set realistic expectations.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Learn more about warning threshold',
          ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter warning threshold';
          }
          final warning = int.tryParse(value);
          if (warning == null) {
            return 'Please enter a valid number';
          }
          if (warning <= 0) {
            return 'Warning threshold must be greater than 0';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOrderCapacityBlockField() {
    return Tooltip(
      message:
          'Number of pending orders that blocks new orders. '
          'Customers cannot place orders when this limit is reached.',
      child: TextFormField(
        controller: _orderCapacityBlockController,
        decoration: InputDecoration(
          labelText: 'Order Capacity Block Threshold',
          hintText: 'Enter number of pending orders to block new orders',
          helperText: 'Block new orders when pending count reaches this number',
          prefixIcon: const Icon(Icons.block),
          suffixIcon: IconButton(
            icon: const Icon(Icons.help_outline, size: 20),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Order Capacity Block'),
                  content: const Text(
                    'When the number of pending orders reaches this threshold, '
                    'new orders will be blocked. Customers will see a message that '
                    'order capacity is full. This prevents overwhelming your fulfillment capacity.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Learn more about block threshold',
          ),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter block threshold';
          }
          final block = int.tryParse(value);
          if (block == null) {
            return 'Please enter a valid number';
          }
          final warning = int.tryParse(_orderCapacityWarningController.text);
          if (warning != null && block <= warning) {
            return 'Block threshold must be greater than warning threshold';
          }
          if (block > 1000) {
            return 'Block threshold cannot exceed 1000';
          }
          return null;
        },
      ),
    );
  }
}
