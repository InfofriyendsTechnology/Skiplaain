class AppConfig {
  // API Base URL - can be overridden with --dart-define
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:61026/api',
  );

  // Razorpay Key - can be overridden with --dart-define
  static const String razorpayKeyId = String.fromEnvironment(
    'RAZORPAY_KEY_ID',
    defaultValue: 'rzp_test_key', // Replace with actual test key
  );

  // Other config
  static const String appName = 'Skiplaain';
  static const String version = '1.0.0';
}
