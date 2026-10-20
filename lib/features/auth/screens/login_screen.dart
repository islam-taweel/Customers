import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/localization/language_controller.dart';
import '../../../data/api/erp_auth_service.dart';
import '../../../data/api/erp_config.dart';
import '../controllers/auth_controller.dart';

/// شاشة تسجيل الدخول: ترويسة متدرجة بشعار التطبيق في دائرة مضيئة،
/// وتحتها بطاقة الدخول (البريد وكلمة المرور) بحركة دخول ناعمة.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _logoAsset = 'assets/splash/logo.png';
  static const double _headerHeight = 320;

  final _formKey = GlobalKey<FormState>();
  // اسم الموقع المحفوظ (أو الافتراضي): الخادم واحد لكل العملاء ولكل عميل موقعه
  final _siteController = TextEditingController(text: ErpConfig.hostHeader);
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _siteController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    FocusScope.of(context).unfocus();

    final auth = context.read<AuthController>();
    // يجب ضبط الموقع قبل الدخول: ترويسة Host تحدد أي موقع يتصل به الطلب
    await ErpConfig.setSite(_siteController.text);
    await auth.login(_emailController.text, _passwordController.text);

    TextInput.finishAutofillContext(shouldSave: auth.isAuthenticated);
    // عند النجاح تستبدل البوابة هذه الشاشة. عند الخطأ في البيانات نفرّغ كلمة المرور.
    if (mounted && auth.failure == AuthFailure.invalidCredentials) {
      _passwordController.clear();
    }
  }

  String? _failureMessage(AuthController auth) => switch (auth.failure) {
        AuthFailure.invalidCredentials => AppStrings.loginInvalid,
        AuthFailure.network => AppStrings.loginNetworkError,
        AuthFailure.server => AppStrings.loginServerError,
        null => null,
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: _headerHeight,
            child: _Header(),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: _LanguageButton(),
                      ),
                      const _Logo(logoAsset: _logoAsset),
                      const SizedBox(height: 26),
                      _EntranceFade(child: _buildCard(auth, scheme)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AuthController auth, ColorScheme scheme) {
    final text = Theme.of(context).textTheme;
    final message = _failureMessage(auth);
    final showLockWarning =
        auth.failure == AuthFailure.invalidCredentials &&
        auth.failedAttempts >= AuthController.lockWarningAfter;

    return Material(
      color: scheme.surface,
      elevation: 8,
      shadowColor: Colors.black38,
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.loginTitle,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              AppStrings.loginSubtitle,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (auth.sessionExpired)
                    _Banner(
                      icon: Icons.lock_clock_outlined,
                      text: AppStrings.sessionExpiredNotice,
                      background: scheme.secondaryContainer,
                      foreground: scheme.onSecondaryContainer,
                    ),
                  if (message != null)
                    _Banner(
                      icon: Icons.error_outline,
                      text: showLockWarning
                          ? '$message\n${AppStrings.loginLockWarning}'
                          : message,
                      background: scheme.errorContainer,
                      foreground: scheme.onErrorContainer,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _siteController,
                      enabled: !auth.isBusy,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      enableSuggestions: false,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).nextFocus(),
                      decoration: _fieldDecoration(
                        scheme,
                        label: AppStrings.siteLabel,
                        icon: Icons.dns_outlined,
                      ).copyWith(helperText: AppStrings.siteHelper),
                      validator: (value) =>
                          ErpConfig.normalizeSite(value ?? '').isEmpty
                              ? AppStrings.siteRequired
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _emailController,
                      enabled: !auth.isBusy,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      autofillHints: const [
                        AutofillHints.username,
                        AutofillHints.email,
                      ],
                      onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                      decoration: _fieldDecoration(
                        scheme,
                        label: AppStrings.emailLabel,
                        icon: Icons.alternate_email,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? AppStrings.emailRequired
                              : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      enabled: !auth.isBusy,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      textDirection: TextDirection.ltr,
                      autocorrect: false,
                      enableSuggestions: false,
                      autofillHints: const [AutofillHints.password],
                      onFieldSubmitted: (_) => _submit(),
                      decoration: _fieldDecoration(
                        scheme,
                        label: AppStrings.passwordLabel,
                        icon: Icons.lock_outline,
                        suffix: IconButton(
                          tooltip: _obscurePassword
                              ? AppStrings.showPassword
                              : AppStrings.hidePassword,
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      validator: (value) => (value == null || value.isEmpty)
                          ? AppStrings.passwordRequired
                          : null,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: auth.isBusy ? null : _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: auth.isBusy
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: scheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(AppStrings.loggingIn),
                      ],
                    )
                  : Text(
                      AppStrings.loginButton,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(
    ColorScheme scheme, {
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    );
  }
}

/// الخلفية المتدرجة بالأعلى بحافة سفلية منحنية ودائرتين زخرفيتين شفافتين.
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = MediaQuery.sizeOf(context).width;

    return ClipRRect(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.elliptical(width, 70),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, Colors.black, 0.45)!,
            ],
          ),
        ),
        child: Stack(
          children: [
            PositionedDirectional(
              top: -70,
              end: -50,
              child: _Bubble(size: 220, alpha: 0.09),
            ),
            PositionedDirectional(
              bottom: 10,
              start: -60,
              child: _Bubble(size: 170, alpha: 0.07),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  final double alpha;

  const _Bubble({required this.size, required this.alpha});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: alpha),
      ),
    );
  }
}

/// الشعار في دائرة بيضاء بظل عميق، يحيط بها هالة شفافة، ويظهر بحركة تكبير ناعمة.
class _Logo extends StatelessWidget {
  final String logoAsset;

  const _Logo({required this.logoAsset});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(scale: 0.6 + 0.4 * value, child: child),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Container(
              width: 128,
              height: 128,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Image.asset(logoAsset, fit: BoxFit.contain),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            AppStrings.appName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// تظهر البطاقة بتلاشٍ وانزلاق خفيف للأعلى.
class _EntranceFade extends StatelessWidget {
  final Widget child;

  const _EntranceFade({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 36 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;
  final Color foreground;

  const _Banner({
    required this.icon,
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: foreground),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: foreground, height: 1.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// تبديل اللغة من الشاشة نفسها (القائمة الجانبية غير متاحة قبل الدخول).
class _LanguageButton extends StatelessWidget {
  const _LanguageButton();

  @override
  Widget build(BuildContext context) {
    final language = context.watch<LanguageController>();
    final isArabic = language.language == AppLanguage.arabic;

    return TextButton.icon(
      onPressed: () => language.setLanguage(
        isArabic ? AppLanguage.english : AppLanguage.arabic,
      ),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      icon: const Icon(Icons.language, size: 20),
      label: Text(isArabic ? 'English' : 'العربية'),
    );
  }
}
