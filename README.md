# Kirana - Online Grocery App

A comprehensive Flutter-based online grocery shopping platform with advanced features for both customers and administrators.

## 🌟 Features

### Customer Features
- 📱 **Phone Authentication** - Secure OTP-based login
- 🛒 **Smart Shopping Cart** - Persistent cart with real-time updates
- 🏷️ **Product Categories** - Easy browsing by category
- 💰 **Discount Pricing** - Special offers and promotional pricing
- 📦 **Minimum Order Quantities** - Clear quantity requirements per product
- 🚚 **Smart Delivery Charges** - Free delivery on orders ≥ ₹200
- ⚠️ **Order Capacity Warnings** - Real-time delivery availability status
- 📍 **Multiple Addresses** - Save and manage delivery locations
- 📋 **Order Tracking** - Real-time order status updates
- 📸 **Delivery Proof** - Photo and location verification
- 💬 **Delivery Feedback** - Share your experience after delivery
- 🔔 **Push Notifications** - Stay updated with order status
- 🔊 **Notification Sounds** - Audio alerts for important updates

### Admin Features
- 📊 **Admin Dashboard** - Comprehensive statistics and insights
- 📦 **Inventory Management** - Full product CRUD operations
- 🏷️ **Category Management** - Create and organize product categories
- 💸 **Discount Management** - Set promotional pricing
- 📸 **Delivery Photo Capture** - Proof of delivery with GPS location
- 🔧 **App Configuration** - Manage delivery charges, cart limits, and capacity thresholds
- 📋 **Order Management** - Process and track all orders
- 🔔 **Customer Notifications** - Send updates and announcements
- 📈 **Analytics** - Monitor sales and performance

## 🚀 Quick Start

### For Customers
1. Download the Kirana app
2. Register with your phone number
3. Browse products by category
4. Add items to cart (watch for discounts!)
5. Place your order
6. Track delivery in real-time
7. Provide feedback after delivery

### For Admins
1. Login with admin credentials
2. Manage product categories
3. Add/update products with discounts
4. Configure app settings (delivery charges, limits)
5. Process customer orders
6. Capture delivery proof (photo + location)
7. Monitor order capacity

## 📚 Documentation

Comprehensive documentation is available in the `docs/` directory:

### User Guides
- **[Customer User Guide](docs/CUSTOMER_USER_GUIDE.md)** - Complete shopping guide
- **[Admin User Guide](docs/ADMIN_USER_GUIDE.md)** - Platform management guide

### Setup & Deployment
- **[Firebase Setup Guide](docs/FIREBASE_SETUP_GUIDE.md)** - Initial configuration
- **[Deployment Guide](docs/DEPLOYMENT_GUIDE.md)** - Production deployment
- **[Deployment Checklist](docs/DEPLOYMENT_CHECKLIST.md)** - Pre-deployment verification

### Technical Documentation
- **[Firestore Indexes](docs/FIRESTORE_INDEXES.md)** - Database indexes
- **[Security Rules](docs/SECURITY_RULES_DEPLOYMENT.md)** - Firestore & Storage rules
- **[Default Data Initialization](docs/DEFAULT_DATA_INITIALIZATION.md)** - Initial data setup
- **[Troubleshooting](docs/TROUBLESHOOTING.md)** - Common issues and solutions

## 🛠️ Technology Stack

### Frontend
- **Flutter** 3.16+ - Cross-platform mobile framework
- **Dart** 3.2+ - Programming language
- **Provider** - State management
- **Material Design 3** - UI components

### Backend (Firebase)
- **Firebase Authentication** - Phone-based OTP authentication
- **Cloud Firestore** - Real-time NoSQL database
- **Firebase Storage** - Image and file storage
- **Firebase Cloud Messaging** - Push notifications
- **Firebase Analytics** - User behavior tracking
- **Firebase Crashlytics** - Error monitoring
- **Firebase Performance** - Performance monitoring

### Key Packages
- `image_picker` - Camera access for delivery photos
- `geolocator` - GPS location capture
- `firebase_messaging` - Push notifications
- `audioplayers` - Notification sounds
- `flutter_image_compress` - Image optimization
- `cached_network_image` - Efficient image loading

## 💡 Key Features Explained

### Product Discount Pricing
- Admins can set optional discount prices on products
- Customers see both original and discounted prices
- Discount percentage displayed prominently
- Cart automatically uses discounted prices

### Product Categories
- Organized product catalog for easy browsing
- Admin-managed category system
- Filter products by category
- Alphabetically sorted categories

### Delivery Proof System
- Mandatory photo capture at delivery
- Automatic GPS location recording
- Stored securely in Firebase Storage
- Visible to both admin and customer

### Configurable Business Rules
- **Delivery Charge**: ₹20 (configurable)
- **Free Delivery Threshold**: ₹200 (configurable)
- **Maximum Cart Value**: ₹3000 (configurable)
- **Order Capacity Thresholds**: Warning at 2, Block at 10 (configurable)

### Smart Order Capacity Management
- Real-time tracking of pending orders
- Warning when capacity is high (≥2 pending orders)
- Blocking when capacity is full (≥10 pending orders)
- Helps manage delivery expectations

### Enhanced Notification System
- Push notifications to device
- In-app notification center
- Custom notification sounds
- User-configurable sound settings
- Background notification handling

### Customer Delivery Feedback
- Add remarks after delivery
- 500 character limit
- Editable for 24 hours
- Visible to admin for quality monitoring

## 🔒 Security Features

- **Phone Authentication** - Secure OTP verification
- **Role-Based Access** - Customer/Admin separation
- **Data Encryption** - Sensitive data encrypted at rest
- **Security Rules** - Firestore and Storage access control
- **Audit Logging** - All admin actions logged
- **OTP Hashing** - Verification codes securely hashed
- **File Validation** - Image upload size and type restrictions

## 📱 Platform Support

- ✅ Android (API 21+)
- ✅ iOS (12.0+)
- ✅ Offline cart persistence
- ✅ Real-time data synchronization
- ✅ Push notifications (both platforms)
- ✅ Camera and GPS support

## 🚀 Getting Started with Development

### Prerequisites
```bash
flutter --version  # Flutter 3.16.0 or higher
dart --version     # Dart 3.2.0 or higher
```

### Installation
```bash
# Clone the repository
git clone <repository-url>
cd kirana

# Install dependencies
flutter pub get

# Run the app
flutter run
```

### Firebase Setup
1. Create a Firebase project
2. Add Android and iOS apps
3. Download configuration files:
   - `google-services.json` (Android)
   - `GoogleService-Info.plist` (iOS)
4. Enable Firebase services:
   - Authentication (Phone)
   - Cloud Firestore
   - Firebase Storage
   - Cloud Messaging
5. Deploy security rules and indexes
6. Initialize default data

See [Firebase Setup Guide](docs/FIREBASE_SETUP_GUIDE.md) for detailed instructions.

## 📋 Project Structure

```
lib/
├── models/          # Data models (Product, Order, Category, AppConfig)
├── services/        # Firebase services (Auth, Firestore, Storage)
├── providers/       # State management (Provider pattern)
├── screens/         # UI screens (Customer & Admin)
├── widgets/         # Reusable UI components
└── utils/           # Helper functions and constants

docs/                # Comprehensive documentation
assets/              # Images, sounds, and other assets
firestore/           # Firestore security rules and indexes
```

## 🤝 Contributing

1. Read the documentation in `docs/`
2. Follow the existing code structure
3. Test thoroughly before submitting
4. Update documentation for new features

## 📄 License

[Add your license information here]

## 🙏 Acknowledgments

Built with:
- Flutter & Dart
- Firebase Platform
- Material Design
- Open source community

## 📞 Support

For issues and questions:
- Check [Troubleshooting Guide](docs/TROUBLESHOOTING.md)
- Review [Customer Guide](docs/CUSTOMER_USER_GUIDE.md) or [Admin Guide](docs/ADMIN_USER_GUIDE.md)
- Contact support team

---

**Version**: 2.0.0 (Enhanced)
**Last Updated**: January 2025

**Happy Shopping! 🛒**
