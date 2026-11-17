abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _emailConfirmationRedirectUrl = String.fromEnvironment(
    'EMAIL_CONFIRMATION_REDIRECT_URL',
  );

  /// The exact URL Supabase will redirect to after confirming an e-mail.
  ///
  /// On web, the deployed app's current origin is a safe default. Native
  /// builds must provide a registered deep-link URL with --dart-define.
  static String? get emailConfirmationRedirectUrl {
    if (_emailConfirmationRedirectUrl.trim().isNotEmpty) {
      return _emailConfirmationRedirectUrl;
    }

    final currentUrl = Uri.base;
    if (currentUrl.scheme != 'http' && currentUrl.scheme != 'https') {
      return null;
    }

    return currentUrl
        .replace(path: '/', query: null, fragment: '/email-confirmado')
        .toString();
  }

  static bool get isEmailConfirmationCallback =>
      Uri.base.fragment == '/email-confirmado' ||
      Uri.base.path == '/email-confirmado';

  static bool get hasSupabaseCredentials =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.trim().isNotEmpty;
}
