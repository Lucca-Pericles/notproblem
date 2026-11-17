abstract final class AppConfig {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const _emailConfirmationRedirectUrl = String.fromEnvironment(
    'EMAIL_CONFIRMATION_REDIRECT_URL',
  );

  /// The URL Supabase will redirect to after confirming an e-mail.
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
        .replace(path: '/', query: null, fragment: null)
        .toString();
  }

  /// Supabase returns either a PKCE code in the query string or a session in
  /// the fragment after the user follows an e-mail confirmation link.
  static bool get isEmailConfirmationCallback {
    final currentUrl = Uri.base;
    if (currentUrl.queryParameters.containsKey('code')) return true;

    final fragment = currentUrl.fragment;
    if (fragment.isEmpty) return false;

    final parameters = Uri.splitQueryString(fragment);
    return parameters.containsKey('access_token') ||
        parameters['type'] == 'signup';
  }

  static bool get hasSupabaseCredentials =>
      supabaseUrl.startsWith('https://') &&
      supabasePublishableKey.trim().isNotEmpty;
}
