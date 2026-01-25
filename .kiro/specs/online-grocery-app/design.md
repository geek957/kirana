# Design Document

## Overview

The Online Grocery Application is a cross-platform mobile application built with Flutter that enables customers to browse grocery items, manage shopping carts, and place orders with cash on delivery. The system includes a separate admin interface for inventory and order management. The architecture prioritizes cost-effectiveness by leveraging free-tier cloud services while maintaining scalability for up to 10,000 customers, 1,000 products, and 100 orders per day.

## Architecture

### High-Level Architecture

**Application Structure:**
- **Single Flutter Application** with role-based UI routing
  - Customer interface (default view)
  - Admin interface (accessible only to admin users)
  - Shared codebase with conditional rendering based on user role

**Backend Architecture:**
- **Firebase Backend-as-a-Service (BaaS)** - No custom backend server needed
  - Direct client-to-Firebase communication
  - Firebase SDK handles authentication, database operations, and file storage
  - Optional Cloud Functions for complex business logic (stock validation, order processing)

```
┌─────────────────────────────────────────────────────────────┐
│              Single Flutter Application                      │
│  ┌──────────────────────────────────────────────────────┐  │
│  │                                                        │  │
│  │  ┌─────────────────┐      ┌─────────────────┐       │  │
│  │  │  Customer UI    │      │   Admin UI      │       │  │
│  │  │  - Browse       │      │   - Inventory   │       │  │
│  │  │  - Cart         │      │   - Orders      │       │  │
│  │  │  - Orders       │      │   - Reports     │       │  │
│  │  └─────────────────┘      └─────────────────┘       │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │         Shared Business Logic Layer          │   │  │
│  │  │  - Services (Product, Cart, Order, Auth)     │   │  │
│  │  │  - State Management (Provider/Riverpod)      │   │  │
│  │  │  - Data Models                               │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  │                                                        │  │
│  │  ┌──────────────────────────────────────────────┐   │  │
│  │  │         Firebase SDK Integration             │   │  │
│  │  └──────────────────────────────────────────────┘   │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                            │
                            │ Firebase SDK (Direct)
                            │
┌─────────────────────────────────────────────────────────────┐
│                  Firebase Backend (BaaS)                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Firebase Authentication (Phone Auth)                 │  │
│  │  - OTP generation and verification                    │  │
│  │  - User session management                            │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cloud Firestore (NoSQL Database)                    │  │
│  │  - Products, Orders, Customers, Carts                │  │
│  │  - Real-time sync                                     │  │
│  │  - Security Rules for access control                 │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Firebase Storage                                     │  │
│  │  - Product images                                     │  │
│  └──────────────────────────────────────────────────────┘  │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  Cloud Functions (Optional - for complex logic)      │  │
│  │  - Stock validation triggers                          │  │
│  │  - Order processing workflows                         │  │
│  │  - Automated notifications                            │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Key Architectural Decisions:**

1. **Single Application, Multiple Interfaces:**
   - One Flutter app with role-based routing
   - Admin users see admin dashboard after login
   - Customer users see shopping interface
   - Reduces maintenance overhead and ensures consistency
   - Shared business logic and data models

2. **No Custom Backend Server:**
   - Firebase provides backend functionality out-of-the-box
   - Client communicates directly with Firebase services via SDK
   - Eliminates need for custom API development and server maintenance
   - Reduces costs (no server hosting fees)
   - Firebase Security Rules enforce access control at database level

3. **Optional Cloud Functions:**
   - Used only for complex server-side logic that can't run on client
   - Examples: stock validation during concurrent orders, scheduled tasks
   - Keeps most logic in Flutter app for simplicity
   - Free tier: 2M invocations/month (sufficient for 100 orders/day)

### Technology Stack

**Frontend (Single Application):**
- Flutter SDK 3.x (cross-platform mobile development for Android & iOS)
- Provider or Riverpod for state management
- Firebase SDK for Flutter (direct backend integration)
- Material Design 3 for UI components

**Backend (Backend-as-a-Service):**
- Firebase Authentication (phone number authentication with free tier: unlimited users)
- Cloud Firestore (NoSQL database with free tier: 1GB storage, 50K reads/day, 20K writes/day)
- Firebase Cloud Functions (optional serverless compute with free tier: 2M invocations/month)
- Firebase Storage (file storage with free tier: 5GB storage, 1GB/day downloads)
- Firebase Security Rules (database-level access control)

**Development Tools:**
- Firebase Emulator Suite (local development and testing)
- Flutter DevTools (debugging and performance profiling)

**Why No Custom Backend Server:**
- Firebase SDK allows direct client-to-database communication
- Security Rules enforce access control at the database level
- Reduces development time and complexity
- Eliminates server hosting and maintenance costs
- Built-in real-time synchronization
- Automatic scaling handled by Firebase

**Cost Justification:**
- Firebase free tier supports 10,000 customers and 100 orders/day comfortably
- No server maintenance costs
- Pay-as-you-grow pricing model
- Built-in security, authentication, and real-time capabilities
- Single application reduces development and maintenance overhead

## Components and Interfaces

### 1. Authentication Service

**Responsibilities:**
- Handle customer registration with mobile number
- Send and verify OTP codes
- Manage user sessions
- Handle admin authentication

**Key Methods:**
```dart
Future<void> registerCustomer(String phoneNumber, String name, String address)
Future<void> sendVerificationCode(String phoneNumber)
Future<User> verifyCode(String phoneNumber, String code)
Future<void> logout()
Future<bool> isAdmin(String userId)
```

### 2. Product Service

**Responsibilities:**
- Fetch product listings with filtering and search
- Retrieve product details
- Check stock availability
- Manage product categories

**Key Methods:**
```dart
Future<List<Product>> getProducts({String? category, String? searchQuery})
Future<Product> getProductById(String productId)
Future<bool> checkStockAvailability(String productId, int quantity)
Future<List<String>> getCategories()
```

### 3. Address Service

**Responsibilities:**
- Manage customer delivery addresses
- Set default address
- Validate address data

**Key Methods:**
```dart
Future<Address> addAddress(String customerId, Address address)
Future<List<Address>> getCustomerAddresses(String customerId)
Future<Address> getAddressById(String addressId)
Future<void> updateAddress(String addressId, Address address)
Future<void> deleteAddress(String addressId)
Future<void> setDefaultAddress(String customerId, String addressId)
Future<Address?> getDefaultAddress(String customerId)
```

### 4. Cart Service

**Responsibilities:**
- Add/remove items from cart
- Update item quantities
- Calculate cart totals
- Validate cart against stock

**Key Methods:**
```dart
Future<void> addToCart(String productId, int quantity)
Future<void> removeFromCart(String productId)
Future<void> updateQuantity(String productId, int quantity)
Future<Cart> getCart()
Future<bool> validateCartStock()
Future<double> calculateTotal()
```

### 5. Order Service

**Responsibilities:**
- Create orders from cart
- Update order status
- Retrieve order history
- Manage order fulfillment
- Handle order cancellation

**Key Methods:**
```dart
Future<Order> createOrder(String addressId)
Future<List<Order>> getCustomerOrders(String customerId)
Future<Order> getOrderById(String orderId)
Future<void> updateOrderStatus(String orderId, OrderStatus status)
Future<void> cancelOrder(String orderId)
```

### 6. Admin Service

**Responsibilities:**
- Manage product inventory (CRUD operations)
- Update stock quantities
- View and manage all orders
- Generate inventory reports

**Key Methods:**
```dart
Future<void> addProduct(Product product)
Future<void> updateProduct(String productId, Product product)
Future<void> deleteProduct(String productId)
Future<void> updateStock(String productId, int quantity)
Future<List<Order>> getAllOrders({OrderStatus? status})
Future<List<Product>> getLowStockProducts(int threshold)
```

## UI/UX Design

### Design Principles
- Clean, minimal interface focused on ease of use
- Material Design 3 components for consistency
- Clear visual hierarchy with product images as focal points
- Accessible color contrast and touch targets
- Responsive layout adapting to different screen sizes

### Customer Interface Screens

#### 1. Authentication Screens

**Login/Registration Screen**
```
┌─────────────────────────────────┐
│  ← Back                         │
│                                 │
│     [Grocery Basket Icon]       │
│                                 │
│     Welcome to Kirana           │
│     Fresh groceries delivered   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ +91 |_______________|   │   │
│  │     Enter mobile number │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Send OTP              │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**OTP Verification Screen**
```
┌─────────────────────────────────┐
│  ← Back                         │
│                                 │
│     Enter Verification Code     │
│     Sent to +91 98765xxxxx      │
│                                 │
│  ┌───┐ ┌───┐ ┌───┐ ┌───┐      │
│  │ _ │ │ _ │ │ _ │ │ _ │      │
│  └───┘ └───┘ └───┘ └───┘      │
│                                 │
│     Resend OTP in 0:45          │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Verify & Continue     │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 2. Product Browsing Screens

**Home/Product List Screen**
```
┌─────────────────────────────────┐
│  ☰  Kirana          🔍  🛒(3)  │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ 🔍 Search products...   │   │
│  └─────────────────────────┘   │
│                                 │
│  Categories:                    │
│  [All] [Fruits] [Vegetables]    │
│  [Dairy] [Snacks] [Beverages]   │
│                                 │
│  ┌─────────────┬─────────────┐ │
│  │ [Image]     │ [Image]     │ │
│  │ Tomatoes    │ Onions      │ │
│  │ ₹40/kg      │ ₹30/kg      │ │
│  │ In Stock    │ In Stock    │ │
│  │ [+ Add]     │ [+ Add]     │ │
│  ├─────────────┼─────────────┤ │
│  │ [Image]     │ [Image]     │ │
│  │ Milk        │ Bread       │ │
│  │ ₹60/L       │ ₹40/pack    │ │
│  │ In Stock    │ Low Stock   │ │
│  │ [+ Add]     │ [+ Add]     │ │
│  └─────────────┴─────────────┘ │
│                                 │
│  [Load More...]                 │
│                                 │
├─────────────────────────────────┤
│  🏠 Home  🛒 Cart  📦 Orders   │
└─────────────────────────────────┘
```

**Product Detail Screen**
```
┌─────────────────────────────────┐
│  ← Back              🛒(3)      │
├─────────────────────────────────┤
│                                 │
│     [Large Product Image]       │
│                                 │
│  Fresh Tomatoes                 │
│  ₹40 per kg                     │
│  ⭐ 4.5 (120 reviews)           │
│                                 │
│  Description:                   │
│  Fresh, locally sourced         │
│  tomatoes. Perfect for salads   │
│  and cooking.                   │
│                                 │
│  Unit Size: 1 kg                │
│  Stock: 50 kg available         │
│  Category: Vegetables           │
│                                 │
│  Quantity:                      │
│  ┌───┐  ┌───┐  ┌───┐          │
│  │ - │  │ 1 │  │ + │          │
│  └───┘  └───┘  └───┘          │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Add to Cart - ₹40     │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 3. Cart Screen

```
┌─────────────────────────────────┐
│  ← Back         My Cart         │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Img] Tomatoes          │   │
│  │       ₹40/kg            │   │
│  │       [-] 2 [+]  ₹80  🗑│   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Img] Milk              │   │
│  │       ₹60/L             │   │
│  │       [-] 1 [+]  ₹60  🗑│   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Img] Bread             │   │
│  │       ₹40/pack          │   │
│  │       [-] 1 [+]  ₹40  🗑│   │
│  └─────────────────────────┘   │
│                                 │
│  ─────────────────────────────  │
│  Subtotal:              ₹180    │
│  Delivery:              Free    │
│  ─────────────────────────────  │
│  Total:                 ₹180    │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Proceed to Checkout   │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 4. Checkout Screen

```
┌─────────────────────────────────┐
│  ← Back         Checkout        │
├─────────────────────────────────┤
│                                 │
│  Delivery Address               │
│  ┌─────────────────────────┐   │
│  │ ☑ Home (Default)        │   │
│  │ 123 Main Street         │   │
│  │ Apartment 4B            │   │
│  │ City, State - 123456    │   │
│  │ Contact: +91 9876543210 │   │
│  └─────────────────────────┘   │
│  ┌─────────────────────────┐   │
│  │ ☐ Office                │   │
│  │ 456 Business Park       │   │
│  │ Floor 3, Building A     │   │
│  │ City, State - 123457    │   │
│  │ Contact: +91 9876543211 │   │
│  └─────────────────────────┘   │
│                                 │
│  [+ Add New Address]            │
│                                 │
│  Order Summary                  │
│  • Tomatoes (2kg)       ₹80     │
│  • Milk (1L)            ₹60     │
│  • Bread (1pack)        ₹40     │
│  ─────────────────────────────  │
│  Total:                 ₹180    │
│                                 │
│  Payment Method                 │
│  ☑ Cash on Delivery             │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Place Order           │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 5. Order Confirmation Screen

```
┌─────────────────────────────────┐
│                                 │
│         ✓                       │
│    Order Placed!                │
│                                 │
│  Order ID: #ORD123456           │
│  Total: ₹180                    │
│                                 │
│  Your order will be delivered   │
│  to your address soon.          │
│                                 │
│  Payment: Cash on Delivery      │
│                                 │
│  ┌─────────────────────────┐   │
│  │   View Order Details    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Continue Shopping     │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 6. Order History Screen

```
┌─────────────────────────────────┐
│  ☰  My Orders                   │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────┐   │
│  │ Order #ORD123456        │   │
│  │ Jan 24, 2026            │   │
│  │ Status: Delivered ✓     │   │
│  │ Total: ₹180             │   │
│  │ 3 items                 │   │
│  │              [View >]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Order #ORD123455        │   │
│  │ Jan 23, 2026            │   │
│  │ Status: Out for Delivery│   │
│  │ Total: ₹250             │   │
│  │ 5 items                 │   │
│  │              [View >]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Order #ORD123454        │   │
│  │ Jan 22, 2026            │   │
│  │ Status: Preparing       │   │
│  │ Total: ₹320             │   │
│  │ 4 items                 │   │
│  │              [View >]   │   │
│  └─────────────────────────┘   │
│                                 │
├─────────────────────────────────┤
│  🏠 Home  🛒 Cart  📦 Orders   │
└─────────────────────────────────┘
```

### Admin Interface Screens

#### 1. Admin Dashboard

```
┌─────────────────────────────────┐
│  ☰  Admin Dashboard    [Logout] │
├─────────────────────────────────┤
│                                 │
│  Quick Stats                    │
│  ┌──────┐ ┌──────┐ ┌──────┐   │
│  │ 1000 │ │  45  │ │  12  │   │
│  │Products│Orders│ Low   │   │
│  │      │ │Today │ Stock │   │
│  └──────┘ └──────┘ └──────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  📦 Manage Inventory    │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │  📋 Manage Orders       │   │
│  └─────────────────────────┘   │
│                                 │
│  Recent Orders                  │
│  ┌─────────────────────────┐   │
│  │ #ORD123456 - Pending    │   │
│  │ Customer: John Doe      │   │
│  │ ₹180            [View >]│   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ #ORD123455 - Confirmed  │   │
│  │ Customer: Jane Smith    │   │
│  │ ₹250            [View >]│   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 2. Inventory Management Screen

```
┌─────────────────────────────────┐
│  ← Back    Inventory    [+ Add] │
├─────────────────────────────────┤
│  ┌─────────────────────────┐   │
│  │ 🔍 Search products...   │   │
│  └─────────────────────────┘   │
│                                 │
│  Filter: [All] [Low Stock]      │
│  Sort: [Name] [Stock] [Price]   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Img] Tomatoes          │   │
│  │       ₹40/kg            │   │
│  │       Stock: 50 kg      │   │
│  │       Category: Veg     │   │
│  │       [Edit] [Delete]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ [Img] Milk              │   │
│  │       ₹60/L             │   │
│  │       Stock: 5 L ⚠️     │   │
│  │       Category: Dairy   │   │
│  │       [Edit] [Delete]   │   │
│  └─────────────────────────┘   │
│                                 │
│  [Load More...]                 │
│                                 │
└─────────────────────────────────┘
```

#### 3. Add/Edit Product Screen

```
┌─────────────────────────────────┐
│  ← Back      Add Product        │
├─────────────────────────────────┤
│                                 │
│  Product Image                  │
│  ┌─────────────────────────┐   │
│  │   [Upload Image]        │   │
│  │   or drag & drop        │   │
│  └─────────────────────────┘   │
│                                 │
│  Product Name *                 │
│  ┌─────────────────────────┐   │
│  │ _____________________   │   │
│  └─────────────────────────┘   │
│                                 │
│  Description                    │
│  ┌─────────────────────────┐   │
│  │ _____________________   │   │
│  │ _____________________   │   │
│  └─────────────────────────┘   │
│                                 │
│  Price (₹) *    Unit Size *     │
│  ┌─────────┐   ┌───────────┐  │
│  │ _______ │   │ _________ │  │
│  └─────────┘   └───────────┘  │
│                                 │
│  Category *     Stock Qty *     │
│  ┌─────────┐   ┌───────────┐  │
│  │ [Select]│   │ _________ │  │
│  └─────────┘   └───────────┘  │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Save Product          │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

#### 4. Order Management Screen

```
┌─────────────────────────────────┐
│  ← Back    Order Management     │
├─────────────────────────────────┤
│                                 │
│  Filter by Status:              │
│  [All] [Pending] [Confirmed]    │
│  [Preparing] [Out for Delivery] │
│  [Delivered] [Cancelled]        │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Order #ORD123456        │   │
│  │ Customer: John Doe      │   │
│  │ Phone: +91 9876543210   │   │
│  │ Status: Pending         │   │
│  │ Total: ₹180             │   │
│  │ Date: Jan 24, 2026      │   │
│  │              [View >]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │ Order #ORD123455        │   │
│  │ Customer: Jane Smith    │   │
│  │ Phone: +91 9876543211   │   │
│  │ Status: Confirmed       │   │
│  │ Total: ₹250             │   │
│  │ Date: Jan 23, 2026      │   │
│  │              [View >]   │   │
│  └─────────────────────────┘   │
│                                 │
│  [Load More...]                 │
│                                 │
└─────────────────────────────────┘
```

#### 5. Order Detail Screen (Admin)

```
┌─────────────────────────────────┐
│  ← Back    Order #ORD123456     │
├─────────────────────────────────┤
│                                 │
│  Customer Information           │
│  Name: John Doe                 │
│  Phone: +91 9876543210          │
│  Address: 123 Main Street       │
│           Apartment 4B          │
│           City, State - 123456  │
│                                 │
│  Order Details                  │
│  Date: Jan 24, 2026 10:30 AM    │
│  Payment: Cash on Delivery      │
│                                 │
│  Items Ordered                  │
│  • Tomatoes (2kg)       ₹80     │
│  • Milk (1L)            ₹60     │
│  • Bread (1pack)        ₹40     │
│  ─────────────────────────────  │
│  Total:                 ₹180    │
│                                 │
│  Current Status: Pending        │
│                                 │
│  Update Status:                 │
│  ┌─────────────────────────┐   │
│  │ [Select New Status ▼]   │   │
│  └─────────────────────────┘   │
│                                 │
│  ┌─────────────────────────┐   │
│  │   Update Status         │   │
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

### Navigation Flow

**Customer Flow:**
```
Login → Home/Browse → Product Details → Cart → Checkout → Order Confirmation
                ↓                         ↓
              Search                  Order History
```

**Admin Flow:**
```
Admin Login → Dashboard → Inventory Management → Add/Edit Product
                    ↓
              Order Management → Order Details → Update Status
```

### Color Scheme (Suggested)
- Primary: Green (#4CAF50) - Fresh, grocery theme
- Secondary: Orange (#FF9800) - Call-to-action buttons
- Background: White (#FFFFFF)
- Text: Dark Gray (#212121)
- Error: Red (#F44336)
- Success: Green (#4CAF50)
- Warning: Amber (#FFC107)

### Typography
- Headings: Roboto Bold, 20-24px
- Body: Roboto Regular, 14-16px
- Captions: Roboto Regular, 12px
- Buttons: Roboto Medium, 16px

## Data Models

### Firestore Database Schema

**Collection Structure:**

```
/customers/{customerId}
  - id: string
  - phoneNumber: string (encrypted)
  - name: string
  - defaultAddressId: string (reference to addresses collection)
  - isAdmin: boolean
  - createdAt: timestamp
  - lastLogin: timestamp

/addresses/{addressId}
  - id: string
  - customerId: string
  - label: string
  - fullAddress: string (encrypted)
  - landmark: string (optional)
  - contactNumber: string (encrypted)
  - isDefault: boolean
  - createdAt: timestamp
  - updatedAt: timestamp

/products/{productId}
  - id: string
  - name: string
  - description: string
  - price: number
  - category: string
  - unitSize: string
  - stockQuantity: number
  - imageUrl: string
  - isActive: boolean
  - createdAt: timestamp
  - updatedAt: timestamp
  - searchKeywords: array<string> (for search optimization)

/carts/{customerId}
  - customerId: string
  - items: array<CartItem>
  - totalAmount: number
  - updatedAt: timestamp

/orders/{orderId}
  - id: string
  - customerId: string
  - customerName: string
  - customerPhone: string (encrypted)
  - items: array<OrderItem>
  - totalAmount: number
  - addressId: string (reference to address used)
  - deliveryAddress: map (snapshot of address at order time)
    - label: string
    - fullAddress: string (encrypted)
    - landmark: string
    - contactNumber: string (encrypted)
  - status: string (enum)
  - paymentMethod: string
  - createdAt: timestamp
  - deliveredAt: timestamp (nullable)
  - statusHistory: array<StatusChange>

/verificationCodes/{phoneNumber}
  - phoneNumber: string
  - codeHash: string (hashed OTP)
  - expiresAt: timestamp
  - attempts: number
  - createdAt: timestamp

/auditLogs/{logId}
  - adminId: string
  - action: string
  - resourceType: string
  - resourceId: string
  - timestamp: timestamp
  - details: map
```

**Indexes Required:**
- addresses: (customerId, isDefault)
- addresses: (customerId, createdAt DESC)
- products: (category, isActive)
- products: (searchKeywords, isActive)
- orders: (customerId, createdAt DESC)
- orders: (status, createdAt DESC)
- products: (stockQuantity ASC) for low stock queries

### Firebase Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/customers/$(request.auth.uid)).data.isAdmin == true;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    // Address rules
    match /addresses/{addressId} {
      allow read: if isOwner(resource.data.customerId) || isAdmin();
      allow create: if isAuthenticated() && isOwner(request.resource.data.customerId);
      allow update: if isOwner(resource.data.customerId);
      allow delete: if isOwner(resource.data.customerId);
    }
    
    // Customer rules
    match /customers/{customerId} {
      allow read: if isOwner(customerId) || isAdmin();
      allow create: if isAuthenticated();
      allow update: if isOwner(customerId);
      allow delete: if false; // No deletion allowed
    }
    
    // Product rules
    match /products/{productId} {
      allow read: if true; // Public read for browsing
      allow write: if isAdmin(); // Only admins can modify
    }
    
    // Cart rules
    match /carts/{customerId} {
      allow read, write: if isOwner(customerId);
    }
    
    // Order rules
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.customerId) || isAdmin();
      allow create: if isAuthenticated() && isOwner(request.resource.data.customerId);
      allow update: if isAdmin(); // Only admins can update order status
      allow delete: if false; // No deletion allowed
    }
    
    // Verification codes (server-side only via Cloud Functions)
    match /verificationCodes/{phoneNumber} {
      allow read, write: if false; // Only Cloud Functions can access
    }
    
    // Audit logs (admin read-only)
    match /auditLogs/{logId} {
      allow read: if isAdmin();
      allow write: if false; // Only Cloud Functions can write
    }
  }
}
```

### State Management Architecture

**Using Provider Pattern:**

```
App State Hierarchy:
├── AuthProvider (user authentication state)
│   ├── currentUser
│   ├── isAdmin
│   └── authStatus
├── ProductProvider (product catalog state)
│   ├── products
│   ├── categories
│   ├── searchResults
│   └── selectedProduct
├── CartProvider (shopping cart state)
│   ├── cartItems
│   ├── totalAmount
│   └── itemCount
├── OrderProvider (order management state)
│   ├── customerOrders
│   ├── allOrders (admin only)
│   └── selectedOrder
└── AdminProvider (admin-specific state)
    ├── inventory
    ├── lowStockProducts
    └── orderStats
```

**State Flow:**
1. User actions trigger provider methods
2. Providers update Firestore via services
3. Firestore real-time listeners update provider state
4. UI rebuilds automatically via Consumer widgets

### Offline Support Strategy

**Firestore Offline Persistence:**
- Enable Firestore offline persistence for seamless offline experience
- Cache product catalog locally
- Queue cart operations when offline
- Sync automatically when connection restored

**Implementation:**
```dart
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
);
```

**Offline Behavior:**
- **Product Browsing:** Show cached products with "Offline" indicator
- **Cart Operations:** Queue locally, sync when online
- **Order Placement:** Require online connection (show error if offline)
- **Search:** Use cached data with limited results indicator

### Image Management

**Product Image Upload (Admin):**
1. Admin selects image from device
2. Image compressed to max 800x800px, <500KB
3. Upload to Firebase Storage: `/products/{productId}/image.jpg`
4. Get download URL
5. Store URL in Firestore product document

**Image Display (Customer):**
1. Load images with caching using `cached_network_image` package
2. Show placeholder while loading
3. Lazy load images in lists
4. Preload images for product details

**Storage Structure:**
```
/products/
  /{productId}/
    /image.jpg (main product image)
    /thumbnail.jpg (optional, for list views)
```

### Search and Filtering Implementation

**Search Strategy:**
1. **Client-Side Search** (for small datasets <1000 products):
   - Load all products into memory
   - Filter locally using Dart string matching
   - Fast and free (no additional Firestore reads)

2. **Firestore Query** (for larger datasets):
   - Use `searchKeywords` array field
   - Query: `where('searchKeywords', arrayContains: searchTerm.toLowerCase())`
   - Generate keywords on product creation (name words, category)

**Filtering:**
- Category filter: `where('category', '==', selectedCategory)`
- Stock filter: `where('stockQuantity', '>', 0)`
- Combine with: `where('isActive', '==', true)`

**Search Keywords Generation:**
```dart
List<String> generateSearchKeywords(String name, String category) {
  final keywords = <String>{};
  keywords.add(name.toLowerCase());
  keywords.add(category.toLowerCase());
  keywords.addAll(name.toLowerCase().split(' '));
  return keywords.toList();
}
```

### Pagination Strategy

**Product Listing:**
- Load 20 products per page
- Use Firestore `limit()` and `startAfter()` for pagination
- Implement infinite scroll with loading indicator

**Order History:**
- Load 10 orders per page
- Sort by `createdAt` descending (most recent first)
- Use pagination for customers with many orders

**Implementation:**
```dart
Query query = FirebaseFirestore.instance
    .collection('products')
    .where('isActive', isEqualTo: true)
    .orderBy('name')
    .limit(20);

// For next page
if (lastDocument != null) {
  query = query.startAfterDocument(lastDocument);
}
```

### Admin User Management

**Admin Account Creation:**
- Initial admin created manually in Firebase Console
- Admin can create additional admin accounts through admin panel
- Admin flag stored in customer document: `isAdmin: true`

**Admin Authentication Flow:**
1. Admin logs in with phone number (same as customer)
2. After OTP verification, check `isAdmin` flag
3. Route to admin dashboard if admin, customer home if not
4. Admin session managed same as customer session

**Admin Permissions:**
- Full access to inventory management
- Full access to order management
- View all customer orders
- Cannot delete orders or customers (audit trail)
- All admin actions logged in auditLogs collection

### Profile Management

**Customer Profile Editing:**
- Edit name
- Edit default delivery address
- View order history
- Logout

**Profile Update Flow:**
1. Customer navigates to profile screen
2. Edits fields
3. Validates input (non-empty name, valid address)
4. Updates Firestore customer document
5. Shows success message

**Data Validation:**
- Name: 2-50 characters, letters and spaces only
- Address: 10-200 characters
- Phone number: Cannot be changed (used for authentication)

### Notification System

**Notification Strategy:**
- **Primary:** In-app notifications (stored in Firestore, displayed in app)
- **Future Enhancement:** Push notifications via Firebase Cloud Messaging (FCM)

**In-App Notification Implementation:**

**Firestore Collection:**
```
/notifications/{notificationId}
  - customerId: string
  - orderId: string
  - type: string (order_status_change, order_confirmed, etc.)
  - title: string
  - message: string
  - isRead: boolean
  - createdAt: timestamp
```

**Notification Triggers:**
1. Order status changes (admin updates order)
2. Order confirmation (customer places order)
3. Low stock alerts (admin only)

**Notification Flow:**
1. Admin updates order status
2. Cloud Function or client-side code creates notification document
3. Customer app listens to notifications collection
4. Unread notifications shown with badge count
5. Customer taps notification to view order details

**Notification Display:**
- Bell icon in app bar with unread count badge
- Notification list screen showing all notifications
- Mark as read when viewed
- Auto-delete notifications older than 30 days

### Security Implementation Details

**Encryption:**
- **Algorithm:** AES-256-GCM for sensitive data at rest
- **Key Management:** Firebase App Check for app attestation
- **Fields Encrypted:** phoneNumber, deliveryAddress, contactNumber

**Hashing:**
- **Algorithm:** bcrypt with cost factor 12 for verification codes
- **Salt:** Automatically generated per code
- **Storage:** Only hash stored, never plaintext

**Rate Limiting:**
- **OTP Requests:** Maximum 3 requests per phone number per hour
- **Login Attempts:** Maximum 5 failed attempts per hour
- **Implementation:** Track attempts in verificationCodes collection
- **Reset:** Automatic after 1 hour

**Session Management:**
- **Token Expiry:** 7 days for customer, 24 hours for admin
- **Refresh:** Automatic token refresh before expiry
- **Revocation:** Logout clears all session tokens

### Conflict Resolution Strategy

**Cart Conflicts (Offline Edits):**
- **Strategy:** Last-write-wins with timestamp comparison
- **Implementation:** Firestore automatically handles with server timestamp
- **User Experience:** Show warning if cart was modified on another device

**Stock Conflicts (Concurrent Orders):**
- **Strategy:** Firestore transactions with retry logic
- **Implementation:**
  ```dart
  await FirebaseFirestore.instance.runTransaction((transaction) async {
    // Read current stock
    // Validate sufficient stock
    // Deduct stock
    // Create order
    // If any step fails, entire transaction rolls back
  });
  ```
- **User Experience:** Show error if stock insufficient, suggest reducing quantity

### Initial Setup Guide

**Creating First Admin User:**

1. **Create Firebase Project:**
   - Go to Firebase Console (console.firebase.google.com)
   - Create new project: "kirana-grocery-app"
   - Enable Google Analytics (optional)

2. **Enable Authentication:**
   - Navigate to Authentication > Sign-in method
   - Enable Phone authentication
   - Configure reCAPTCHA (for web)

3. **Create Firestore Database:**
   - Navigate to Firestore Database
   - Create database in production mode
   - Choose region (closest to users)

4. **Deploy Security Rules:**
   - Copy security rules from design document
   - Deploy via Firebase Console or CLI

5. **Create First Admin:**
   - Navigate to Authentication > Users
   - Add user manually with phone number
   - Copy the generated UID
   - Navigate to Firestore Database
   - Create document in `customers` collection:
     ```
     Document ID: <copied UID>
     Fields:
       - id: <copied UID>
       - phoneNumber: "+919876543210" (encrypted)
       - name: "Admin User"
       - defaultAddress: "Admin Office"
       - isAdmin: true
       - createdAt: <current timestamp>
       - lastLogin: <current timestamp>
     ```

6. **Configure Firebase Storage:**
   - Navigate to Storage
   - Create default bucket
   - Deploy storage rules (allow authenticated writes to /products/)

7. **Enable Firestore Offline Persistence:**
   - Configured in Flutter app initialization

### Monitoring and Analytics

**Key Metrics to Track:**

**Business Metrics:**
- Order completion rate (orders placed / carts created)
- Average order value
- Cart abandonment rate
- Products per order
- Revenue per day/week/month
- Top-selling products
- Low stock alerts triggered

**Technical Metrics:**
- API response times (p50, p95, p99)
- Error rates by type and endpoint
- Crash-free sessions percentage
- App startup time
- Image load times
- Search query latency
- Order placement success rate

**User Metrics:**
- Daily/Monthly active users
- Session duration
- Screens per session
- User retention (Day 1, Day 7, Day 30)
- Feature adoption rates

**Implementation:**
- Firebase Analytics for user behavior
- Firebase Performance Monitoring for technical metrics
- Firebase Crashlytics for crash reporting
- Custom events for business metrics:
  ```dart
  FirebaseAnalytics.instance.logEvent(
    name: 'order_placed',
    parameters: {
      'order_value': totalAmount,
      'item_count': items.length,
      'payment_method': 'cod',
    },
  );
  ```

**Monitoring Dashboards:**
- Firebase Console for real-time metrics
- Custom dashboard for business KPIs
- Alert rules for critical errors (>5% error rate, >3s response time)

### Backup and Disaster Recovery

**Firestore Backup Strategy:**
- **Automated Backups:** Enable Firestore automatic backups (daily)
- **Retention:** 30 days of backup history
- **Location:** Same region as primary database
- **Cost:** Included in Firebase pricing

**Backup Configuration:**
```bash
# Using Firebase CLI
firebase firestore:backup --project kirana-grocery-app
```

**Recovery Procedures:**
1. Identify backup point (date/time)
2. Create new Firestore database
3. Restore from backup
4. Update app configuration to point to restored database
5. Verify data integrity
6. Switch traffic to restored database

**Data Export (for compliance):**
- Monthly export to Cloud Storage
- Format: JSON or CSV
- Retention: 1 year
- Encryption: AES-256

### Testing Strategy - Property Mapping

**Property-Based Tests (36 properties):**

| Property | Test Type | Priority | Generator Strategy |
|----------|-----------|----------|-------------------|
| 1. Product listing displays fields | Property | High | Generate random products, verify display |
| 2. Search returns matching items | Property | High | Generate inventory + queries, verify matches |
| 3. Product details complete | Property | Medium | Generate products, verify all fields present |
| 4. Category filter correct | Property | High | Generate multi-category inventory, verify filter |
| 5. Add to cart preserves data | Property | High | Generate items + quantities, verify cart |
| 6. Cart display complete | Property | High | Generate carts, verify display fields |
| 7. Quantity update recalculates | Property | High | Generate carts, modify quantities, verify totals |
| 8. Item removal updates cart | Property | High | Generate carts, remove items, verify state |
| 9. Order creation transfers data | Property | High | Generate carts, create orders, verify transfer |
| 10. Order reduces stock | Property | Critical | Generate orders, verify stock reduction |
| 11. Order clears cart | Property | High | Generate orders, verify cart empty |
| 12. Order history displays fields | Property | Medium | Generate order histories, verify display |
| 13. Order details complete | Property | Medium | Generate orders, verify all fields |
| 14. Status changes reflected | Property | High | Update statuses, verify display updates |
| 15. Product creation stores fields | Property | High | Generate product data, verify storage |
| 16. Product updates persist | Property | High | Generate updates, verify persistence |
| 17. Stock updates persist | Property | High | Generate stock changes, verify persistence |
| 18. Deleted products hidden | Property | High | Delete products, verify not in search |
| 19. Inventory displays all | Property | Medium | Generate inventory, verify display |
| 20. Order management displays fields | Property | Medium | Generate orders, verify admin display |
| 21. Order status filter correct | Property | High | Generate orders, filter, verify results |
| 22. Admin order details complete | Property | Medium | Generate orders, verify admin view |
| 23. Order status updates persist | Property | High | Update statuses, verify persistence |
| 24. Registration creates account | Property | High | Generate customer data, verify creation |
| 25. Login generates code | Property | High | Generate phone numbers, verify code creation |
| 26. Valid code authenticates | Property | High | Generate codes, verify authentication |
| 27. Profile updates persist | Property | Medium | Generate updates, verify persistence |
| 28. Logout clears session | Property | High | Logout, verify session cleared |
| 29. Admin credentials grant access | Property | High | Generate admin logins, verify access |
| 30. Expired session requires reauth | Property | High | Simulate expiry, verify reauth required |
| 31. Failed transactions preserve stock | Property | Critical | Simulate failures, verify stock unchanged |
| 32. Errors logged | Property | Medium | Generate errors, verify logging |
| 33. Sensitive data encrypted | Property | Critical | Generate customer data, verify encryption |
| 34. Users access own data only | Property | Critical | Generate access attempts, verify isolation |
| 35. Admin access logged | Property | High | Generate admin actions, verify logging |
| 36. Codes hashed | Property | Critical | Generate codes, verify hashing |

**Test Implementation Priority:**
1. **Critical (4 properties):** 10, 31, 33, 34, 36 - Core security and data integrity
2. **High (22 properties):** Most functional requirements
3. **Medium (10 properties):** Display and reporting features

**Generator Examples:**
```dart
// Product generator
Product generateRandomProduct() {
  return Product(
    id: uuid.v4(),
    name: faker.food.dish(),
    price: faker.randomGenerator.decimal(min: 10, scale: 100),
    category: faker.randomGenerator.element(['Fruits', 'Vegetables', 'Dairy']),
    stockQuantity: faker.randomGenerator.integer(100),
    // ... other fields
  );
}

// Cart generator with edge cases
Cart generateRandomCart({bool includeOutOfStock = false}) {
  final items = List.generate(
    faker.randomGenerator.integer(10, min: 1),
    (_) => generateRandomCartItem(outOfStock: includeOutOfStock),
  );
  return Cart(items: items, /* ... */);
}
```

## Data Models

### Customer
```dart
class Customer {
  String id;
  String phoneNumber;
  String name;
  String defaultAddressId;  // Reference to default address
  DateTime createdAt;
  DateTime lastLogin;
}
```

### Address
```dart
class Address {
  String id;
  String customerId;
  String label;  // e.g., "Home", "Office", "Mom's House"
  String fullAddress;  // Complete address string
  String? landmark;  // Optional landmark for easier delivery
  String contactNumber;  // Contact number for this address
  bool isDefault;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### Product
```dart
class Product {
  String id;
  String name;
  String description;
  double price;
  String category;
  String unitSize;  // e.g., "1kg", "500ml"
  int stockQuantity;
  String imageUrl;
  bool isActive;
  DateTime createdAt;
  DateTime updatedAt;
}
```

### CartItem
```dart
class CartItem {
  String productId;
  String productName;
  double price;
  int quantity;
  String imageUrl;
}
```

### Cart
```dart
class Cart {
  String customerId;
  List<CartItem> items;
  double totalAmount;
  DateTime updatedAt;
}
```

### Order
```dart
class Order {
  String id;
  String customerId;
  String customerName;
  String customerPhone;
  List<OrderItem> items;
  double totalAmount;
  String addressId;  // Reference to address used for this order
  Address deliveryAddress;  // Snapshot of address at order time
  OrderStatus status;
  PaymentMethod paymentMethod;  // Always COD for now
  DateTime createdAt;
  DateTime? deliveredAt;
}

enum OrderStatus {
  pending,
  confirmed,
  preparing,
  outForDelivery,
  delivered,
  cancelled
}

enum PaymentMethod {
  cashOnDelivery
}
```

### OrderItem
```dart
class OrderItem {
  String productId;
  String productName;
  double price;
  int quantity;
  double subtotal;
}
```

### Admin
```dart
class Admin {
  String id;
  String username;
  String phoneNumber;
  DateTime createdAt;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*


### Property 1: Product listing displays all required fields
*For any* product in the inventory, when displayed in the product list, the rendered output should contain the product name, image, price, and stock status.
**Validates: Requirement 1, Acceptance Criteria 1.1**

### Property 2: Search returns only matching items
*For any* search query and inventory data, all returned items should have names or categories that match the search criteria.
**Validates: Requirement 1, Acceptance Criteria 1.2**

### Property 3: Product details contain complete information
*For any* product, when viewing its details, the display should include description, price, unit size, and available stock quantity.
**Validates: Requirement 1, Acceptance Criteria 1.3**

### Property 4: Category filter returns only matching items
*For any* selected category and inventory data, all returned items should belong to the selected category.
**Validates: Requirement 1, Acceptance Criteria 1.5**

### Property 5: Add to cart preserves item and quantity
*For any* item and valid quantity, after adding to cart, the cart should contain that item with the specified quantity.
**Validates: Requirement 2, Acceptance Criteria 2.1**

### Property 6: Cart display shows complete information
*For any* cart with items, the display should show all items with their quantities, individual prices, and the correct total cost.
**Validates: Requirement 2, Acceptance Criteria 2.3**

### Property 7: Quantity update recalculates total correctly
*For any* cart item, when its quantity is modified, the cart total should be recalculated to reflect the new quantity.
**Validates: Requirement 2, Acceptance Criteria 2.4**

### Property 8: Item removal updates cart correctly
*For any* cart with multiple items, removing an item should result in that item being absent from the cart and the total being recalculated without that item.
**Validates: Requirement 2, Acceptance Criteria 2.5**

### Property 9: Cart persists across sessions
*For any* customer with items in cart, closing and reopening the application should restore the cart with all items and quantities intact.
**Validates: Requirement 2, Acceptance Criteria 2.6**

### Property 10: Order creation transfers all cart data
*For any* cart with items and delivery information, creating an order should result in an order containing all cart items, delivery details, and payment method set to Cash on Delivery.
**Validates: Requirement 3, Acceptance Criteria 3.2**

### Property 11: Order creation reduces stock quantities
*For any* order with items, after order creation, the stock quantity for each ordered item should be reduced by the ordered quantity.
**Validates: Requirement 3, Acceptance Criteria 3.3**

### Property 12: Order confirmation clears cart
*For any* customer cart, after successfully creating an order, the cart should be empty.
**Validates: Requirement 3, Acceptance Criteria 3.4**

### Property 13: Order history displays required fields
*For any* customer with orders, the order history display should show all orders with order ID, date, status, and total amount.
**Validates: Requirement 4, Acceptance Criteria 4.1**

### Property 14: Order details contain complete information
*For any* order, the detail view should display items, quantities, prices, delivery address, and current status.
**Validates: Requirement 4, Acceptance Criteria 4.2**

### Property 15: Status changes are reflected in order history
*For any* order, when its status is updated, the order history should display the new status.
**Validates: Requirement 4, Acceptance Criteria 4.3**

### Property 16: Order cancellation restores stock
*For any* order with status Pending or Confirmed, when cancelled, the stock quantities for all ordered items should be restored.
**Validates: Requirement 4, Acceptance Criteria 4.4**

### Property 17: Address creation stores all fields
*For any* address data with label, full address, landmark, and contact number, creating the address should store all fields correctly.
**Validates: Requirement 4A, Acceptance Criteria 4A.1**

### Property 18: Customer addresses display correctly
*For any* customer with saved addresses, retrieving addresses should return all addresses with complete details.
**Validates: Requirement 4A, Acceptance Criteria 4A.2**

### Property 19: Default address is set correctly
*For any* customer and address, marking an address as default should set isDefault to true and set all other addresses to false.
**Validates: Requirement 4A, Acceptance Criteria 4A.3**

### Property 20: Address updates persist changes
*For any* existing address and updated data, after updating, retrieving the address should return the updated information with the same address ID.
**Validates: Requirement 4A, Acceptance Criteria 4A.4**

### Property 21: Address deletion works correctly
*For any* address not used in existing orders, deleting should remove it from the customer's saved addresses.
**Validates: Requirement 4A, Acceptance Criteria 4A.5**

### Property 22: Product creation stores all fields
*For any* product data with name, description, price, category, unit size, and stock quantity, creating the product should result in all fields being stored in the inventory.
**Validates: Requirement 5, Acceptance Criteria 5.1**

### Property 18: Image upload accepts valid formats
*For any* JPG or PNG image under 500KB, uploading should succeed and store the image URL.
**Validates: Requirement 5, Acceptance Criteria 5.2**

### Property 19: Oversized images are compressed
*For any* image exceeding 500KB, the system should compress it to meet the size requirement before upload.
**Validates: Requirement 5, Acceptance Criteria 5.3**

### Property 20: Product updates persist changes
*For any* existing product and updated data, after updating the product, retrieving it should return the updated information.
**Validates: Requirement 5, Acceptance Criteria 5.4**

### Property 21: Stock updates persist new quantity
*For any* product and new stock quantity, after updating the stock, retrieving the product should show the new stock level.
**Validates: Requirement 5, Acceptance Criteria 5.5**

### Property 22: Deleted products don't appear in searches
*For any* product that has been deleted, searching for it by name or category should not return that product.
**Validates: Requirement 5, Acceptance Criteria 5.6**

### Property 23: Inventory display shows all items and stock
*For any* inventory, the admin inventory view should display all active products with their current stock levels.
**Validates: Requirement 5, Acceptance Criteria 5.7**

### Property 24: Order management displays all required fields
*For any* set of orders, the admin order management interface should display all orders with customer details, order date, status, and total amount.
**Validates: Requirement 6, Acceptance Criteria 6.1**

### Property 25: Order status filter returns only matching orders
*For any* order status filter and set of orders, all returned orders should have the selected status.
**Validates: Requirement 6, Acceptance Criteria 6.2**

### Property 26: Admin order details contain complete information
*For any* order, the admin detail view should display customer information, items, quantities, delivery address, and payment method.
**Validates: Requirement 6, Acceptance Criteria 6.3**

### Property 27: Order status updates persist and notify
*For any* order and new status, after updating the order status, retrieving the order should show the new status and a notification should be created for the customer.
**Validates: Requirement 6, Acceptance Criteria 6.4**

### Property 28: Customer registration creates account with all fields
*For any* customer data with mobile number, name, and address, registering should create an account containing all provided information.
**Validates: Requirement 7, Acceptance Criteria 7.1**

### Property 29: Login generates verification code
*For any* valid mobile number, initiating login should generate and store a verification code associated with that number.
**Validates: Requirement 7, Acceptance Criteria 7.2**

### Property 30: OTP rate limiting enforced
*For any* phone number with 3 OTP requests in the past hour, additional requests should be denied with a rate limit error.
**Validates: Requirement 7, Acceptance Criteria 7.3**

### Property 31: Valid verification code authenticates user
*For any* customer with a valid, non-expired verification code, entering the correct code should authenticate the customer and grant access.
**Validates: Requirement 7, Acceptance Criteria 7.4**

### Property 32: Profile updates persist changes
*For any* customer and updated profile information, after updating the profile, retrieving the customer data should show the updated information.
**Validates: Requirement 7, Acceptance Criteria 7.6**

### Property 33: Logout clears session
*For any* authenticated customer, after logging out, attempting to access protected resources should require re-authentication.
**Validates: Requirement 7, Acceptance Criteria 7.7**

### Property 34: Valid admin credentials grant access
*For any* admin with valid credentials, logging in should authenticate the admin and grant access to administrative functions.
**Validates: Requirement 8, Acceptance Criteria 8.1**

### Property 35: Expired admin session requires re-authentication
*For any* admin with an expired session, attempting administrative actions should require re-authentication.
**Validates: Requirement 8, Acceptance Criteria 8.3**

### Property 36: Failed transactions don't modify stock
*For any* order creation that fails, the stock quantities for all items should remain unchanged.
**Validates: Requirement 10, Acceptance Criteria 10.2**

### Property 37: Errors are logged with details
*For any* error that occurs in the application, the error should be logged with sufficient details for debugging.
**Validates: Requirement 10, Acceptance Criteria 10.4**

### Property 38: Sensitive data is encrypted at rest
*For any* customer data containing mobile numbers or addresses, the stored values should be encrypted, not plaintext.
**Validates: Requirement 11, Acceptance Criteria 11.2**

### Property 39: Users can only access their own data
*For any* authenticated customer, they should only be able to retrieve their own orders and profile information, not other customers' data.
**Validates: Requirement 11, Acceptance Criteria 11.3**

### Property 40: Admin data access is logged
*For any* admin accessing customer data, the access attempt should be logged with admin ID, customer ID, and timestamp.
**Validates: Requirement 11, Acceptance Criteria 11.4**

### Property 41: Verification codes are hashed
*For any* verification code stored in the system, it should be hashed using a secure algorithm, not stored in plaintext.
**Validates: Requirement 11, Acceptance Criteria 11.5**

## Error Handling

### Error Categories

**1. Validation Errors**
- Invalid input data (empty fields, invalid formats)
- Stock quantity exceeded
- Out of stock items
- Invalid verification codes

**Strategy:** Return user-friendly error messages with specific guidance on how to correct the input.

**2. Authentication/Authorization Errors**
- Invalid credentials
- Expired sessions
- Unauthorized access attempts

**Strategy:** Return clear error messages without exposing security details. Log all authentication failures for security monitoring.

**3. Business Logic Errors**
- Insufficient stock during checkout
- Order already processed
- Product not found

**Strategy:** Return descriptive error messages and maintain data consistency by rolling back partial changes.

**4. System Errors**
- Database connection failures
- External service unavailability (SMS provider)
- Network timeouts

**Strategy:** Log detailed error information, return generic user-friendly messages, implement retry logic for transient failures.

### Error Response Format

All API errors should follow a consistent format:

```dart
class AppError {
  String code;          // Machine-readable error code
  String message;       // User-friendly message
  String? details;      // Additional context (optional)
  DateTime timestamp;
}
```

### Transaction Management

For operations that modify multiple entities (e.g., order creation):
1. Use Firestore transactions to ensure atomicity
2. Validate all preconditions before making changes
3. Roll back all changes if any step fails
4. Log transaction failures for debugging

## Testing Strategy

### Unit Testing

**Framework:** Flutter's built-in test package

**Focus Areas:**
- Data model serialization/deserialization
- Business logic validation (stock checks, price calculations)
- State management logic
- Error handling paths

**Example Unit Tests:**
- Cart total calculation with various item combinations
- Stock validation with edge cases (zero stock, negative quantities)
- Order status transitions
- Authentication token validation

### Property-Based Testing

**Framework:** `test` package with custom property test utilities (or `dart_check` if available)

**Configuration:** Each property test should run a minimum of 100 iterations to ensure thorough coverage of the input space.

**Test Annotation Format:** Each property-based test MUST be tagged with a comment explicitly referencing the correctness property:
```dart
// Feature: online-grocery-app, Property 10: Order creation reduces stock quantities
```

**Key Properties to Test:**
- Property 10: Order creation reduces stock (generate random orders, verify stock reduction)
- Property 7: Quantity update recalculates total (generate random carts and quantity changes)
- Property 2: Search returns only matching items (generate random search queries and inventory)
- Property 21: Order status filter returns only matching orders (generate random orders with various statuses)
- Property 34: Users can only access their own data (generate random user IDs and data access attempts)

**Generator Strategy:**
- Create smart generators that produce valid domain objects (Products, Orders, Carts)
- Include edge cases in generators (zero stock, maximum quantities, empty carts)
- Use property tests to verify invariants across many random inputs

### Integration Testing

**Framework:** Flutter integration test package

**Focus Areas:**
- End-to-end user flows (browse → add to cart → checkout)
- Firebase integration (authentication, database operations)
- UI navigation and state persistence
- Offline behavior and data synchronization

**Key Integration Tests:**
- Complete order placement flow
- Admin inventory management flow
- Authentication flow with OTP
- Cart persistence across app restarts

### Widget Testing

**Framework:** Flutter widget test package

**Focus Areas:**
- UI component rendering
- User interaction handling
- State updates reflected in UI
- Error message display

**Key Widget Tests:**
- Product list displays correctly
- Cart updates when items are added/removed
- Order confirmation screen shows correct information
- Admin dashboard displays orders and inventory

### Testing Principles

1. **Write implementation first, then tests:** Implement features before writing corresponding tests to validate behavior
2. **Complementary testing:** Use both unit tests (specific examples) and property tests (universal properties) for comprehensive coverage
3. **Focus on core logic:** Prioritize testing business logic and data transformations over UI rendering details
4. **Mock external dependencies:** Mock Firebase services in unit tests, use real services in integration tests
5. **Test error paths:** Ensure error handling is tested as thoroughly as happy paths

## Security Considerations

### Authentication
- Phone number verification with time-limited OTP codes (5-minute expiry)
- Secure session management with token refresh
- Rate limiting on OTP requests to prevent abuse

### Authorization
- Role-based access control (Customer vs Admin)
- Middleware to verify user permissions before executing operations
- Audit logging for all admin actions

### Data Protection
- Encrypt sensitive data at rest (mobile numbers, addresses)
- Use HTTPS for all API communications
- Implement Firebase Security Rules to restrict data access
- Hash verification codes before storage

### Input Validation
- Sanitize all user inputs to prevent injection attacks
- Validate data types and formats on both client and server
- Implement rate limiting on API endpoints

## Performance Optimization

### Client-Side
- Implement pagination for product listings (20 items per page)
- Cache product images locally
- Use lazy loading for images
- Implement optimistic UI updates for cart operations

### Server-Side
- Index Firestore collections on frequently queried fields (category, status, customerId)
- Use Firestore compound indexes for complex queries
- Implement caching for frequently accessed data (product categories)
- Batch read operations where possible

### Database Design
- Denormalize data where appropriate to reduce read operations
- Use subcollections for scalability (orders as subcollection of customers)
- Implement pagination for large result sets

## Deployment Strategy

### Development Environment
- Use Firebase Emulator Suite for local development
- Separate Firebase project for development

### Production Environment
- Firebase project with production configuration
- Enable Firebase Analytics for monitoring
- Set up Cloud Functions deployment pipeline
- Configure Firebase Security Rules for production

### Monitoring
- Firebase Crashlytics for crash reporting
- Firebase Performance Monitoring for performance tracking
- Cloud Functions logs for backend monitoring
- Set up alerts for critical errors and performance degradation

## Future Enhancements

While not in the current scope, the architecture supports these future additions:
- Multiple payment methods (online payment gateways)
- Real-time order tracking
- Push notifications for order updates
- Wishlist functionality
- Product reviews and ratings
- Promotional codes and discounts
- Delivery slot selection
- Multiple delivery addresses per customer
