class AppConfig {
  const AppConfig._();

  static const String recaptchaEnterpriseSiteKey = String.fromEnvironment(
    'RECAPTCHA_ENTERPRISE_SITE_KEY',
  );

  static const String geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-3.8-flash',
  );

  static bool get hasAppCheckSiteKey =>
      recaptchaEnterpriseSiteKey.trim().isNotEmpty;
}
