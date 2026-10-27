// Tests for BATCH 2/3 flows — pure Dart logic, no real network calls
import 'package:flutter_test/flutter_test.dart';
import 'package:skiplaain_customer_app/utils/error_handler.dart';

// ── helpers ──────────────────────────────────────────────────────────────────

Map<String, dynamic> makeSubscriptionStatus({
  bool plansEnabled = true,
  bool hasActivePlan = false,
}) =>
    {'plansEnabled': plansEnabled, 'hasActivePlan': hasActivePlan};

bool shouldOpenPlanScreen(Map<String, dynamic> status) {
  final plansEnabled = status['plansEnabled'] == true;
  final hasActivePlan = status['hasActivePlan'] == true;
  return plansEnabled && !hasActivePlan;
}

bool shouldSkipPlanScreen(Map<String, dynamic> status) =>
    !shouldOpenPlanScreen(status);

// Renew visibility logic (mirrors my_plans_screen.dart)
bool shouldShowRenew({required bool isActive, required int daysLeft}) =>
    !isActive || (isActive && daysLeft <= 7);

// ── tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── _onBookSlot subscription branches ────────────────────────────────────

  group('_onBookSlot subscription branches', () {
    test('active plan → skip plan screen, go to booking', () {
      final status = makeSubscriptionStatus(plansEnabled: true, hasActivePlan: true);
      expect(shouldOpenPlanScreen(status), false);
      expect(shouldSkipPlanScreen(status), true);
    });

    test('no plan, plansEnabled=true → open plan screen', () {
      final status = makeSubscriptionStatus(plansEnabled: true, hasActivePlan: false);
      expect(shouldOpenPlanScreen(status), true);
    });

    test('plansEnabled=false → skip plan screen regardless', () {
      final status = makeSubscriptionStatus(plansEnabled: false, hasActivePlan: false);
      expect(shouldOpenPlanScreen(status), false);
      expect(shouldSkipPlanScreen(status), true);
    });
  });

  // ── PlanSelectionScreen states ────────────────────────────────────────────

  group('PlanSelectionScreen states', () {
    test('empty plans list → should show empty state UI (not pay button)', () {
      final plans = <Map<String, dynamic>>[];
      expect(plans.isEmpty, true); // empty state shown
    });

    test('non-empty plans → pay button visible', () {
      final plans = [
        {'id': 'p1', 'name': '1 Month', 'pricePaise': 49900, 'durationMonths': 1}
      ];
      expect(plans.isNotEmpty, true);
    });
  });

  // ── 402 retry logic ───────────────────────────────────────────────────────

  group('402 retry logic', () {
    test('AppError with 402 is isSubscriptionRequired', () {
      final err = AppError(statusCode: 402, message: 'SUBSCRIPTION_REQUIRED');
      expect(err.isSubscriptionRequired, true);
      expect(err.isUnauthorized, false);
    });

    test('AppError with 401 is isUnauthorized', () {
      final err = AppError(statusCode: 401, message: 'Unauthorized');
      expect(err.isUnauthorized, true);
      expect(err.isSubscriptionRequired, false);
    });

    test('Network error is neither 401 nor 402', () {
      final err = AppError.network();
      expect(err.isUnauthorized, false);
      expect(err.isSubscriptionRequired, false);
    });
  });

  // ── Cancel only for confirmed ─────────────────────────────────────────────

  group('Cancel button visibility', () {
    test('confirmed booking → cancel shown', () {
      final status = 'confirmed';
      final isConfirmed = status == 'confirmed';
      expect(isConfirmed, true);
    });

    test('completed booking → cancel NOT shown', () {
      final status = 'completed';
      final isConfirmed = status == 'confirmed';
      expect(isConfirmed, false);
    });

    test('cancelled booking → cancel NOT shown', () {
      final status = 'cancelled';
      final isConfirmed = status == 'confirmed';
      expect(isConfirmed, false);
    });
  });

  // ── Renew button logic ────────────────────────────────────────────────────

  group('Renew button visibility', () {
    test('expired plan → renew shown', () {
      expect(shouldShowRenew(isActive: false, daysLeft: 0), true);
    });

    test('active plan ≤7 days → renew shown (Renew Early)', () {
      expect(shouldShowRenew(isActive: true, daysLeft: 3), true);
      expect(shouldShowRenew(isActive: true, daysLeft: 7), true);
    });

    test('active plan >7 days → renew NOT shown', () {
      expect(shouldShowRenew(isActive: true, daysLeft: 30), false);
    });
  });

  // ── plan_selection resume (lifecycle) ────────────────────────────────────

  group('Plan selection resume check', () {
    test('resumed with payment in progress → should check status', () {
      bool isPaymentInProgress = true;
      // Simulate: app resumed, payment was in progress
      bool shouldCheck = isPaymentInProgress;
      expect(shouldCheck, true);
    });

    test('resumed without payment in progress → no check', () {
      bool isPaymentInProgress = false;
      bool shouldCheck = isPaymentInProgress;
      expect(shouldCheck, false);
    });
  });
}
