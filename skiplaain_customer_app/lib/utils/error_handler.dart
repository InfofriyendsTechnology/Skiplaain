import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppError {
  final int? statusCode;
  final String message;
  final String? userMessage;

  AppError({
    this.statusCode,
    required this.message,
    this.userMessage,
  });

  factory AppError.fromResponse(int statusCode, Map<String, dynamic>? body) {
    String message = 'An error occurred';
    String? userMessage;

    if (body != null && body['message'] != null) {
      message = body['message'];
    }

    switch (statusCode) {
      case 401:
        userMessage = 'Session expired. Please login again.';
        break;
      case 402:
        userMessage = body?['message'] ?? 'You need an active subscription to book at this salon.';
        break;
      case 429:
        userMessage = 'Too many requests. Please wait a moment and try again.';
        break;
      case 500:
      case 502:
      case 503:
        userMessage = 'Server error. Please try again later.';
        break;
      default:
        userMessage = message;
    }

    return AppError(
      statusCode: statusCode,
      message: message,
      userMessage: userMessage,
    );
  }

  factory AppError.network() {
    return AppError(
      message: 'Network error',
      userMessage: 'No internet connection. Please check your network and try again.',
    );
  }

  bool get isSubscriptionRequired => statusCode == 402;
  bool get isUnauthorized => statusCode == 401;
  bool get isRateLimited => statusCode == 429;
}

class ErrorHandler {
  static void showError(
    BuildContext context,
    AppError error, {
    VoidCallback? onSubscriptionRequired,
  }) {
    if (error.isUnauthorized) {
      handleUnauthorized(context);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error.userMessage ?? error.message),
        backgroundColor: error.isSubscriptionRequired ? Colors.orange : Colors.red,
        duration: Duration(seconds: error.isRateLimited ? 5 : 3),
        action: error.isSubscriptionRequired && onSubscriptionRequired != null
            ? SnackBarAction(
                label: 'View Plans',
                textColor: Colors.white,
                onPressed: onSubscriptionRequired,
              )
            : null,
      ),
    );
  }

  static Future<void> handleUnauthorized(BuildContext context) async {
    // Clear stored session
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('customer_data');
    
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}
