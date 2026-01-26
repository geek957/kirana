import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'crashlytics_service.dart';

/// Centralized error handling service
/// Provides error logging, user-friendly messages, and retry logic
class ErrorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CrashlyticsService _crashlytics = CrashlyticsService();

  // Singleton pattern
  static final ErrorService _instance = ErrorService._internal();
  factory ErrorService() => _instance;
  ErrorService._internal();

  /// Log error to Firestore for monitoring and debugging
  Future<void> logError({
    required String error,
    required String stackTrace,
    String? userId,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Log to Crashlytics
      _crashlytics.log('Error in $context: $error');
      if (additionalData != null) {
        await _crashlytics.setCustomKeys(additionalData);
      }

      final errorLog = {
        'error': error,
        'stackTrace': stackTrace,
        'userId': userId ?? _auth.currentUser?.uid ?? 'anonymous',
        'context': context ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
        'platform': defaultTargetPlatform.toString(),
        'additionalData': additionalData ?? {},
      };

      await _firestore.collection('errorLogs').add(errorLog);
    } catch (e) {
      // If logging fails, print to console as fallback
      debugPrint('Failed to log error to Firestore: $e');
      debugPrint('Original error: $error');
    }
  }

  /// Get user-friendly error message from exception
  String getUserFriendlyMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      return _getAuthErrorMessage(error);
    } else if (error is FirebaseException) {
      return _getFirestoreErrorMessage(error);
    } else if (error is Exception) {
      final message = error.toString();
      if (message.contains('Failed to')) {
        // Extract the meaningful part after "Exception: Failed to"
        return message.replaceFirst('Exception: Failed to ', 'Failed to ');
      }
      return message.replaceFirst('Exception: ', '');
    } else {
      return error.toString();
    }
  }

  /// Handle error with logging and return user-friendly message
  Future<String> handleError({
    required dynamic error,
    required StackTrace stackTrace,
    String? context,
    Map<String, dynamic>? additionalData,
  }) async {
    final errorMessage = error.toString();
    final stackTraceString = stackTrace.toString();

    // Record error in Crashlytics
    await _crashlytics.recordError(
      error,
      stackTrace,
      reason: context,
      fatal: false,
    );

    // Log error to Firestore
    await logError(
      error: errorMessage,
      stackTrace: stackTraceString,
      context: context,
      additionalData: additionalData,
    );

    // Return user-friendly message
    return getUserFriendlyMessage(error);
  }

  /// Retry logic for transient failures
  Future<T> retryOperation<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int attempts = 0;
    dynamic lastError;

    while (attempts < maxAttempts) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        attempts++;

        // Check if we should retry this error
        if (shouldRetry != null && !shouldRetry(e)) {
          rethrow;
        }

        // If this was the last attempt, rethrow
        if (attempts >= maxAttempts) {
          rethrow;
        }

        // Check if error is retryable
        if (!_isRetryableError(e)) {
          rethrow;
        }

        // Wait before retrying with exponential backoff
        await Future.delayed(delay * attempts);
      }
    }

    throw lastError;
  }

  /// Check if error is retryable (network issues, timeouts, etc.)
  bool _isRetryableError(dynamic error) {
    if (error is FirebaseException) {
      // Retry on network errors, unavailable, deadline exceeded
      return error.code == 'unavailable' ||
          error.code == 'deadline-exceeded' ||
          error.code == 'network-request-failed';
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection') ||
        errorString.contains('unavailable');
  }

  /// Get user-friendly message for Firebase Auth errors
  String _getAuthErrorMessage(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-phone-number':
        return 'Invalid phone number. Please check and try again.';
      case 'invalid-verification-code':
        return 'Invalid verification code. Please check and try again.';
      case 'invalid-verification-id':
        return 'Verification session expired. Please request a new code.';
      case 'session-expired':
        return 'Session expired. Please try again.';
      case 'quota-exceeded':
        return 'Too many requests. Please try again later.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'operation-not-allowed':
        return 'This operation is not allowed.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication error: ${error.message ?? 'Unknown error'}';
    }
  }

  /// Get user-friendly message for Firestore errors
  String _getFirestoreErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'permission-denied':
        return 'You do not have permission to perform this action.';
      case 'not-found':
        return 'The requested data was not found.';
      case 'already-exists':
        return 'This item already exists.';
      case 'resource-exhausted':
        return 'Service temporarily unavailable. Please try again later.';
      case 'failed-precondition':
        return 'Operation failed. Please try again.';
      case 'aborted':
        return 'Operation was aborted. Please try again.';
      case 'out-of-range':
        return 'Invalid input value.';
      case 'unimplemented':
        return 'This feature is not available yet.';
      case 'internal':
        return 'Internal error. Please try again later.';
      case 'unavailable':
        return 'Service temporarily unavailable. Please check your connection.';
      case 'data-loss':
        return 'Data error occurred. Please contact support.';
      case 'unauthenticated':
        return 'Please log in to continue.';
      case 'deadline-exceeded':
        return 'Request timeout. Please try again.';
      case 'cancelled':
        return 'Operation was cancelled.';
      default:
        return 'Error: ${error.message ?? 'Unknown error'}';
    }
  }

  /// Check if error indicates network connectivity issue
  bool isNetworkError(dynamic error) {
    if (error is FirebaseException) {
      return error.code == 'unavailable' ||
          error.code == 'network-request-failed' ||
          error.code == 'deadline-exceeded';
    }

    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('connection') ||
        errorString.contains('timeout');
  }

  /// Check if error indicates authentication issue
  bool isAuthError(dynamic error) {
    return error is FirebaseAuthException ||
        (error is FirebaseException && error.code == 'unauthenticated');
  }

  /// Check if error indicates permission issue
  bool isPermissionError(dynamic error) {
    return error is FirebaseException && error.code == 'permission-denied';
  }
}
