import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/admin_provider.dart';
import '../../services/admin_service.dart';
import '../../models/order.dart';

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
      body: SingleChildScrollView(
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

            // Order Total
            _buildTotalCard(),
            const SizedBox(height: 24),

            // Current Status
            _buildSectionTitle('Current Status'),
            const SizedBox(height: 12),
            _buildStatusBadge(_order!.status),
            const SizedBox(height: 24),

            // Update Status
            _buildSectionTitle('Update Status'),
            const SizedBox(height: 12),
            _buildStatusDropdown(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateOrderStatus,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Update Status'),
              ),
            ),
          ],
        ),
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              '₹${_order!.totalAmount.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ],
        ),
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
}
