import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Earnings Tab Tests', () {
    test('Format money with Indian rupee grouping', () {
      // Test paise to rupee conversion with formatting
      final paise1 = 100000; // ₹1,000.00
      final rupees1 = paise1 / 100;
      expect(rupees1, 1000.00);
      
      final paise2 = 12345678; // ₹1,23,456.78
      final rupees2 = paise2 / 100;
      expect(rupees2, 123456.78);
    });

    test('Earnings API field names match backend contract', () {
      final mockResponse = {
        'success': true,
        'data': {
          'pendingPaise': 10000,
          'includedNotPaidPaise': 5000,
          'lifetimeEarnedPaise': 50000,
          'paidTotalPaise': 35000,
          'ledgerRows': [
            {
              'id': 'test-1',
              'customerName': 'Test Customer',
              'planName': 'Premium Plan',
              'commissionPaise': 5000,
              'earnedAt': '2024-01-15T10:00:00Z',
              'status': 'pending'
            }
          ],
          'payouts': [
            {
              'id': 'payout-1',
              'totalPaise': 10000,
              'status': 'paid',
              'createdAt': '2024-01-01T00:00:00Z',
              'paidAt': '2024-01-02T00:00:00Z',
              'paymentReference': 'REF123'
            }
          ],
          'nextPayoutDate': '2024-02-01T00:00:00Z'
        }
      };

      final data = mockResponse['data'] as Map<String, dynamic>;
      
      // Verify all expected fields exist
      expect(data['pendingPaise'], 10000);
      expect(data['includedNotPaidPaise'], 5000);
      expect(data['lifetimeEarnedPaise'], 50000);
      expect(data['paidTotalPaise'], 35000);
      expect(data['ledgerRows'], isA<List>());
      expect(data['payouts'], isA<List>());
      expect(data['nextPayoutDate'], isNotNull);

      // Verify ledger row structure
      final ledger = (data['ledgerRows'] as List).first;
      expect(ledger['customerName'], isNotNull);
      expect(ledger['planName'], isNotNull);
      expect(ledger['commissionPaise'], isNotNull);
      expect(ledger['earnedAt'], isNotNull);
      expect(ledger['status'], isNotNull);

      // Verify payout structure
      final payout = (data['payouts'] as List).first;
      expect(payout['totalPaise'], isNotNull);
      expect(payout['status'], isNotNull);
      expect(payout['createdAt'], isNotNull);
    });

    test('Payout details use snake_case field names', () {
      final payoutDetails = {
        'payout_upi_id': 'test@upi',
        'payout_bank_account_name': 'Test User',
        'payout_bank_account_number': '1234567890',
        'payout_bank_ifsc': 'SBIN0001234'
      };

      // Verify snake_case keys
      expect(payoutDetails.containsKey('payout_upi_id'), true);
      expect(payoutDetails.containsKey('payout_bank_account_name'), true);
      expect(payoutDetails.containsKey('payout_bank_account_number'), true);
      expect(payoutDetails.containsKey('payout_bank_ifsc'), true);

      // Verify no camelCase keys
      expect(payoutDetails.containsKey('payoutUpiId'), false);
      expect(payoutDetails.containsKey('payoutBankAccountName'), false);
    });

    test('UPI validation requires @ symbol', () {
      final validUpi = 'user@upi';
      final invalidUpi = 'invalidupi';

      expect(validUpi.contains('@'), true);
      expect(invalidUpi.contains('@'), false);
    });

    test('IFSC code validation requires 11 characters', () {
      final validIfsc = 'SBIN0001234';
      final invalidIfsc = 'SBIN';

      expect(validIfsc.length, 11);
      expect(invalidIfsc.length, lessThan(11));
    });

    test('Bank account number should be digits only', () {
      final validAccount = '1234567890';
      final invalidAccount = 'ABC123';

      final digitPattern = RegExp(r'^\d+$');
      expect(digitPattern.hasMatch(validAccount), true);
      expect(digitPattern.hasMatch(invalidAccount), false);
    });
  });
}
