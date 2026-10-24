class ApiErrorHandler {
  /// Get user-friendly error message from API error
  static String getErrorMessage(dynamic error) {
    if (error is Map) {
      final statusCode = error['statusCode'];
      final code = error['code'];

      // Handle specific error codes
      if (code == 'SUBSCRIPTION_REQUIRED' || statusCode == 402) {
        return 'Active subscription required for this salon';
      }

      // Handle HTTP status codes
      if (statusCode != null) {
        switch (statusCode) {
          case 400:
            return error['message'] ?? 'Invalid request. Please check your inputs.';
          case 401:
            return 'Your session has expired. Please login again.';
          case 403:
            return 'You don\'t have permission to access this resource.';
          case 404:
            return 'The requested resource was not found.';
          case 429:
            return 'Too many requests. Please wait a moment and try again.';
          case 500:
          case 502:
          case 503:
            return 'Server error. Please try again later.';
          default:
            return error['message'] ?? 'Something went wrong. Please try again.';
        }
      }

      // Return message if available
      if (error['message'] != null) {
        return error['message'] as String;
      }
    }

    // Handle string errors
    final errorStr = error.toString();
    
    if (errorStr.contains('SocketException') || errorStr.contains('NetworkException')) {
      return 'No internet connection. Please check your network.';
    }

    if (errorStr.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }

    if (errorStr.contains('FormatException')) {
      return 'Invalid data received from server.';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Check if error is subscription required
  static bool isSubscriptionRequired(dynamic error) {
    if (error is Map) {
      return error['statusCode'] == 402 || 
             error['code'] == 'SUBSCRIPTION_REQUIRED';
    }
    return error.toString().contains('SUBSCRIPTION_REQUIRED') ||
           error.toString().contains('402');
  }

  /// Check if error is authentication error
  static bool isAuthError(dynamic error) {
    if (error is Map) {
      return error['statusCode'] == 401;
    }
    return error.toString().contains('401') ||
           error.toString().contains('Unauthorized');
  }

  /// Check if error is rate limiting
  static bool isRateLimitError(dynamic error) {
    if (error is Map) {
      return error['statusCode'] == 429;
    }
    return error.toString().contains('429') ||
           error.toString().contains('Too many requests');
  }

  /// Check if error is network error
  static bool isNetworkError(dynamic error) {
    final errorStr = error.toString();
    return errorStr.contains('SocketException') ||
           errorStr.contains('NetworkException') ||
           errorStr.contains('TimeoutException');
  }
}
