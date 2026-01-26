# Admin User Guide - Kirana Online Grocery App

## Welcome, Admin!

This guide provides comprehensive instructions for managing the Kirana online grocery platform. As an admin, you have access to inventory management, order fulfillment, and system monitoring features.

## Table of Contents

1. [Getting Started](#getting-started)
2. [Admin Dashboard](#admin-dashboard)
3. [Inventory Management](#inventory-management)
4. [Order Management](#order-management)
5. [Product Management](#product-management)
6. [Analytics & Monitoring](#analytics--monitoring)
7. [Security & Best Practices](#security--best-practices)
8. [FAQs](#faqs)

---

## Getting Started

### Admin Login

1. **Open the App**: Launch the Kirana app
2. **Enter Admin Phone Number**: Use your registered admin phone number
3. **Receive OTP**: You'll receive a 4-digit verification code
4. **Enter OTP**: Type the verification code
5. **Admin Dashboard**: You'll be redirected to the admin dashboard

**Note**: Admin accounts must be created manually in Firebase Console. See "Initial Setup" section in deployment documentation.

### Admin Interface Overview

The admin interface includes:
- **Dashboard**: Quick stats and recent orders
- **Inventory Management**: Product catalog and stock control
- **Order Management**: View and update customer orders
- **Navigation Drawer**: Access all admin features

---

## Admin Dashboard

### Quick Stats

The dashboard displays key metrics:

**Product Statistics**:
- Total number of products in inventory
- Active products count
- Inactive products count

**Order Statistics**:
- Today's orders count
- Pending orders requiring attention
- Orders by status breakdown

**Inventory Alerts**:
- Low stock products count
- Out of stock products count

### Recent Orders

View the most recent orders with:
- Order ID
- Customer name
- Order status
- Total amount
- Quick "View" action

### Navigation

Use the drawer menu to access:
- 📦 Manage Inventory
- 📋 Manage Orders
- 📊 Analytics (if enabled)
- 🚪 Logout

---

## Inventory Management

### Viewing Inventory

1. **Navigate**: Tap "Manage Inventory" from dashboard
2. **Product Grid**: See all products with:
   - Product image
   - Product name
   - Price per unit
   - Current stock quantity
   - Category
   - Edit and Delete buttons

### Search and Filter

**Search Products**:
- Use search bar at the top
- Type product name
- Results filter in real-time

**Filter by Stock Status**:
- All Products
- Low Stock (< 10 units)
- Out of Stock (0 units)

**Sort Options**:
- By Name (A-Z)
- By Stock (Low to High)
- By Price (Low to High)

### Stock Indicators

- ✅ **Good Stock**: Quantity > 10 units
- ⚠️ **Low Stock**: Quantity ≤ 10 units (yellow indicator)
- ❌ **Out of Stock**: Quantity = 0 (red indicator)

### Managing Low Stock

**Best Practices**:
1. Check low stock products daily
2. Update stock before it reaches zero
3. Consider setting reorder points
4. Monitor fast-moving items

---

## Product Management

### Adding a New Product

1. **Navigate**: Go to Inventory Management
2. **Add Button**: Tap "+ Add Product" button
3. **Fill Product Details**:

   **Required Fields**:
   - Product Name
   - Price (in ₹)
   - Unit Size (e.g., 1kg, 500g, 1L)
   - Category
   - Stock Quantity

   **Optional Fields**:
   - Description
   - Product Image

4. **Upload Image**:
   - Tap "Upload Image" area
   - Select image from device
   - Supported formats: JPG, PNG
   - Max size: 500KB (auto-compressed if larger)
   - Recommended: 800x800px square images

5. **Save**: Tap "Save Product" button

**Image Guidelines**:
- Use clear, well-lit product photos
- White or neutral background preferred
- Show product clearly
- Avoid text overlays
- Square aspect ratio works best

### Editing a Product

1. **Find Product**: Navigate to inventory list
2. **Edit Button**: Tap "Edit" on the product card
3. **Update Details**: Modify any field
4. **Change Image**: Upload new image if needed
5. **Save Changes**: Tap "Save Product"

**What You Can Edit**:
- Product name
- Description
- Price
- Unit size
- Category
- Stock quantity
- Product image
- Active status

### Updating Stock Quantity

**Quick Stock Update**:
1. Find the product in inventory
2. Tap "Edit" button
3. Update "Stock Quantity" field
4. Save changes

**Stock Management Tips**:
- Update stock after receiving new inventory
- Check stock before confirming orders
- Set up regular stock audits
- Monitor stock levels for popular items

### Deleting a Product

1. **Find Product**: Locate in inventory list
2. **Delete Button**: Tap "Delete" icon
3. **Confirm**: Confirm deletion in dialog

**Important Notes**:
- Deletion is a soft delete (sets isActive = false)
- Product won't appear in customer searches
- Historical order data is preserved
- Can be reactivated if needed

### Product Categories

**Available Categories**:
- Fruits
- Vegetables
- Dairy
- Snacks
- Beverages
- Grains & Cereals
- Spices & Condiments
- Personal Care
- Household Items
- Others

**Category Best Practices**:
- Choose the most appropriate category
- Be consistent with categorization
- Use "Others" sparingly
- Consider customer browsing patterns

---

## Order Management

### Viewing All Orders

1. **Navigate**: Tap "Manage Orders" from dashboard
2. **Order List**: See all orders with:
   - Order ID
   - Customer name and phone
   - Order date
   - Current status
   - Total amount
   - "View Details" button

### Filtering Orders by Status

Use status filter chips to view:
- **All**: All orders
- **Pending**: New orders awaiting confirmation
- **Confirmed**: Orders confirmed and ready for preparation
- **Preparing**: Orders being prepared
- **Out for Delivery**: Orders dispatched for delivery
- **Delivered**: Successfully delivered orders
- **Cancelled**: Cancelled orders

### Order Details

Tap any order to view complete information:

**Customer Information**:
- Customer name
- Phone number
- Delivery address with landmark
- Contact number for delivery

**Order Information**:
- Order ID
- Order date and time
- Payment method (COD)
- Current status

**Items Ordered**:
- Product name
- Quantity
- Unit price
- Subtotal per item
- Order total

### Updating Order Status

**Status Workflow**:
```
Pending → Confirmed → Preparing → Out for Delivery → Delivered
         ↓
      Cancelled (only from Pending/Confirmed)
```

**Steps to Update Status**:
1. Open order details
2. Find "Update Status" section
3. Select new status from dropdown
4. Tap "Update Status" button
5. Customer receives automatic notification

**Status Descriptions**:

- **Pending**: Order just placed, needs confirmation
  - Action: Review order and confirm
  
- **Confirmed**: Order accepted, ready for preparation
  - Action: Start preparing items
  
- **Preparing**: Items being collected and packed
  - Action: Complete packing and dispatch
  
- **Out for Delivery**: Order dispatched to customer
  - Action: Deliver to customer address
  
- **Delivered**: Order successfully delivered
  - Action: No further action needed
  
- **Cancelled**: Order cancelled by customer or admin
  - Note: Stock is automatically restored

### Order Fulfillment Workflow

**Recommended Process**:

1. **Morning Review** (Start of Day):
   - Check all Pending orders
   - Confirm orders with available stock
   - Contact customers if items unavailable

2. **Preparation** (Throughout Day):
   - Move Confirmed orders to Preparing
   - Collect and pack items
   - Verify quantities and quality

3. **Dispatch** (Scheduled Times):
   - Update to Out for Delivery
   - Assign to delivery personnel
   - Provide customer contact info

4. **Completion** (After Delivery):
   - Update to Delivered
   - Collect payment (COD)
   - Handle any issues

### Handling Cancellations

**Customer-Initiated Cancellations**:
- Customers can cancel Pending/Confirmed orders
- Stock is automatically restored
- No admin action needed

**Admin-Initiated Cancellations**:
1. Open order details
2. Change status to "Cancelled"
3. Contact customer to explain reason
4. Stock is automatically restored

**Cannot Cancel**:
- Orders in Preparing status
- Orders Out for Delivery
- Delivered orders

### Order Management Best Practices

✅ **Confirm orders promptly** (within 1 hour)
✅ **Check stock availability** before confirming
✅ **Update status regularly** to keep customers informed
✅ **Handle Pending orders first** (oldest to newest)
✅ **Communicate with customers** for any issues
✅ **Verify delivery address** before dispatch
✅ **Mark as Delivered** only after successful delivery

---

## Analytics & Monitoring

### Key Metrics to Monitor

**Daily Metrics**:
- Number of orders received
- Total revenue
- Average order value
- Order fulfillment rate

**Inventory Metrics**:
- Stock turnover rate
- Low stock items count
- Out of stock items count
- Most popular products

**Customer Metrics**:
- New customer registrations
- Repeat customer rate
- Order cancellation rate

### Firebase Analytics

The app automatically tracks:
- Product views
- Add to cart events
- Order placements
- Search queries
- User engagement

**Accessing Analytics**:
1. Go to Firebase Console
2. Navigate to Analytics section
3. View dashboards and reports

### Performance Monitoring

**Firebase Performance Monitoring tracks**:
- App startup time
- Screen rendering performance
- Network request latency
- Custom traces for key operations

**Accessing Performance Data**:
1. Go to Firebase Console
2. Navigate to Performance section
3. Review performance metrics

### Error Monitoring

**Firebase Crashlytics tracks**:
- App crashes
- Non-fatal errors
- Custom error logs

**Reviewing Errors**:
1. Go to Firebase Console
2. Navigate to Crashlytics section
3. Review crash reports and errors

---

## Security & Best Practices

### Admin Account Security

**Password/OTP Security**:
- Never share your admin phone number
- Don't share OTP codes with anyone
- Log out when not using the app
- Use a secure device

### Data Access

**Admin Responsibilities**:
- Access customer data only when necessary
- All data access is logged for audit
- Respect customer privacy
- Follow data protection guidelines

**Audit Logging**:
- All admin actions are logged
- Logs include: timestamp, admin ID, action, resource
- Logs are stored securely in Firestore
- Cannot be modified or deleted

### Sensitive Data Handling

**Encrypted Data**:
- Customer phone numbers (encrypted at rest)
- Delivery addresses (encrypted at rest)
- OTP codes (hashed with bcrypt)

**Best Practices**:
- Don't screenshot customer information
- Don't share customer data externally
- Use data only for order fulfillment
- Report any security concerns immediately

### Stock Management Security

**Preventing Stock Issues**:
- Always verify stock before confirming orders
- Update stock immediately after receiving inventory
- Don't manually adjust stock without reason
- Report discrepancies

### Firebase Security Rules

**Access Control**:
- Customers can only access their own data
- Admins can access all data (logged)
- Products are publicly readable
- Only admins can modify products and orders

---

## FAQs

### Account & Access

**Q: How do I become an admin?**
A: Admin accounts must be created manually in Firebase Console by the system administrator. Contact your system admin.

**Q: Can I have multiple admin accounts?**
A: Yes, multiple admin accounts can be created for different team members.

**Q: What if I forget my admin phone number?**
A: Contact the system administrator to retrieve your registered phone number.

### Inventory Management

**Q: What happens when I delete a product?**
A: The product is soft-deleted (marked inactive). It won't appear in customer searches but remains in the database for historical orders.

**Q: Can I reactivate a deleted product?**
A: Yes, by updating the isActive field in Firebase Console or through the app if the feature is implemented.

**Q: How do I handle products with variants (sizes, flavors)?**
A: Currently, create separate products for each variant. Example: "Milk 500ml" and "Milk 1L" as separate products.

**Q: What's the best way to organize products?**
A: Use clear, descriptive names, accurate categories, and consistent unit sizes. Add detailed descriptions.

### Order Management

**Q: Can I edit an order after it's placed?**
A: No, orders cannot be edited. You can cancel and ask the customer to place a new order.

**Q: What if a customer wants to add items to an existing order?**
A: They need to place a separate order. Orders cannot be modified after placement.

**Q: How do I handle out-of-stock items in an order?**
A: Contact the customer before confirming. Offer to remove the item or cancel the order.

**Q: Can I change the delivery address?**
A: No, delivery addresses cannot be changed after order placement. Cancel and reorder if needed.

### Technical Issues

**Q: The app is slow. What should I do?**
A: Check your internet connection. Close and reopen the app. Clear app cache if needed.

**Q: I can't upload product images. Why?**
A: Ensure the image is JPG or PNG format. Check your internet connection. Try compressing the image.

**Q: Orders aren't syncing. What's wrong?**
A: Check internet connectivity. Verify Firebase connection. Contact technical support if issue persists.

---

## Need Help?

For additional support:

1. **Technical Issues**: Contact your system administrator
2. **Firebase Console**: See Firebase documentation
3. **Troubleshooting**: Refer to TROUBLESHOOTING.md
4. **Deployment**: See DEPLOYMENT_GUIDE.md

---

## Admin Checklist

### Daily Tasks
- [ ] Review and confirm pending orders
- [ ] Check low stock items
- [ ] Update order statuses
- [ ] Monitor delivery progress
- [ ] Review customer notifications

### Weekly Tasks
- [ ] Update inventory stock levels
- [ ] Review sales analytics
- [ ] Check for app errors in Crashlytics
- [ ] Audit product catalog
- [ ] Review customer feedback

### Monthly Tasks
- [ ] Analyze sales trends
- [ ] Review popular products
- [ ] Update product catalog
- [ ] Check system performance
- [ ] Review security logs

---

**Thank you for managing Kirana! 🛒📦**
