import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

// Notification messages for different order statuses
const statusMessages: { [key: string]: { title: string; body: string } } = {
  confirmed: {
    title: 'Order Confirmed! 🎉',
    body: 'Your order has been confirmed and will be prepared soon.',
  },
  preparing: {
    title: 'Order Being Prepared 👨‍🍳',
    body: 'Your order is being prepared for delivery.',
  },
  out_for_delivery: {
    title: 'Out for Delivery 🚚',
    body: 'Your order is out for delivery and will arrive soon.',
  },
  delivered: {
    title: 'Order Delivered ✅',
    body: 'Your order has been delivered. Thank you for shopping with us!',
  },
};

/**
 * Cloud Function to send push notifications when order status changes
 * Triggers on any order document update in Firestore
 */
export const sendOrderNotification = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    try {
      const orderId = context.params.orderId;
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Check if status changed
      if (beforeData.status === afterData.status) {
        console.log('Order status unchanged, skipping notification');
        return null;
      }

      const newStatus = afterData.status;
      const customerId = afterData.customerId;

      // Only send notifications for specific status changes
      if (!statusMessages[newStatus]) {
        console.log(`No notification configured for status: ${newStatus}`);
        return null;
      }

      // Get customer's FCM token
      const userDoc = await admin
        .firestore()
        .collection('customers')
        .doc(customerId)
        .get();

      if (!userDoc.exists) {
        console.error(`Customer not found: ${customerId}`);
        return null;
      }

      const fcmToken = userDoc.data()?.fcmToken;

      if (!fcmToken) {
        console.log(`No FCM token for customer: ${customerId}`);
        // Still create in-app notification even without FCM token
      }

      // Create in-app notification document
      const notificationRef = admin.firestore().collection('notifications').doc();
      await notificationRef.set({
        id: notificationRef.id,
        customerId: customerId,
        orderId: orderId,
        type: 'order_status_change',
        title: statusMessages[newStatus].title,
        message: statusMessages[newStatus].body,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`In-app notification created for customer: ${customerId}`);

      // Send push notification if FCM token exists
      if (fcmToken) {
        const message = {
          token: fcmToken,
          notification: {
            title: statusMessages[newStatus].title,
            body: statusMessages[newStatus].body,
          },
          data: {
            orderId: orderId,
            type: 'order_status_change',
            status: newStatus,
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high' as const,
            notification: {
              channelId: 'order_updates',
              sound: 'default',
              priority: 'high' as const,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
        };

        await admin.messaging().send(message);
        console.log(`Push notification sent to customer: ${customerId}`);
      }

      return null;
    } catch (error) {
      console.error('Error sending notification:', error);
      return null;
    }
  });

/**
 * Optional: Cloud Function to send bulk notifications
 * Can be triggered via HTTP request
 */
export const sendBulkNotification = functions.https.onCall(
  async (data, context) => {
    try {
      // Only allow admins to send bulk notifications
      if (!context.auth) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'Must be authenticated'
        );
      }

      const { title, body, type } = data;

      // Get all customers with FCM tokens
      const usersSnapshot = await admin
        .firestore()
        .collection('customers')
        .where('isAdmin', '==', false)
        .get();

      const tokens: string[] = [];
      const batch = admin.firestore().batch();

      // Create in-app notifications and collect FCM tokens
      usersSnapshot.docs.forEach((doc) => {
        const fcmToken = doc.data().fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        }

        // Create in-app notification
        const notificationRef = admin
          .firestore()
          .collection('notifications')
          .doc();
        batch.set(notificationRef, {
          id: notificationRef.id,
          customerId: doc.id,
          orderId: '',
          type: type || 'announcement',
          title: title,
          message: body,
          isRead: false,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      await batch.commit();

      // Send push notifications in batches
      if (tokens.length > 0) {
        const message = {
          notification: {
            title: title,
            body: body,
          },
          data: {
            type: type || 'announcement',
          },
          tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(
          `Bulk notification sent. Success: ${response.successCount}, Failure: ${response.failureCount}`
        );

        return {
          success: true,
          successCount: response.successCount,
          failureCount: response.failureCount,
          totalCustomers: usersSnapshot.docs.length,
        };
      }

      return {
        success: true,
        successCount: 0,
        failureCount: 0,
        totalCustomers: usersSnapshot.docs.length,
      };
    } catch (error) {
      console.error('Error sending bulk notification:', error);
      throw new functions.https.HttpsError('internal', 'Failed to send notification');
    }
  }
);

/**
 * Cloud Function to send push notifications to all admins when a new order is created
 * Triggers on order document creation in Firestore
 */
export const sendNewOrderNotificationToAdmins = functions.firestore
  .document('orders/{orderId}')
  .onCreate(async (snapshot, context) => {
    try {
      const orderId = context.params.orderId;
      const orderData = snapshot.data();

      const customerName = orderData.customerName || 'Unknown Customer';
      const totalAmount = orderData.totalAmount || 0;
      const itemCount = orderData.items?.length || 0;

      console.log(`New order created: ${orderId} by ${customerName}`);

      // Get all admin FCM tokens from customers collection
      const adminsSnapshot = await admin
        .firestore()
        .collection('customers')
        .where('isAdmin', '==', true)
        .get();

      const tokens: string[] = [];
      adminsSnapshot.docs.forEach((doc) => {
        const fcmToken = doc.data().fcmToken;
        if (fcmToken) {
          tokens.push(fcmToken);
        }
      });

      if (tokens.length === 0) {
        console.log('No admin FCM tokens found');
        return null;
      }

      console.log(`Sending new order notification to ${tokens.length} admin(s)`);

      // Send push notification to all admins
      const message = {
        notification: {
          title: '🛒 New Order Received!',
          body: `Order #${orderId} from ${customerName}. ${itemCount} items, Total: ₹${totalAmount.toFixed(2)}`,
        },
        data: {
          orderId: orderId,
          type: 'new_order',
          customerId: orderData.customerId || '',
          customerName: customerName,
          totalAmount: totalAmount.toString(),
          itemCount: itemCount.toString(),
          clickAction: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high' as const,
          notification: {
            channelId: 'admin_order_updates',
            sound: 'default',
            priority: 'high' as const,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
        tokens: tokens,
      };

      const response = await admin.messaging().sendEachForMulticast(message);
      console.log(
        `New order notification sent. Success: ${response.successCount}, Failure: ${response.failureCount}`
      );

      return null;
    } catch (error) {
      console.error('Error sending new order notification to admins:', error);
      return null;
    }
  });

/**
 * Cloud Function to send push notifications to all admins when an order is delivered
 * Triggers on order document update when status changes to 'delivered'
 */
export const sendDeliveredNotificationToAdmins = functions.firestore
  .document('orders/{orderId}')
  .onUpdate(async (change, context) => {
    try {
      const orderId = context.params.orderId;
      const beforeData = change.before.data();
      const afterData = change.after.data();

      // Check if status changed to delivered
      if (beforeData.status !== 'delivered' && afterData.status === 'delivered') {
        const customerName = afterData.customerName || 'Unknown Customer';
        const totalAmount = afterData.totalAmount || 0;

        console.log(`Order delivered: ${orderId} for ${customerName}`);

        // Get all admin FCM tokens from customers collection
        const adminsSnapshot = await admin
          .firestore()
          .collection('customers')
          .where('isAdmin', '==', true)
          .get();

        const tokens: string[] = [];
        adminsSnapshot.docs.forEach((doc) => {
          const fcmToken = doc.data().fcmToken;
          if (fcmToken) {
            tokens.push(fcmToken);
          }
        });

        if (tokens.length === 0) {
          console.log('No admin FCM tokens found');
          return null;
        }

        console.log(`Sending delivered notification to ${tokens.length} admin(s)`);

        // Send push notification to all admins
        const message = {
          notification: {
            title: '✅ Order Delivered',
            body: `Order #${orderId} has been successfully delivered to ${customerName}. Amount: ₹${totalAmount.toFixed(2)}`,
          },
          data: {
            orderId: orderId,
            type: 'order_delivered',
            customerId: afterData.customerId || '',
            customerName: customerName,
            totalAmount: totalAmount.toString(),
            clickAction: 'FLUTTER_NOTIFICATION_CLICK',
          },
          android: {
            priority: 'high' as const,
            notification: {
              channelId: 'admin_order_updates',
              sound: 'default',
              priority: 'high' as const,
            },
          },
          apns: {
            payload: {
              aps: {
                sound: 'default',
                badge: 1,
              },
            },
          },
          tokens: tokens,
        };

        const response = await admin.messaging().sendEachForMulticast(message);
        console.log(
          `Delivered notification sent. Success: ${response.successCount}, Failure: ${response.failureCount}`
        );
      }

      return null;
    } catch (error) {
      console.error('Error sending delivered notification to admins:', error);
      return null;
    }
  });
