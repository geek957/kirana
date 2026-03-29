import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'About Flash'),
          _buildSectionContent(
            context,
            'Flash is your one-stop online grocery delivery app that brings fresh groceries, '
            'daily essentials, and more right to your doorstep. Enjoy fast delivery, quality products, '
            'and a seamless shopping experience.',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'How to Order'),
          _buildStepItem(context, '1', 'Browse Products',
              'Explore our wide range of groceries, vegetables, fruits, and daily essentials.'),
          _buildStepItem(context, '2', 'Add to Cart',
              'Tap on products you want to buy and add them to your cart. Adjust quantities as needed.'),
          _buildStepItem(context, '3', 'Review Cart',
              'Check your cart, update quantities, and proceed to checkout.'),
          _buildStepItem(context, '4', 'Select Address',
              'Choose or add a delivery address for your order.'),
          _buildStepItem(context, '5', 'Place Order',
              'Review order details and confirm your order. Pay cash on delivery.'),
          _buildStepItem(context, '6', 'Track Delivery',
              'Track your order status in real-time from preparation to delivery.'),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Account & Profile'),
          _buildSectionContent(
            context,
            '• Sign in using your mobile number and OTP verification\n'
            '• Manage your profile information\n'
            '• Add and save multiple delivery addresses\n'
            '• View your order history\n'
            '• Receive notifications about order updates',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Orders & Delivery'),
          _buildSectionContent(
            context,
            'Order Status:\n'
            '• Pending - Order received and being processed\n'
            '• Confirmed - Order confirmed by store\n'
            '• Preparing - Your order is being packed\n'
            '• Out for Delivery - Delivery executive is on the way\n'
            '• Delivered - Order successfully delivered\n\n'
            'Cancellation:\n'
            'You can cancel orders before they are confirmed. Once an order is confirmed '
            'or being prepared, cancellation may not be available.',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Payment'),
          _buildSectionContent(
            context,
            'We currently accept Cash on Delivery (COD) for all orders. '
            'Pay the delivery executive when you receive your order. '
            'Make sure to keep exact change ready for a smooth transaction.',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Notifications'),
          _buildSectionContent(
            context,
            'Stay updated with push notifications about:\n'
            '• Order confirmations\n'
            '• Order status updates\n'
            '• Delivery updates\n'
            '• Special offers and promotions\n\n'
            'You can view all notifications by tapping the bell icon on the home screen.',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Frequently Asked Questions'),
          _buildFaqItem(
            context,
            'What is the minimum order amount?',
            'There is no minimum order amount. You can order products worth any value.',
          ),
          _buildFaqItem(
            context,
            'What are the delivery hours?',
            'We typically deliver orders during business hours. Specific delivery times may vary '
            'based on your location and order time.',
          ),
          _buildFaqItem(
            context,
            'How do I track my order?',
            'Go to "Orders" section from the bottom navigation to view real-time status of your orders.',
          ),
          _buildFaqItem(
            context,
            'Can I modify my order after placing it?',
            'Unfortunately, orders cannot be modified once placed. However, you can cancel the order '
            '(if it\'s not yet confirmed) and place a new one.',
          ),
          _buildFaqItem(
            context,
            'What if I receive damaged or wrong items?',
            'Please contact our admin immediately if you receive damaged or incorrect items. '
            'We will resolve the issue promptly.',
          ),
          const SizedBox(height: 24),

          _buildSectionHeader(context, 'Contact Us'),
          _buildSectionContent(
            context,
            'Need help or have questions? Reach out to our admin:',
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.email_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Email',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'r.akhil.9640@gmail.com',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: 'r.akhil.9640@gmail.com'),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Email copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Copy email',
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  'Flash - Fresh Groceries Delivered',
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[500],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildSectionContent(BuildContext context, String content) {
    return Text(
      content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.6,
          ),
    );
  }

  Widget _buildStepItem(
    BuildContext context,
    String number,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(
    BuildContext context,
    String question,
    String answer,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.help_outline,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 28),
            child: Text(
              answer,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
