import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../route_generator.dart';
import '../../theme_data.dart';
import '../widgets/legal_dialog.dart';
import 'auth_service.dart';

enum _AuthMode {
  emailInput,
  signInPassword,
  createAccount,
  forgotPassword,
}

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  _AuthMode _mode = _AuthMode.emailInput;
  bool _isLoading = false;
  String? _errorMessage;

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _setMode(_AuthMode mode) {
    setState(() {
      _errorMessage = null;
      _mode = mode;
    });
  }

  void _setLoading(bool val) => setState(() => _isLoading = val);
  void _setError(String? msg) => setState(() => _errorMessage = msg);

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w\-\.]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(e.trim());

  Future<void> _handleEmailContinue() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      _setError('Please enter a valid email address.');
      return;
    }
    _setMode(_AuthMode.signInPassword);
  }

  Future<void> _handleSignIn() async {
    final email = _emailCtrl.text.trim();
    final pass = _passwordCtrl.text;
    if (pass.isEmpty) {
      _setError('Please enter your password.');
      return;
    }

    _setLoading(true);
    _setError(null);

    final res = await AuthService.signIn(email: email, password: pass);
    _setLoading(false);

    if (res.success) {
      _onAuthSuccess();
    } else {
      _setError(res.errorMessage);
    }
  }

  Future<void> _handleCreateAccount() async {
    final email = _emailCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final pass = _passwordCtrl.text;

    if (name.isEmpty) {
      _setError('Please enter your display name.');
      return;
    }
    if (pass.length < 6) {
      _setError('Password must be at least 6 characters.');
      return;
    }

    _setLoading(true);
    _setError(null);

    final res = await AuthService.createAccount(
      email: email,
      password: pass,
      displayName: name,
    );
    _setLoading(false);

    if (res.success) {
      _onAuthSuccess();
    } else {
      _setError(res.errorMessage);
    }
  }

  Future<void> _handleSendResetEmail() async {
    final email = _emailCtrl.text.trim();
    if (!_isValidEmail(email)) {
      _setError('Please enter a valid email address.');
      return;
    }

    _setLoading(true);
    _setError(null);

    final res = await AuthService.sendPasswordResetEmail(email);
    _setLoading(false);

    if (res.success) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Password Reset Sent'),
            content: Text(
              'A password reset link has been dispatched to $email. Follow the link in your email to choose a new password, then return here to sign in.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _setMode(_AuthMode.signInPassword);
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } else {
      _setError(res.errorMessage);
    }
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
            if (_mode != _AuthMode.emailInput)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, top: 8),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded,
                        color: context.accent, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (_mode == _AuthMode.forgotPassword) {
                        _setMode(_AuthMode.signInPassword);
                      } else {
                        _setMode(_AuthMode.emailInput);
                      }
                    },
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    _BrandHeader(),
                    const SizedBox(height: 32),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      child: _buildCurrentCard(context),
                    ),
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

  Widget _buildCurrentCard(BuildContext context) {
    return switch (_mode) {
      _AuthMode.emailInput => _buildEmailCard(context),
      _AuthMode.signInPassword => _buildSignInCard(context),
      _AuthMode.createAccount => _buildCreateAccountCard(context),
      _AuthMode.forgotPassword => _buildForgotPasswordCard(context),
    };
  }

  Widget _buildEmailCard(BuildContext context) {
    return Column(
      key: const ValueKey('emailInput'),
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
        const SizedBox(height: 28),
        _AuthField(
          controller: _emailCtrl,
          hint: 'Email address',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleEmailContinue,
        ),
        const SizedBox(height: 20),
        _PrimaryButton(
          label: 'Continue',
          isLoading: _isLoading,
          onTap: _handleEmailContinue,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton(
            onPressed: () async {
              await AuthService.signInAnonymously();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  homeRoute,
                  (route) => false,
                );
              }
            },
            child: Text(
              'Continue as Guest',
              style: TextStyle(
                color: context.textSecondary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInCard(BuildContext context) {
    return Column(
      key: const ValueKey('signInPassword'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter your password',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _emailCtrl.text.trim(),
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _AuthField(
          controller: _passwordCtrl,
          hint: 'Password',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleSignIn,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => _setMode(_AuthMode.createAccount),
              child: Text(
                'Need an account? Sign up',
                style: TextStyle(
                  color: context.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _setMode(_AuthMode.forgotPassword),
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: context.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Sign In',
          isLoading: _isLoading,
          onTap: _handleSignIn,
        ),
      ],
    );
  }

  Widget _buildCreateAccountCard(BuildContext context) {
    return Column(
      key: const ValueKey('createAccount'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create your account',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Joining with ${_emailCtrl.text.trim()}',
          style: TextStyle(color: context.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 24),
        _AuthField(
          controller: _nameCtrl,
          hint: 'Full Name',
          prefixIcon: Icons.person_outline_rounded,
          keyboardType: TextInputType.name,
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 14),
        _AuthField(
          controller: _passwordCtrl,
          hint: 'Password (min 6 characters)',
          prefixIcon: Icons.lock_outline_rounded,
          isPassword: true,
          textInputAction: TextInputAction.done,
          onSubmitted: _handleCreateAccount,
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () => _setMode(_AuthMode.signInPassword),
          child: Text(
            'Already have an account? Sign In',
            style: TextStyle(
              color: context.accent,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Register Account',
          isLoading: _isLoading,
          onTap: _handleCreateAccount,
        ),
      ],
    );
  }

  Widget _buildForgotPasswordCard(BuildContext context) {
    return Column(
      key: const ValueKey('forgotPassword'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reset Password',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We will send a password reset email to ${_emailCtrl.text.trim()}',
          style: TextStyle(
            color: context.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _PrimaryButton(
          label: 'Send Reset Link',
          isLoading: _isLoading,
          onTap: _handleSendResetEmail,
        ),
      ],
    );
  }
}

class _BrandHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: context.accentSubtle,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_outline_rounded,
              color: context.accent, size: 36),
        ),
        const SizedBox(height: 16),
        Text(
          'ChatBud',
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _LegalLinksRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
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
