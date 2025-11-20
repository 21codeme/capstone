import 'dart:async';
import 'dart:math' as math;

/// A utility class that provides exponential backoff retry functionality
/// for Firebase operations that might fail due to network issues or
/// temporary service disruptions.
class RetryHelper {
  /// Executes the provided function with exponential backoff retry logic.
  /// 
  /// Parameters:
  /// - [operation]: The async function to execute with retry logic
  /// - [maxRetries]: Maximum number of retry attempts (default: 3)
  /// - [initialDelayMs]: Initial delay in milliseconds before first retry (default: 300ms)
  /// - [maxDelayMs]: Maximum delay in milliseconds between retries (default: 5000ms)
  /// - [shouldRetry]: Optional function to determine if a specific error should trigger a retry
  /// 
  /// Returns the result of the operation if successful, or throws the last error if all retries fail.
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxRetries = 3,
    int initialDelayMs = 300,
    int maxDelayMs = 5000,
    bool Function(dynamic error)? shouldRetry,
  }) async {
    int retryCount = 0;
    dynamic lastError;

    while (retryCount <= maxRetries) {
      try {
        // Attempt the operation
        return await operation();
      } catch (error) {
        lastError = error;
        
        // Check if we should retry based on the error
        final shouldAttemptRetry = shouldRetry?.call(error) ?? defaultShouldRetry(error);
        
        // If we shouldn't retry or we've reached max retries, rethrow
        if (!shouldAttemptRetry || retryCount >= maxRetries) {
          print('❌ Retry failed after $retryCount attempts: $error');
          rethrow;
        }
        
        // Calculate backoff delay with jitter
        final backoffMs = _calculateBackoffWithJitter(
          retryCount: retryCount,
          initialDelayMs: initialDelayMs,
          maxDelayMs: maxDelayMs,
        );
        
        print('⏱️ Retry attempt ${retryCount + 1}/$maxRetries after ${backoffMs}ms delay. Error: $error');
        
        // Wait before retrying
        await Future.delayed(Duration(milliseconds: backoffMs));
        retryCount++;
      }
    }
    
    // This should never be reached due to the rethrow above, but just in case
    throw lastError;
  }
  
  /// Calculates exponential backoff time with jitter to prevent thundering herd problem
  static int _calculateBackoffWithJitter({
    required int retryCount,
    required int initialDelayMs,
    required int maxDelayMs,
  }) {
    // Calculate exponential backoff: initialDelay * 2^retryCount
    final exponentialDelay = initialDelayMs * math.pow(2, retryCount).toInt();
    
    // Apply a random jitter of 0-25% to prevent synchronized retries
    final jitter = (math.Random().nextDouble() * 0.25 * exponentialDelay).toInt();
    
    // Calculate final delay with jitter
    final delay = exponentialDelay + jitter;
    
    // Ensure delay doesn't exceed maximum
    return math.min(delay, maxDelayMs);
  }
  
  /// Default logic to determine if an error should trigger a retry
  static bool defaultShouldRetry(dynamic error) {
    // Retry network-related errors
    if (error.toString().contains('network')) return true;
    if (error.toString().contains('timeout')) return true;
    if (error.toString().contains('connection')) return true;
    
    // Retry Firebase-specific temporary errors
    if (error.toString().contains('unavailable')) return true;
    if (error.toString().contains('resource-exhausted')) return true;
    if (error.toString().contains('internal')) return true;
    if (error.toString().contains('PigeonUserDetails')) return true;
    
    // Don't retry authentication errors, permission errors, or invalid arguments
    if (error.toString().contains('permission-denied')) return false;
    if (error.toString().contains('unauthenticated')) return false;
    if (error.toString().contains('invalid-argument')) return false;
    if (error.toString().contains('wrong-password')) return false;
    if (error.toString().contains('user-not-found')) return false;
    
    // By default, don't retry unknown errors
    return false;
  }
}