import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/services/logging_service.dart';

/// Comprehensive error handling and retry service for production scanning
class ErrorHandlingService {
  static const int _maxRetryAttempts = 3;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(seconds: 30);

  /// Execute operation with exponential backoff retry
  static Future<T> executeWithRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = _maxRetryAttempts,
    Duration baseDelay = _baseRetryDelay,
    bool Function(Exception)? shouldRetry,
    String operationName = 'Operation',
  }) async {
    Exception? lastException;
    
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        LoggingService.info('Attempting operation', tag: 'ErrorHandler', context: {'operation': operationName, 'attempt': attempt, 'maxAttempts': maxAttempts});
        final result = await operation();
        
        if (attempt > 1) {
          LoggingService.success('Operation succeeded after retry', tag: 'ErrorHandler', context: {'operation': operationName, 'attempts': attempt});
        }
        
        return result;
      } on Exception catch (e) {
        lastException = e;
        LoggingService.warning('Operation failed', tag: 'ErrorHandler', context: {'operation': operationName, 'attempt': attempt, 'maxAttempts': maxAttempts, 'error': e.toString()});
        
        // Check if we should retry this specific error
        if (shouldRetry != null && !shouldRetry(e)) {
          LoggingService.warning('Not retrying due to non-retryable error', tag: 'ErrorHandler', context: {'operation': operationName});
          rethrow;
        }
        
        // Don't delay after the last attempt
        if (attempt < maxAttempts) {
          final delay = _calculateBackoffDelay(attempt, baseDelay);
          LoggingService.info('Waiting before retry', tag: 'ErrorHandler', context: {'delaySeconds': delay.inSeconds});
          await Future.delayed(delay);
        }
      }
    }
    
    LoggingService.error('Operation failed after all retry attempts', tag: 'ErrorHandler', context: {'operation': operationName, 'maxAttempts': maxAttempts});
    throw RetryExhaustedException(operationName, maxAttempts, lastException!);
  }

  /// Calculate exponential backoff delay with jitter
  static Duration _calculateBackoffDelay(int attempt, Duration baseDelay) {
    final exponentialDelay = Duration(
      milliseconds: (baseDelay.inMilliseconds * (1 << (attempt - 1))).round()
    );
    
    // Cap at max delay
    final cappedDelay = exponentialDelay > _maxRetryDelay ? _maxRetryDelay : exponentialDelay;
    
    // Add jitter (10-20% of delay)
    final jitterMs = (cappedDelay.inMilliseconds * (0.1 + (0.1 * (attempt % 10) / 10))).round();
    
    return Duration(milliseconds: cappedDelay.inMilliseconds + jitterMs);
  }

  /// Check if an error is retryable
  static bool isRetryableError(Exception error) {
    // Network-related errors are retryable
    if (error is SocketException) return true;
    if (error is TimeoutException) return true;
    if (error is HttpException) {
      // Retry on server errors (5xx), but not client errors (4xx)
      final message = error.message.toLowerCase();
      return message.contains('5') && message.contains('server');
    }
    
    // WebSocket connection errors are retryable
    if (error.toString().toLowerCase().contains('websocket')) return true;
    if (error.toString().toLowerCase().contains('connection')) return true;
    
    // Camera errors might be temporary
    if (error.toString().toLowerCase().contains('camera')) return true;
    
    // Generic platform exceptions might be retryable
    if (error.toString().toLowerCase().contains('platform')) return true;
    
    return false;
  }

  /// Handle WebSocket connection errors specifically
  static Future<T> executeWebSocketWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'WebSocket Operation',
  }) async {
    return executeWithRetry<T>(
      operation,
      maxAttempts: 5, // More attempts for WebSocket
      baseDelay: const Duration(seconds: 1),
      shouldRetry: (error) => isWebSocketRetryableError(error),
      operationName: operationName,
    );
  }

  /// Check if WebSocket error is retryable
  static bool isWebSocketRetryableError(Exception error) {
    final errorString = error.toString().toLowerCase();
    
    // Connection-related errors
    if (errorString.contains('connection')) return true;
    if (errorString.contains('network')) return true;
    if (errorString.contains('timeout')) return true;
    if (errorString.contains('unreachable')) return true;
    
    // WebSocket-specific errors
    if (errorString.contains('websocket')) return true;
    if (errorString.contains('handshake')) return true;
    
    // Server errors (but not authentication)
    if (errorString.contains('server') && !errorString.contains('auth')) return true;
    
    return false;
  }

  /// Handle camera-related errors specifically
  static Future<T> executeCameraWithRetry<T>(
    Future<T> Function() operation, {
    String operationName = 'Camera Operation',
  }) async {
    return executeWithRetry<T>(
      operation,
      maxAttempts: 4, // Camera operations need fewer attempts
      baseDelay: const Duration(milliseconds: 500),
      shouldRetry: (error) => isCameraRetryableError(error),
      operationName: operationName,
    );
  }

  /// Check if camera error is retryable
  static bool isCameraRetryableError(Exception error) {
    final errorString = error.toString().toLowerCase();
    
    // Temporary camera issues
    if (errorString.contains('camera not available')) return true;
    if (errorString.contains('camera busy')) return true;
    if (errorString.contains('camera error')) return true;
    
    // Permission issues are not retryable
    if (errorString.contains('permission')) return false;
    if (errorString.contains('access denied')) return false;
    
    // Hardware issues might be temporary
    if (errorString.contains('hardware')) return true;
    
    return false;
  }

  /// Execute with circuit breaker pattern
  static Future<T> executeWithCircuitBreaker<T>(
    Future<T> Function() operation, {
    required String operationName,
    int failureThreshold = 5,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final breaker = CircuitBreaker.getInstance(operationName);
    
    if (breaker.state == CircuitBreakerState.open) {
      throw CircuitBreakerOpenException(operationName);
    }
    
    try {
      final result = await operation().timeout(timeout);
      breaker.recordSuccess();
      return result;
    } on Exception catch (e) {
      breaker.recordFailure();
      
      if (breaker.state == CircuitBreakerState.open) {
        LoggingService.error('Circuit breaker opened', tag: 'ErrorHandler', context: {'operation': operationName, 'failureCount': breaker.failureCount});
      }
      
      rethrow;
    }
  }

  /// Log error details for debugging
  static void logError(
    String operation,
    Exception error, {
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  }) {
    LoggingService.error('Error in operation', tag: 'ErrorHandler', context: {'operation': operation, 'error': error.toString()});
    
    if (context != null && context.isNotEmpty) {
      LoggingService.debug('Error context', tag: 'ErrorHandler', context: context);
    }
    
    if (stackTrace != null) {
      LoggingService.debug('Stack trace', tag: 'ErrorHandler', context: {'stackTrace': stackTrace.toString()});
    }
    
    // In production, you might want to send this to crash reporting service
    // FirebaseCrashlytics.instance.recordError(error, stackTrace, context: context);
  }

  /// Create user-friendly error message
  static String getUserFriendlyMessage(Exception error) {
    final errorString = error.toString().toLowerCase();
    
    if (error is TimeoutException) {
      return 'The operation timed out. Please check your internet connection and try again.';
    }
    
    if (error is SocketException) {
      return 'Network connection error. Please check your internet connection.';
    }
    
    if (errorString.contains('websocket')) {
      return 'Connection to scanning service failed. Please try again.';
    }
    
    if (errorString.contains('camera')) {
      return 'Camera access error. Please check camera permissions and try again.';
    }
    
    if (errorString.contains('permission')) {
      return 'Permission denied. Please grant the required permissions.';
    }
    
    if (errorString.contains('auth')) {
      return 'Authentication failed. Please check your credentials.';
    }
    
    if (error is RetryExhaustedException) {
      return 'Operation failed after multiple attempts. Please try again later.';
    }
    
    if (error is CircuitBreakerOpenException) {
      return 'Service temporarily unavailable. Please try again in a few minutes.';
    }
    
    return 'An unexpected error occurred. Please try again.';
  }
}

/// Circuit breaker implementation for fault tolerance
class CircuitBreaker {
  static final Map<String, CircuitBreaker> _instances = {};
  
  final String name;
  final int failureThreshold;
  final Duration timeout;
  
  int _failureCount = 0;
  DateTime? _lastFailureTime;
  CircuitBreakerState _state = CircuitBreakerState.closed;
  
  CircuitBreaker._(this.name, this.failureThreshold, this.timeout);
  
  factory CircuitBreaker.getInstance(
    String name, {
    int failureThreshold = 5,
    Duration timeout = const Duration(minutes: 1),
  }) {
    return _instances.putIfAbsent(
      name,
      () => CircuitBreaker._(name, failureThreshold, timeout),
    );
  }
  
  CircuitBreakerState get state {
    if (_state == CircuitBreakerState.halfOpen || _state == CircuitBreakerState.closed) {
      return _state;
    }
    
    // Check if timeout has passed
    if (_lastFailureTime != null && 
        DateTime.now().difference(_lastFailureTime!) > timeout) {
      _state = CircuitBreakerState.halfOpen;
      LoggingService.info('Circuit breaker moved to half-open state', tag: 'ErrorHandler', context: {'name': name});
    }
    
    return _state;
  }
  
  int get failureCount => _failureCount;
  
  void recordSuccess() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
  }
  
  void recordFailure() {
    _failureCount++;
    _lastFailureTime = DateTime.now();
    
    if (_failureCount >= failureThreshold) {
      _state = CircuitBreakerState.open;
    }
  }
  
  void reset() {
    _failureCount = 0;
    _state = CircuitBreakerState.closed;
    _lastFailureTime = null;
  }
}

enum CircuitBreakerState { closed, open, halfOpen }

/// Exception thrown when retry attempts are exhausted
class RetryExhaustedException implements Exception {
  final String operationName;
  final int maxAttempts;
  final Exception lastException;
  
  RetryExhaustedException(this.operationName, this.maxAttempts, this.lastException);
  
  @override
  String toString() => 'RetryExhaustedException: $operationName failed after $maxAttempts attempts. Last error: $lastException';
}

/// Exception thrown when circuit breaker is open
class CircuitBreakerOpenException implements Exception {
  final String operationName;
  
  CircuitBreakerOpenException(this.operationName);
  
  @override
  String toString() => 'CircuitBreakerOpenException: $operationName circuit breaker is open';
}