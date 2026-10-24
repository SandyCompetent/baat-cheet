import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../route_generator.dart';
import '../../theme_data.dart';
import '../widgets/legal_dialog.dart';
import 'auth_service.dart';

/// Unified single login/sign-up screen for ChatBud.
///
/// Features:
/// - Single email & password form (auto-detects login vs account creation)
/// - No "Already have an account? Sign In" or "Don't have an account? Sign Up" toggles
/// - Google Sign-In and Apple Sign-In support
/// - Forgot password reset dialog
/// - Compliant with Soft Minimalist Slate design system
class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _setLoading(bool val) => setState(() => _isLoading = val);
  void _setError(String? msg) => setState(() => _errorMessage = msg);

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  Future<void> _handleUnifiedAuth() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (!_isValidEmail(email)) {
      _setError('Please enter a valid email address.');
      return;
    }
    if (pass.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }

    _setLoading(true);
    _setError(null);

    final res = await AuthService.authenticateUnified(
      email: email,
      password: pass,
    );
    _setLoading(false);

    if (res.success) {
      _onAuthSuccess();
    } else {
      _setError(res.errorMessage);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    _setLoading(true);
    _setError(null);

    final res = await AuthService.signInWithGoogle();
    _setLoading(false);

    if (res.success) {
      _onAuthSuccess();
    } else {
      if (res.errorMessage != null &&
          !res.errorMessage!.contains('cancelled')) {
        _setError(res.errorMessage);
      }
    }
  }

  Future<void> _handleAppleSignIn() async {
    _setLoading(true);
    _setError(null);

    final res = await AuthService.signInWithApple();
    _setLoading(false);

    if (res.success) {
      _onAuthSuccess();
    } else {
      if (res.errorMessage != null &&
          !res.errorMessage!.contains('cancelled')) {
        _setError(res.errorMessage);
      }
    }
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => _ForgotPasswordDialog(
        initialEmail: _emailCtrl.text.trim(),
      ),
    );
  }

  void _onAuthSuccess() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      homeRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop())
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: context.accent,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 24),
                    _BrandHeader(),
                    const SizedBox(height: 28),
                    _buildFormCard(context),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBanner(message: _errorMessage!),
                    ],
                    const SizedBox(height: 32),
                    _LegalLinksRow(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return Column(
      key: const ValueKey('unifiedAuthForm'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome to ChatBud',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your email to sign in or create an account.',
          style: TextStyle(color: context.textSecondary, fontSize: 15),
        ),
        const SizedBox(height: 24),

        // Email field
        _AuthField(
          controller: _emailCtrl,
          hint: 'Email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),

        // Password field
        _AuthField(
          controller: _passwordCtrl,
          hint: 'Password (min 6 characters)',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleUnifiedAuth,
        ),
        const SizedBox(height: 10),

        // Forgot password
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: _showForgotPasswordDialog,
            child: Text(
              'Forgot password?',
              style: TextStyle(
                color: context.accent,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Primary Continue Button
        _PrimaryButton(
          label: 'Continue',
          isLoading: _isLoading,
          onTap: _handleUnifiedAuth,
        ),
        const SizedBox(height: 24),

        // Divider
        Row(
          children: [
            Expanded(child: Divider(color: context.borderSubtle)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                'or continue with',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(child: Divider(color: context.borderSubtle)),
          ],
        ),
        const SizedBox(height: 20),

        // Google Sign-In
        _SocialButton(
          label: 'Continue with Google',
          icon: _buildGoogleLogo(),
          onTap: _isLoading ? null : _handleGoogleSignIn,
        ),
        const SizedBox(height: 12),

        // Apple Sign-In
        _SocialButton(
          label: 'Continue with Apple',
          icon: Icon(
            Icons.apple,
            size: 22,
            color: context.isDark ? Colors.black : Colors.white,
          ),
          isApple: true,
          onTap: _isLoading ? null : _handleAppleSignIn,
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
      ),
      child: const Text(
        'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: 15,
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto',
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            color: context.accentSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.chat_bubble_outline_rounded,
            color: context.accent,
            size: 34,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'ChatBud',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: context.accentSubtle,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.accent.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            'Portfolio Demo · Non-Commercial',
            style: TextStyle(
              color: context.accent,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;
  final bool isApple;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isApple = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Color textColor;
    final Border? border;

    if (isApple) {
      bgColor = context.isDark ? Colors.white : Colors.black;
      textColor = context.isDark ? Colors.black : Colors.white;
      border = null;
    } else {
      bgColor = context.bgSurface;
      textColor = context.textPrimary;
      border = Border.all(color: context.borderSubtle);
    }

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: textColor,
          side: border != null
              ? BorderSide(color: context.borderSubtle)
              : BorderSide.none,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            icon,
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () => LegalDocs.showTerms(context),
              child: Text(
                'Terms of Service',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('•', style: TextStyle(color: context.textMuted)),
            ),
            GestureDetector(
              onTap: () => LegalDocs.showPrivacy(context),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: context.textMuted,
                  fontSize: 12,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Portfolio Demo • Not for Commercial Use',
          style: TextStyle(
            color: context.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.statusDanger.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.statusDanger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded,
              color: context.statusDanger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.statusDanger,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final IconData prefixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.prefixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  State<_AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<_AuthField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      obscureText: widget.isPassword && _hidden,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      style: TextStyle(
        color: context.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      onSubmitted:
          widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: Icon(widget.prefixIcon, color: context.textMuted, size: 20),
        suffixIcon: widget.isPassword
            ? IconButton(
                onPressed: () => setState(() => _hidden = !_hidden),
                icon: Icon(
                  _hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: context.textMuted,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: context.bgElevated,
        hintStyle: TextStyle(color: context.textMuted, fontSize: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: context.accent, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryButton({
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: context.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: context.accent.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const _ForgotPasswordDialog({required this.initialEmail});

  @override
  State<_ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  late final TextEditingController _resetCtrl;
  bool _isSending = false;
  String? _resetError;

  @override
  void initState() {
    super.initState();
    _resetCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _resetCtrl.dispose();
    super.dispose();
  }

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  Future<void> _handleSend() async {
    final email = _resetCtrl.text.trim();
    if (!_isValidEmail(email)) {
      setState(() => _resetError = 'Please enter a valid email address.');
      return;
    }
    setState(() {
      _isSending = true;
      _resetError = null;
    });

    final res = await AuthService.sendPasswordResetEmail(email);
    if (!mounted) return;

    if (res.success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset link dispatched to $email'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() {
        _isSending = false;
        _resetError = res.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter your email address to receive a secure password reset link.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 16),
          _AuthField(
            controller: _resetCtrl,
            hint: 'Email address',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
          ),
          if (_resetError != null) ...[
            const SizedBox(height: 10),
            Text(
              _resetError!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSending ? null : _handleSend,
          child: _isSending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send Link'),
        ),
      ],
    );
  }
}
