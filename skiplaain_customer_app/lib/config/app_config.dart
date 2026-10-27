class AppConfig {
  static const String _defaultBaseUrl = 'http://localhost:3000';
  
  static String get apiBaseUrl {
    const url = String.fromEnvironment('API_BASE_URL', defaultValue: _defaultBaseUrl);
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static String get razorpayKeyId {
    return const String.fromEnvironment('RAZORPAY_KEY_ID', defaultValue: 'rzp_test_key');
  }
}
