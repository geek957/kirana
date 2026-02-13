import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/product_provider.dart';
import 'providers/cart_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/address_provider.dart';
import 'providers/order_provider.dart';
import 'providers/admin_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/category_provider.dart';
import 'services/encryption_service.dart';
import 'services/navigation_service.dart';
import 'services/analytics_service.dart';
import 'services/crashlytics_service.dart';
import 'services/notification_service.dart';
import 'utils/route_generator.dart';
import 'utils/auth_guard.dart';
import 'utils/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Crashlytics
  await CrashlyticsService().initialize();

  // Enable Firestore offline persistence
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Initialize Firebase Cloud Messaging
  await NotificationService().initializeFCM();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
      ],
      child: MaterialApp(
        title: 'Kirana - Online Grocery',
        theme: AppTheme.lightTheme,
        navigatorKey: NavigationService.navigatorKey,
        navigatorObservers: [AnalyticsService().getAnalyticsObserver()],
        onGenerateRoute: RouteGenerator.generateRoute,
        home: const AuthWrapper(),
      ),
    );
  }
}
