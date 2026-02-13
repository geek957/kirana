import 'package:flutter/material.dart';
import '../utils/routes.dart';

/// Bottom navigation bar for customer interface
/// Only displayed on home screen with 3 items: Home, Search, Orders
class CustomerBottomNav extends StatelessWidget {
  final int currentIndex;
  final VoidCallback? onSearchTap;

  const CustomerBottomNav({
    super.key,
    required this.currentIndex,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey,
      onTap: (index) => _onItemTapped(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Search',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
      ],
    );
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        // Home - do nothing if already on home, otherwise navigate
        if (currentIndex != 0) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            Routes.home,
            (route) => false,
          );
        }
        break;
      case 1:
        // Search - trigger search focus callback
        onSearchTap?.call();
        break;
      case 2:
        // Orders
        Navigator.of(context).pushNamed(Routes.orderHistory);
        break;
    }
  }
}
