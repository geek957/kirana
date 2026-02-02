# Admin Guide: App Configuration

## Overview

The App Configuration feature allows administrators to manage key business rules and operational parameters without code changes. This includes delivery charges, cart limits, and order capacity thresholds. This guide covers all configurable settings and their impact.

## Table of Contents

1. [Accessing App Configuration](#accessing-app-configuration)
2. [Configuration Settings](#configuration-settings)
3. [Delivery Charge Settings](#delivery-charge-settings)
4. [Cart Value Settings](#cart-value-settings)
5. [Order Capacity Settings](#order-capacity-settings)
6. [Updating Configuration](#updating-configuration)
7. [Best Practices](#best-practices)
8. [Troubleshooting](#troubleshooting)

---

## Accessing App Configuration

### Navigation Path
1. Open the Kirana admin app
2. Login with your admin credentials
3. From the admin dashboard, tap **"Settings"** or **"App Configuration"**
4. You'll see the App Configuration screen

### Screen Overview
The configuration screen displays:
- Current values for all settings
- Input fields to modify settings
- Validation messages
- Last updated timestamp and admin name
- Save button

### Permissions
- Only admin users can access this screen
- All configuration changes are logged
- Changes take effect immediately across all devices

---

## Configuration Settings

### Overview of All Settings

| Setting | Default Value | Purpose |
|---------|--------------|---------|
| Delivery Charge | ₹20 | Standard delivery fee |
| Free Delivery Threshold | ₹200 | Cart value for free delivery |
| Maximum Cart Value | ₹3000 | Upper limit for cart total |
| Order Capacity Warning | 2 | Pending orders to show warning |
| Order Capacity Block | 10 | Pending orders to block new orders |

### Configuration Document
All settings are stored in a single Firestore document:
- **Path**: `/config/app_settings`
- **Updates**: Real-time across all devices
- **Audit Trail**: Includes updatedAt and updatedBy fields

---

## Delivery Charge Settings

### Delivery Charge Amount

**Purpose**: The standard delivery fee charged on orders.

**Default Value**: ₹20

**Valid Range**: ₹0 - ₹1000

**How It Works**:
- Applied to all orders by default
- Waived if cart value meets free delivery threshold
- Displayed as separate line item in order summary

**When to Adjust**:
- Fuel price changes
- Operational cost changes
- Competitive pricing adjustments
- Promotional periods (set to ₹0 for free delivery)

**Example Scenarios**:
```
Cart Value: ₹150
Delivery Charge: ₹20
Total: ₹170

Cart Value: ₹250 (≥ ₹200 threshold)
Delivery Charge: ₹0 (FREE)
Total: ₹250
```

### Free Delivery Threshold

**Purpose**: Cart value at which delivery becomes free.

**Default Value**: ₹200

**Valid Range**: ₹0 - ₹10,000

**How It Works**:
- If cart value ≥ threshold, delivery charge = ₹0
- If cart value < threshold, standard delivery charge applies
- Progress indicator shows customers how much more to add

**When to Adjust**:
- Increase average order value
- Promotional campaigns
- Seasonal adjustments
- Competitive positioning

**Customer Experience**:
- Cart shows: "Add ₹X more for free delivery"
- Progress bar indicates proximity to threshold
- Encourages customers to add more items

**Example Scenarios**:
```
Threshold: ₹200
Cart: ₹180 → "Add ₹20 more for free delivery"
Cart: ₹200 → "You qualify for FREE delivery!"
Cart: ₹250 → "FREE delivery applied"
```

### Relationship Between Settings

**Important**: Free Delivery Threshold must be less than Maximum Cart Value.

**Valid Configuration**:
```
Delivery Charge: ₹20
Free Delivery Threshold: ₹200
Max Cart Value: ₹3000
✅ Valid (₹200 < ₹3000)
```

**Invalid Configuration**:
```
Free Delivery Threshold: ₹3500
Max Cart Value: ₹3000
❌ Invalid (₹3500 > ₹3000)
```

---

## Cart Value Settings

### Maximum Cart Value

**Purpose**: Upper limit for cart total to manage order size and delivery capacity.

**Default Value**: ₹3000

**Valid Range**: ₹100 - ₹100,000

**How It Works**:
- Customers cannot checkout if cart exceeds this value
- Warning shown when approaching limit
- Error message blocks checkout when exceeded

**When to Adjust**:
- Increase: During low-demand periods, for bulk orders
- Decrease: During high-demand periods, to manage capacity
- Seasonal adjustments based on delivery capability

**Customer Experience**:
```
Cart: ₹2800 (Max: ₹3000)
→ Warning: "Approaching maximum cart value"

Cart: ₹3100 (Max: ₹3000)
→ Error: "Cart exceeds maximum value of ₹3000"
→ Checkout button disabled
```

**Business Impact**:
- **Higher Limit**: Allows larger orders, more revenue per order
- **Lower Limit**: Better order management, faster fulfillment
- **Balance**: Consider delivery capacity and customer needs

---

## Order Capacity Settings

### Order Capacity Warning Threshold

**Purpose**: Number of pending orders at which to show delivery delay warning.

**Default Value**: 2 pending orders

**Valid Range**: 1 - 100

**How It Works**:
- System counts orders with "pending" status
- When count ≥ threshold, warning appears
- Customers can still place orders
- Warning: "Delivery might be delayed due to high demand"

**When to Adjust**:
- **Increase**: If you can handle more concurrent orders
- **Decrease**: If you want earlier warnings
- **Consider**: Your delivery capacity and team size

**Customer Experience**:
```
Pending Orders: 1
→ No warning, normal checkout

Pending Orders: 2 (≥ threshold)
→ ⚠️ "Delivery might be delayed"
→ Can still place order

Pending Orders: 5
→ ⚠️ "Delivery might be delayed"
→ Can still place order
```

### Order Capacity Block Threshold

**Purpose**: Number of pending orders at which to block new orders.

**Default Value**: 10 pending orders

**Valid Range**: 2 - 1000

**How It Works**:
- System counts orders with "pending" status
- When count ≥ threshold, new orders are blocked
- Customers see clear message
- Blocking: "Order capacity full. Please try again later."

**When to Adjust**:
- **Increase**: If you can handle more orders
- **Decrease**: If you need stricter capacity control
- **Consider**: Maximum orders you can fulfill in a day

**Customer Experience**:
```
Pending Orders: 9
→ ⚠️ Warning shown, can place order

Pending Orders: 10 (≥ threshold)
→ ❌ "Order capacity full"
→ Cannot place order
→ "Please try again later"

Pending Orders: 8 (after processing some)
→ ⚠️ Warning shown, can place order again
```

### Relationship Between Capacity Thresholds

**Important**: Warning threshold must be less than block threshold.

**Valid Configuration**:
```
Warning Threshold: 2
Block Threshold: 10
✅ Valid (2 < 10)
```

**Invalid Configuration**:
```
Warning Threshold: 15
Block Threshold: 10
❌ Invalid (15 > 10)
```

**Recommended Gap**: Keep at least 3-5 orders between warning and block thresholds.

---

## Updating Configuration

### Steps to Update Settings

1. **Access Configuration Screen**:
   - Navigate to App Configuration
   - Review current settings

2. **Modify Settings**:
   - Tap on any input field
   - Enter new value
   - Validation occurs in real-time

3. **Review Changes**:
   - Check all modified values
   - Ensure relationships are valid
   - Consider impact on customers

4. **Save Configuration**:
   - Tap "Save Configuration" button
   - Confirmation dialog appears
   - Review summary of changes

5. **Confirm Save**:
   - Tap "Confirm" in dialog
   - Settings are saved immediately
   - Success message appears

### Validation Rules

**Delivery Charge**:
- ✅ Must be ≥ ₹0
- ✅ Must be ≤ ₹1000
- ❌ Cannot be negative

**Free Delivery Threshold**:
- ✅ Must be > ₹0
- ✅ Must be < Maximum Cart Value
- ✅ Must be ≤ ₹10,000

**Maximum Cart Value**:
- ✅ Must be > Free Delivery Threshold
- ✅ Must be ≤ ₹100,000
- ❌ Cannot be less than threshold

**Order Capacity Warning**:
- ✅ Must be ≥ 1
- ✅ Must be < Block Threshold
- ✅ Must be ≤ 100

**Order Capacity Block**:
- ✅ Must be > Warning Threshold
- ✅ Must be ≤ 1000
- ❌ Cannot be less than warning

### Real-Time Updates

**Propagation**:
- Changes save to Firestore immediately
- All devices receive updates within 2 seconds
- No app restart required

**Impact**:
- Customer apps update automatically
- Cart calculations use new values
- Order capacity checks use new thresholds

### Audit Trail

Every configuration change is logged:
- **Timestamp**: When the change was made
- **Admin ID**: Who made the change
- **Previous Values**: What was changed from
- **New Values**: What was changed to

**Viewing Audit Trail**:
- Check Firebase Console → Firestore → `/config/app_settings`
- Review `updatedAt` and `updatedBy` fields
- For detailed history, check Firestore audit logs

---

## Best Practices

### General Guidelines

**1. Test Before Changing**:
- Understand current customer behavior
- Analyze order patterns
- Consider peak vs. off-peak times

**2. Make Gradual Changes**:
- Don't make drastic changes suddenly
- Adjust incrementally
- Monitor impact before further changes

**3. Communicate Changes**:
- Inform customers of significant changes
- Use in-app notifications
- Update help documentation

**4. Monitor Impact**:
- Track order values after changes
- Monitor customer feedback
- Adjust if needed

### Delivery Charge Strategy

**Competitive Pricing**:
- Research competitor delivery charges
- Balance between profitability and competitiveness
- Consider your service quality

**Promotional Periods**:
- Set delivery charge to ₹0 for promotions
- Lower free delivery threshold temporarily
- Announce promotions clearly

**Cost-Based Pricing**:
- Calculate actual delivery costs
- Include fuel, time, vehicle maintenance
- Add reasonable margin

### Cart Value Strategy

**Encouraging Larger Orders**:
- Set attractive free delivery threshold
- Not too high (discourages orders)
- Not too low (reduces revenue)

**Managing Capacity**:
- Lower max cart value during peak times
- Raise during slow periods
- Balance revenue and fulfillment capability

**Sweet Spot**:
- Free delivery threshold: 2-3x average order value
- Maximum cart value: 10-15x average order value

### Capacity Management Strategy

**Understanding Your Capacity**:
- How many orders can you fulfill per day?
- How long does each order take?
- What's your delivery team size?

**Setting Thresholds**:
- Warning: 20-30% of daily capacity
- Block: 80-90% of daily capacity
- Leave buffer for processing

**Dynamic Adjustment**:
- Increase thresholds during slow periods
- Decrease during peak times (festivals, weekends)
- Monitor and adjust based on actual performance

---

## Configuration Scenarios

### Scenario 1: New Store Launch

**Goal**: Attract customers, build base

**Recommended Settings**:
```
Delivery Charge: ₹0 (Free for all)
Free Delivery Threshold: ₹0
Maximum Cart Value: ₹2000
Warning Threshold: 3
Block Threshold: 8
```

**Rationale**:
- Free delivery attracts customers
- Lower max cart ensures manageable orders
- Conservative capacity limits

### Scenario 2: Established Store

**Goal**: Optimize profitability, manage capacity

**Recommended Settings**:
```
Delivery Charge: ₹20
Free Delivery Threshold: ₹200
Maximum Cart Value: ₹3000
Warning Threshold: 5
Block Threshold: 15
```

**Rationale**:
- Standard delivery charge
- Threshold encourages larger orders
- Higher capacity reflects experience

### Scenario 3: Peak Season (Festivals)

**Goal**: Manage high demand, prevent overload

**Recommended Settings**:
```
Delivery Charge: ₹30
Free Delivery Threshold: ₹300
Maximum Cart Value: ₹2500
Warning Threshold: 3
Block Threshold: 10
```

**Rationale**:
- Higher charges manage demand
- Higher threshold for free delivery
- Lower capacity limits prevent overload

### Scenario 4: Promotional Campaign

**Goal**: Boost sales, attract customers

**Recommended Settings**:
```
Delivery Charge: ₹0
Free Delivery Threshold: ₹0
Maximum Cart Value: ₹5000
Warning Threshold: 5
Block Threshold: 20
```

**Rationale**:
- Free delivery for all
- Higher cart limit for bulk orders
- Increased capacity for expected volume

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: Cannot save configuration - validation error

**Cause**: Invalid values or relationship violations

**Solution**:
1. Check all validation messages
2. Ensure Free Delivery Threshold < Max Cart Value
3. Ensure Warning Threshold < Block Threshold
4. Verify all values are within valid ranges

#### Issue: Changes not reflecting in customer app

**Cause**: 
- Sync delay
- Customer app not connected to internet
- Cache issue

**Solution**:
1. Wait 2-3 seconds for sync
2. Ask customer to check internet connection
3. Ask customer to refresh app
4. Verify changes in Firebase Console

#### Issue: Customers complaining about delivery charges

**Cause**: 
- Recent configuration change
- Misunderstanding of free delivery rules
- Display issue

**Solution**:
1. Verify current configuration is correct
2. Check if free delivery threshold is clear
3. Send notification explaining delivery charges
4. Consider adjusting thresholds based on feedback

#### Issue: Too many orders being blocked

**Cause**: Block threshold too low for actual capacity

**Solution**:
1. Review actual fulfillment capacity
2. Increase block threshold gradually
3. Monitor pending order count
4. Adjust based on performance

#### Issue: Not enough warning before blocking

**Cause**: Warning and block thresholds too close

**Solution**:
1. Increase gap between thresholds
2. Recommended: 3-5 orders difference
3. Gives time to process orders before blocking

---

## Configuration Checklist

### Before Changing Settings
- [ ] Reviewed current settings and their impact
- [ ] Analyzed order patterns and customer behavior
- [ ] Calculated actual costs (for delivery charges)
- [ ] Assessed current capacity (for thresholds)
- [ ] Planned communication to customers
- [ ] Noted current values for rollback if needed

### After Changing Settings
- [ ] Verified changes saved successfully
- [ ] Checked settings in Firebase Console
- [ ] Tested customer app with new settings
- [ ] Monitored initial customer reactions
- [ ] Tracked order patterns with new settings
- [ ] Documented reason for change
- [ ] Set reminder to review impact in 1 week

### Regular Review (Weekly)
- [ ] Review order value distribution
- [ ] Check if free delivery threshold is effective
- [ ] Monitor pending order counts
- [ ] Assess if capacity thresholds are appropriate
- [ ] Gather customer feedback
- [ ] Adjust settings if needed

---

## Advanced Tips

### A/B Testing (Manual)

**Test Different Thresholds**:
1. Week 1: Free delivery at ₹200
2. Week 2: Free delivery at ₹250
3. Compare: Average order value, total orders, revenue

**Measure Impact**:
- Track average order value
- Monitor order frequency
- Calculate total revenue
- Assess customer satisfaction

### Seasonal Adjustments

**Create a Schedule**:
- Normal periods: Standard settings
- Weekends: Slightly higher capacity
- Festivals: Higher charges, lower capacity
- Promotions: Free delivery, higher capacity

**Plan Ahead**:
- Set reminders for seasonal changes
- Prepare configuration changes in advance
- Communicate changes to customers
- Monitor closely during transitions

### Data-Driven Decisions

**Metrics to Track**:
- Average order value
- Orders per day
- Peak order times
- Delivery completion rate
- Customer complaints

**Use Data to Optimize**:
- If avg order value < threshold: Lower threshold
- If too many blocks: Increase capacity or improve processing
- If low order volume: Reduce delivery charge or threshold

---

## Integration with Other Features

### Product Management
- Discount pricing affects cart values
- Consider discounts when setting thresholds
- Monitor impact of promotions on cart values

### Order Management
- Pending order count drives capacity checks
- Process orders promptly to free capacity
- Monitor order status distribution

### Customer Experience
- Clear messaging about delivery charges
- Progress indicators for free delivery
- Helpful error messages when blocked

---

## FAQs

**Q: How often should I review configuration?**
A: Review weekly initially, then monthly once stable. Adjust immediately if issues arise.

**Q: Can I set delivery charge to ₹0 permanently?**
A: Yes, but ensure this is sustainable for your business model.

**Q: What if I set thresholds too low?**
A: Customers will be blocked frequently. Monitor and increase if needed.

**Q: Can customers see these settings?**
A: They see the effects (delivery charges, warnings) but not the admin configuration screen.

**Q: What happens to orders in progress when I change settings?**
A: Existing orders use the settings at the time they were placed. New orders use new settings.

**Q: Can I schedule configuration changes?**
A: Not currently. Changes must be made manually. Set reminders for planned changes.

**Q: What if two admins change settings simultaneously?**
A: Last save wins. Coordinate with other admins to avoid conflicts.

**Q: How do I revert to previous settings?**
A: Note current values before changing. Manually enter previous values if needed to revert.

---

## Need Help?

For additional support:
- **Configuration Questions**: Contact system administrator
- **Business Strategy**: Consult with management
- **Technical Issues**: Check Firebase Console
- **General Admin Help**: See main Admin User Guide

---

**Remember**: Configuration changes affect all customers immediately. Make changes thoughtfully and monitor their impact!

**Last Updated**: January 2025
