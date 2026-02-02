# Kirana Online Grocery App - Documentation

Welcome to the Kirana documentation hub. This directory contains comprehensive guides for users, administrators, and developers.

## 📚 Documentation Index

### For Customers
- **[Customer User Guide](CUSTOMER_USER_GUIDE.md)** - Complete guide for shopping, managing orders, and using the app
  - Registration and login
  - Browsing and searching products
  - Cart management
  - Placing orders
  - Managing addresses
  - Order history and tracking
  - Profile management
  - Notifications

### For Administrators
- **[Admin User Guide](ADMIN_USER_GUIDE.md)** - Comprehensive guide for managing the platform
  - Admin dashboard overview
  - Inventory management
  - Product management (add, edit, delete)
  - Order management and fulfillment
  - Analytics and monitoring
  - Security best practices
- **[Category Management Guide](ADMIN_CATEGORY_MANAGEMENT.md)** - Complete guide for managing product categories
- **[App Configuration Guide](ADMIN_APP_CONFIGURATION.md)** - Managing delivery charges, cart limits, and capacity thresholds
- **[Delivery Proof Guide](ADMIN_DELIVERY_PROOF.md)** - Capturing and managing delivery photos and locations

### For Developers & DevOps

#### Setup & Configuration
- **[Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md)** - Initial Firebase project configuration
- **[Firebase Setup Enhancements](FIREBASE_SETUP_ENHANCEMENTS.md)** - Configuration for enhanced features (v2.0)
- **[Firebase Verification](FIREBASE_VERIFICATION.md)** - Verify Firebase integration
- **[Initial Admin Setup](INITIAL_ADMIN_SETUP.md)** - Create the first admin account
- **[Default Data Initialization](DEFAULT_DATA_INITIALIZATION.md)** - Initialize categories and configuration

#### Deployment
- **[Deployment Guide](DEPLOYMENT_GUIDE.md)** - Complete deployment instructions
  - Firebase production configuration
  - Security setup
  - Database and storage configuration
  - Monitoring and alerts
  - Backup configuration
  - App store deployment
- **[Deployment Checklist](DEPLOYMENT_CHECKLIST.md)** - Step-by-step deployment checklist
- **[Deployment Checklist - Enhancements](DEPLOYMENT_CHECKLIST_ENHANCEMENTS.md)** - Checklist for v2.0 enhanced features

#### Technical Documentation
- **[Firestore Indexes](FIRESTORE_INDEXES.md)** - Database index configuration
- **[Security Rules Deployment](SECURITY_RULES_DEPLOYMENT.md)** - Firestore and Storage security rules
- **[Analytics and Monitoring](ANALYTICS_AND_MONITORING.md)** - Firebase Analytics, Crashlytics, and Performance Monitoring
- **[Notification System](NOTIFICATION_SYSTEM.md)** - In-app notification implementation
- **[Error Handling Guide](ERROR_HANDLING_GUIDE.md)** - Error handling and logging

### Support & Troubleshooting
- **[Troubleshooting Guide](TROUBLESHOOTING.md)** - Common issues and solutions
  - Authentication issues
  - Product browsing issues
  - Cart and order issues
  - Image upload issues
  - Network and connectivity issues
  - Performance issues
  - Admin-specific issues

---

## 🚀 Quick Start

### For New Customers
1. Download the Kirana app from App Store or Play Store
2. Read the [Customer User Guide](CUSTOMER_USER_GUIDE.md)
3. Register with your phone number
4. Start shopping!

### For New Admins
1. Ensure you have admin access (contact system administrator)
2. Read the [Admin User Guide](ADMIN_USER_GUIDE.md)
3. Login with your admin phone number
4. Familiarize yourself with the dashboard and features

### For Developers
1. Review the [Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md)
2. Follow the [Deployment Guide](DEPLOYMENT_GUIDE.md)
3. Use the [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)
4. Set up the [Initial Admin Account](INITIAL_ADMIN_SETUP.md)

---

## 📖 Documentation Structure

```
docs/
├── README.md (this file)
│
├── User Documentation
│   ├── CUSTOMER_USER_GUIDE.md
│   ├── ADMIN_USER_GUIDE.md
│   └── TROUBLESHOOTING.md
│
├── Deployment Documentation
│   ├── DEPLOYMENT_GUIDE.md
│   ├── DEPLOYMENT_CHECKLIST.md
│   └── INITIAL_ADMIN_SETUP.md
│
└── Technical Documentation
    ├── FIREBASE_SETUP_GUIDE.md
    ├── FIREBASE_VERIFICATION.md
    ├── FIRESTORE_INDEXES.md
    ├── SECURITY_RULES_DEPLOYMENT.md
    ├── ANALYTICS_AND_MONITORING.md
    ├── NOTIFICATION_SYSTEM.md
    └── ERROR_HANDLING_GUIDE.md
```

---

## 🎯 Common Tasks

### I want to...

**...start using the app as a customer**
→ Read [Customer User Guide](CUSTOMER_USER_GUIDE.md)

**...manage inventory and orders**
→ Read [Admin User Guide](ADMIN_USER_GUIDE.md)

**...manage product categories**
→ Read [Category Management Guide](ADMIN_CATEGORY_MANAGEMENT.md)

**...configure app settings**
→ Read [App Configuration Guide](ADMIN_APP_CONFIGURATION.md)

**...capture delivery proof**
→ Read [Delivery Proof Guide](ADMIN_DELIVERY_PROOF.md)

**...deploy the app to production**
→ Follow [Deployment Guide](DEPLOYMENT_GUIDE.md) and [Deployment Checklist](DEPLOYMENT_CHECKLIST.md)

**...create the first admin account**
→ Follow [Initial Admin Setup](INITIAL_ADMIN_SETUP.md)

**...troubleshoot an issue**
→ Check [Troubleshooting Guide](TROUBLESHOOTING.md)

**...set up Firebase**
→ Follow [Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md) and [Firebase Setup Enhancements](FIREBASE_SETUP_ENHANCEMENTS.md)

**...initialize default data**
→ Follow [Default Data Initialization](DEFAULT_DATA_INITIALIZATION.md)

**...configure monitoring**
→ Read [Analytics and Monitoring](ANALYTICS_AND_MONITORING.md)

**...understand the notification system**
→ Read [Notification System](NOTIFICATION_SYSTEM.md)

**...deploy security rules**
→ Follow [Security Rules Deployment](SECURITY_RULES_DEPLOYMENT.md)

---

## 🔧 Technical Stack

### Frontend
- **Framework**: Flutter 3.x
- **State Management**: Provider
- **UI**: Material Design 3

### Backend (Firebase)
- **Authentication**: Firebase Authentication (Phone)
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Analytics**: Firebase Analytics
- **Monitoring**: Firebase Crashlytics & Performance Monitoring

### Development Tools
- **Version Control**: Git
- **CI/CD**: Firebase App Distribution (optional)
- **Testing**: Flutter Test, Integration Tests, Property-Based Tests

---

## 📊 Key Features

### Customer Features
✅ Phone number authentication with OTP
✅ Product browsing with search and category filters
✅ Shopping cart with persistence
✅ Discount pricing and special offers
✅ Minimum order quantity requirements
✅ Smart delivery charges (FREE for orders ≥ ₹200)
✅ Order capacity warnings
✅ Multiple delivery addresses
✅ Order placement (Cash on Delivery)
✅ Order history and tracking
✅ Real-time order status notifications
✅ Push notifications with sound alerts
✅ Delivery proof viewing (photo + location)
✅ Delivery feedback and remarks
✅ Profile management

### Admin Features
✅ Admin dashboard with statistics
✅ Category management (create, edit, delete)
✅ Inventory management (CRUD operations)
✅ Product discount management
✅ Minimum order quantity configuration
✅ Product image upload
✅ Stock management
✅ Order management and fulfillment
✅ Delivery proof capture (photo + GPS location)
✅ App configuration (delivery charges, cart limits, capacity thresholds)
✅ Order status updates
✅ Customer notifications
✅ Push notification management
✅ Analytics and reporting

### Technical Features
✅ Offline support (cart persistence)
✅ Real-time data synchronization
✅ Secure data encryption
✅ Audit logging
✅ Error handling and logging
✅ Performance monitoring
✅ Crash reporting
✅ Push notifications (FCM)
✅ Image compression and optimization
✅ GPS location capture
✅ Configurable business rules

---

## 🔒 Security

The app implements multiple security layers:
- **Authentication**: Phone-based OTP authentication
- **Authorization**: Role-based access control (Customer/Admin)
- **Data Encryption**: Sensitive data encrypted at rest
- **Security Rules**: Firestore and Storage security rules
- **Audit Logging**: All admin actions logged
- **OTP Hashing**: Verification codes hashed with bcrypt

See [Security Rules Deployment](SECURITY_RULES_DEPLOYMENT.md) for details.

---

## 📈 Monitoring

The app includes comprehensive monitoring:
- **Analytics**: User behavior and engagement tracking
- **Crashlytics**: Crash reporting and analysis
- **Performance**: App performance monitoring
- **Alerts**: Automated alerts for critical issues

See [Analytics and Monitoring](ANALYTICS_AND_MONITORING.md) for details.

---

## 🆘 Getting Help

### For Customers
- Check [Customer User Guide](CUSTOMER_USER_GUIDE.md)
- Review [Troubleshooting Guide](TROUBLESHOOTING.md)
- Contact customer support through the app

### For Admins
- Check [Admin User Guide](ADMIN_USER_GUIDE.md)
- Review [Troubleshooting Guide](TROUBLESHOOTING.md)
- Contact system administrator

### For Developers
- Review relevant technical documentation
- Check [Troubleshooting Guide](TROUBLESHOOTING.md)
- Check Firebase Console for errors
- Review application logs

---

## 🔄 Updates and Maintenance

### Keeping Documentation Updated
- Update documentation when features change
- Review documentation quarterly
- Gather feedback from users and admins
- Keep troubleshooting guide current with new issues

### Version History
- **v1.0.0** - Initial release documentation
- Future versions will be documented here

---

## 📝 Contributing to Documentation

If you find errors or have suggestions:
1. Document the issue clearly
2. Suggest improvements
3. Submit changes for review
4. Update version history

---

## 📞 Support Contacts

### Technical Support
- **System Administrator**: [Contact Info]
- **Developer Team**: [Contact Info]

### Business Support
- **Product Manager**: [Contact Info]
- **Customer Support**: [Contact Info]

### Emergency Contacts
- **Critical Issues**: [Contact Info]
- **After Hours**: [Contact Info]

---

## 📄 License

[Add your license information here]

---

## 🙏 Acknowledgments

Built with:
- Flutter & Dart
- Firebase Platform
- Material Design
- Open source packages (see pubspec.yaml)

---

**Last Updated**: January 2025
**Documentation Version**: 2.0.0 (Enhanced Features)
**App Version**: 2.0.0

---

**Need help? Start with the relevant guide above or check the [Troubleshooting Guide](TROUBLESHOOTING.md)!**
