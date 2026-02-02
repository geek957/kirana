import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../widgets/star_rating.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  final AdminService _adminService = AdminService();
  Order? _order;
  bool _isLoading = true;
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _isLoading = true);
    try {
      final orders = await _adminService.getAllOrders();
      final order = orders.firstWhere((o) => o.id == widget.orderId);
      setState(() {
        _order = order;
        _selectedStatus = order.status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading order: $e')));
      }
    }
  }

  Future<void> _updateOrderStatus() async {
    if (_selectedStatus == null || _order == null) return;

    if (_selectedStatus == _order!.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status is already set to this value')),
      );
      return;
    }

    try {
      await context.read<AdminProvider>().updateOrderStatus(
        widget.orderId,
        _selectedStatus!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order status updated successfully')),
        );
        // Reload order to get updated data
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order Details')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Scaffold(
      appBar: AppBar(title: Text('Order #${_order!.id.substring(0, 8)}')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Customer Information
            _buildSectionTitle('Customer Information'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.person, 'Name', _order!.customerName),
              _buildInfoRow(Icons.phone, 'Phone', _order!.customerPhone),
            ]),
            const SizedBox(height: 16),

            // Order Total
            _buildTotalCard(),
            const SizedBox(height: 24),

            // Delivery Address
            _buildSectionTitle('Delivery Address'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.label,
                'Label',
                _order!.deliveryAddress.label,
              ),
              _buildInfoRow(
                Icons.location_on,
                'Address',
                _order!.deliveryAddress.fullAddress,
              ),
              if (_order!.deliveryAddress.landmark != null &&
                  _order!.deliveryAddress.landmark!.isNotEmpty)
                _buildInfoRow(
                  Icons.place,
                  'Landmark',
                  _order!.deliveryAddress.landmark!,
                ),
              _buildInfoRow(
                Icons.phone,
                'Contact',
                _order!.deliveryAddress.contactNumber,
              ),
            ]),
            const SizedBox(height: 24),

            // Order Details
            _buildSectionTitle('Order Details'),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.calendar_today,
                'Order Date',
                dateFormat.format(_order!.createdAt),
              ),
              _buildInfoRow(
                Icons.payment,
                'Payment Method',
                _getPaymentMethodText(_order!.paymentMethod),
              ),
              if (_order!.deliveredAt != null)
                _buildInfoRow(
                  Icons.check_circle,
                  'Delivered At',
                  dateFormat.format(_order!.deliveredAt!),
                ),
            ]),
            const SizedBox(height: 24),

            // Items Ordered
            _buildSectionTitle('Items Ordered'),
            const SizedBox(height: 12),
            _buildItemsList(),
            const SizedBox(height: 24),

            // Delivery Proof Section (only for delivered orders)
            if (_order!.status == OrderStatus.delivered) ...[
              _buildSectionTitle('Delivery Proof'),
              const SizedBox(height: 12),
              _buildDeliveryProofSection(),
              const SizedBox(height: 24),
            ],

            // Customer Feedback Section (only if rating exists)
            if (_order!.rating != null) ...[
              _buildSectionTitle('Customer Feedback'),
              const SizedBox(height: 12),
              _buildCustomerRemarksSection(),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    ),
    // Fixed bottom section with status and actions
    Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Status
              Text(
                'Order Status',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              _buildCurrentStatusCard(),
              // Available Actions (only show if there are actions)
              if (_hasAvailableActions()) ...[
                const SizedBox(height: 12),
                Text(
                  'Available Actions',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusActionButtons(),
              ],
            ],
          ),
        ),
      ),
    ),
  ],
),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Card(
      elevation: 2,
      child: Column(
        children: _order!.items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == _order!.items.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '₹${item.price.toStringAsFixed(2)} × ${item.quantity}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${item.subtotal.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast) const Divider(height: 1),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTotalCard() {
    return Card(
      elevation: 2,
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 14)),
                Text(
                  '₹${_order!.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery', style: TextStyle(fontSize: 14)),
                Text(
                  _order!.deliveryCharge == 0
                      ? 'Free'
                      : '₹${_order!.deliveryCharge.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: _order!.deliveryCharge == 0
                        ? Colors.green
                        : null,
                    fontWeight: _order!.deliveryCharge == 0
                        ? FontWeight.bold
                        : null,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '₹${(_order!.totalAmount + _order!.deliveryCharge).toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryProofSection() {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Photo
            if (_order!.deliveryPhotoUrl != null) ...[
              Row(
                children: [
                  Icon(Icons.photo_camera, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Delivery Photo',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showFullScreenImage(_order!.deliveryPhotoUrl!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _order!.deliveryPhotoUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to view full size',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.photo_camera, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    'No delivery photo available',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),

            // Delivery Location
            if (_order!.deliveryLocation != null) ...[
              Row(
                children: [
                  Icon(Icons.location_on, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Text(
                    'Delivery Location',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Latitude: ${_order!.deliveryLocation!.latitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.my_location,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Longitude: ${_order!.deliveryLocation!.longitude.toStringAsFixed(6)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openInMaps(
                          _order!.deliveryLocation!.latitude,
                          _order!.deliveryLocation!.longitude,
                        ),
                        icon: const Icon(Icons.map, size: 18),
                        label: const Text('Open in Maps'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Icon(Icons.location_off, size: 20, color: Colors.grey[400]),
                  const SizedBox(width: 12),
                  Text(
                    'No delivery location available',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],

            // Delivery Timestamp
            if (_order!.deliveredAt != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivered At',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dateFormat.format(_order!.deliveredAt!),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerRemarksSection() {
    final dateFormat = DateFormat('MMM dd, yyyy hh:mm a');

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _order!.rating! >= 4
                        ? Colors.green[50]
                        : _order!.rating! == 3
                            ? Colors.orange[50]
                            : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _order!.rating! >= 4
                        ? Icons.sentiment_very_satisfied
                        : _order!.rating! == 3
                            ? Icons.sentiment_neutral
                            : Icons.sentiment_dissatisfied,
                    color: _order!.rating! >= 4
                        ? Colors.green[700]
                        : _order!.rating! == 3
                            ? Colors.orange[700]
                            : Colors.red[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Customer Feedback',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Rating Display
            Row(
              children: [
                StarRating(
                  rating: _order!.rating!,
                  size: 28,
                  isInteractive: false,
                ),
                const SizedBox(width: 12),
                Text(
                  '${_order!.rating}/5 Stars',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            // Text feedback if provided
            if (_order!.customerRemarks != null &&
                _order!.customerRemarks!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Comments:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _order!.customerRemarks!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
            
            if (_order!.remarksTimestamp != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted on ${dateFormat.format(_order!.remarksTimestamp!)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Failed to load image',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openInMaps(double latitude, double longitude) async {
    // Create a Google Maps URL
    final url =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

    // Show a dialog with the coordinates and option to copy
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delivery Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latitude: ${latitude.toStringAsFixed(6)}'),
            Text('Longitude: ${longitude.toStringAsFixed(6)}'),
            const SizedBox(height: 16),
            const Text(
              'You can open this location in your maps app or copy the coordinates.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              // In a real app, you would use url_launcher package
              // For now, just show a message
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Maps URL: $url'),
                  duration: const Duration(seconds: 3),
                ),
              );
            },
            child: const Text('View URL'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderStatus status) {
    Color backgroundColor;
    Color textColor = Colors.white;
    String text;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange;
        text = 'Pending';
        break;
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.purple;
        text = 'Preparing';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.indigo;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green;
        text = 'Delivered';
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red;
        text = 'Cancelled';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline, color: textColor, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButtonFormField<OrderStatus>(
          value: _selectedStatus,
          decoration: const InputDecoration(
            labelText: 'Select New Status',
            border: InputBorder.none,
          ),
          items: OrderStatus.values.map((status) {
            return DropdownMenuItem(
              value: status,
              child: Text(_getStatusText(status)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value;
            });
          },
        ),
      ),
    );
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.confirmed:
        return 'Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cashOnDelivery:
        return 'Cash on Delivery';
    }
  }

  // New UI methods for action buttons

  /// Builds current status display card
  Widget _buildCurrentStatusCard() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      color: _getStatusColor(_order!.status).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              _getStatusIcon(_order!.status),
              color: _getStatusColor(_order!.status),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Status',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStatusText(_order!.status),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_order!.status),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds action buttons based on current status
  Widget _buildStatusActionButtons() {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: _getAvailableActions(),
        ),
      ),
    );
  }

  /// Check if there are available actions for current status
  bool _hasAvailableActions() {
    return _order!.status != OrderStatus.delivered &&
           _order!.status != OrderStatus.cancelled;
  }

  /// Returns list of action buttons based on current status
  List<Widget> _getAvailableActions() {
    final actions = <Widget>[];
    
    switch (_order!.status) {
      case OrderStatus.pending:
        actions.add(_buildActionButton(
          icon: Icons.check_circle,
          label: 'Confirm Order',
          color: Colors.blue,
          onPressed: () => _updateStatus(OrderStatus.confirmed),
        ));
        actions.add(const SizedBox(height: 8));
        actions.add(_buildActionButton(
          icon: Icons.cancel,
          label: 'Cancel Order',
          color: Colors.red,
          onPressed: _confirmCancellation,
        ));
        break;
        
      case OrderStatus.confirmed:
        actions.add(_buildActionButton(
          icon: Icons.restaurant,
          label: 'Move to Preparing',
          color: Colors.purple,
          onPressed: () => _updateStatus(OrderStatus.preparing),
        ));
        actions.add(const SizedBox(height: 8));
        actions.add(_buildActionButton(
          icon: Icons.cancel,
          label: 'Cancel Order',
          color: Colors.red,
          onPressed: _confirmCancellation,
        ));
        break;
        
      case OrderStatus.preparing:
        actions.add(_buildActionButton(
          icon: Icons.local_shipping,
          label: 'Send Out for Delivery',
          color: Colors.indigo,
          onPressed: () => _updateStatus(OrderStatus.outForDelivery),
        ));
        break;
        
      case OrderStatus.outForDelivery:
        actions.add(_buildActionButton(
          icon: Icons.photo_camera,
          label: 'Mark as Delivered',
          subtitle: 'Requires photo + GPS location',
          color: Colors.green,
          onPressed: _showDeliveryCompletionDialog,
        ));
        break;
        
      case OrderStatus.delivered:
      case OrderStatus.cancelled:
        // No actions available - section will be hidden
        break;
    }
    
    return actions;
  }

  /// Builds an action button
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    String? subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  /// Updates order status (for non-delivered statuses)
  Future<void> _updateStatus(OrderStatus newStatus) async {
    try {
      await context.read<AdminProvider>().updateOrderStatus(
        widget.orderId,
        newStatus,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order status updated to ${_getStatusText(newStatus)}'),
            backgroundColor: Colors.green,
          ),
        );
        await _loadOrder();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Confirms order cancellation
  Future<void> _confirmCancellation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? Stock quantities will be restored.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _updateStatus(OrderStatus.cancelled);
    }
  }

  /// Gets status icon
  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  /// Gets status color
  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  /// Shows delivery completion dialog with photo and GPS
  Future<void> _showDeliveryCompletionDialog() async {
    final imagePicker = ImagePicker();
    File? capturedPhoto;
    Position? capturedLocation;
    bool isUploading = false;
    String? errorMessage;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Complete Delivery'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${_order!.id.substring(0, 8)}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Photo capture section
                      const Text(
                        'Delivery Photo (Required)',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (capturedPhoto == null)
                        ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final photo = await _capturePhoto(imagePicker);
                                  if (photo != null) {
                                    setState(() {
                                      capturedPhoto = photo;
                                      errorMessage = null;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('Capture Photo'),
                        )
                      else
                        Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                capturedPhoto!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () {
                                      setState(() {
                                        capturedPhoto = null;
                                      });
                                    },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retake Photo'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),

                      // Location capture section
                      const Text(
                        'GPS Location',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (capturedLocation == null)
                        ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : () async {
                                  final location = await _captureLocation();
                                  if (location != null) {
                                    setState(() {
                                      capturedLocation = location;
                                      errorMessage = null;
                                    });
                                  }
                                },
                          icon: const Icon(Icons.location_on),
                          label: const Text('Capture Location'),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Location captured\n'
                                  'Lat: ${capturedLocation!.latitude.toStringAsFixed(6)}\n'
                                  'Lng: ${capturedLocation!.longitude.toStringAsFixed(6)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              TextButton(
                                onPressed: isUploading
                                    ? null
                                    : () {
                                        setState(() {
                                          capturedLocation = null;
                                        });
                                      },
                                child: const Text('Recapture'),
                              ),
                            ],
                          ),
                        ),

                      // Error message
                      if (errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error,
                                color: Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  errorMessage!,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Upload progress
                      if (isUploading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Uploading delivery proof...',
                          style: TextStyle(fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed:
                      (capturedPhoto != null &&
                          capturedLocation != null &&
                          !isUploading)
                      ? () async {
                          setState(() {
                            isUploading = true;
                            errorMessage = null;
                          });

                          try {
                            final orderService = OrderService();
                            await orderService.completeDelivery(
                              orderId: widget.orderId,
                              deliveryPhoto: capturedPhoto!,
                              latitude: capturedLocation!.latitude,
                              longitude: capturedLocation!.longitude,
                            );

                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }

                            if (mounted) {
                              await _loadOrder();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Delivery completed successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setState(() {
                              isUploading = false;
                              errorMessage = e.toString();
                            });
                          }
                        }
                      : null,
                  child: const Text('Complete Delivery'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Captures a photo using the device camera
  Future<File?> _capturePhoto(ImagePicker imagePicker) async {
    try {
      final XFile? photo = await imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// Captures the current GPS location
  Future<Position?> _captureLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location services are disabled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location permission permanently denied. '
                'Please enable in settings.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      return position;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}
