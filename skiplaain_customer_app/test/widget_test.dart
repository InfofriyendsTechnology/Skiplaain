import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skiplaain_customer_app/utils/error_handler.dart';
import 'package:skiplaain_customer_app/screens/premium/my_plans_screen.dart';

void main() {
  group('ErrorHandler Tests', () {
    test('AppError.fromResponse should parse 402 correctly', () {
      final error = AppError.fromResponse(402, {'message': 'Subscription required'});
      
      expect(error.statusCode, 402);
      expect(error.isSubscriptionRequired, true);
      expect(error.userMessage, isNotNull);
    });

    test('AppError.fromResponse should parse 401 correctly', () {
      final error = AppError.fromResponse(401, {'message': 'Unauthorized'});
      
      expect(error.statusCode, 401);
      expect(error.isUnauthorized, true);
      expect(error.userMessage, 'Session expired. Please login again.');
    });

    test('AppError.fromResponse should parse 429 correctly', () {
      final error = AppError.fromResponse(429, {'message': 'Too many requests'});
      
      expect(error.statusCode, 429);
      expect(error.isRateLimited, true);
      expect(error.userMessage, contains('wait'));
    });

    test('AppError.network should create network error', () {
      final error = AppError.network();
      
      expect(error.statusCode, null);
      expect(error.message, 'Network error');
      expect(error.userMessage, contains('internet'));
    });
  });

  group('MyPlansScreen Widget Tests', () {
    testWidgets('MyPlansScreen should display loading initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyPlansScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MyPlansScreen should have AppBar with title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyPlansScreen(),
        ),
      );

      expect(find.text('My Subscriptions'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
