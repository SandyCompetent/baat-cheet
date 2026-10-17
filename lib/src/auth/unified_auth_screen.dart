import 'package:flutter/material.dart';

import '../../route_generator.dart';
import '../../theme_data.dart';
import 'auth_service.dart';
import 'otp_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// UnifiedAuthScreen — single-screen step machine covering all three flows:
//
//   Flow A (existing user):
//     enterEmail → existingUserPassword → [logged in]
//
//   Flow B (new user):
//     enterEmail → verifyOtp(newAccount) → createAccount → [logged in]
//
//   Flow C (forgot password):
//     enterEmail → forgotVerifyOtp → setNewPassword → [logged in via signIn]
// ─────────────────────────────────────────────────────────────────────────────

enum AuthStep {
  enterEmail,
  existingUserPassword,
  verifyOtpNewAccount,
  createAccount,
  verifyOtpForgotPassword,
  setNewPassword,
}

class UnifiedAuthScreen extends StatefulWidget {
  const UnifiedAuthScreen({super.key});

  @override
  State<UnifiedAuthScreen> createState() => _UnifiedAuthScreenState();
}

class _UnifiedAuthScreenState extends State<UnifiedAuthScreen> {
  AuthStep _step = AuthStep.enterEmail;

  // Controllers
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  // State
  bool _loading = false;
  String? _error;
  String? _sentOtp; // Mock OTP generated for testing

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error != null) setState(() => _error = null);
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Step Handlers
  // ───────────────────────────────────────────────────────────────────────────

  /// Step 1: User enters email. We check if user exists.
  Future<void> _handleEmailSubmitted() async {
    _clearError();
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() => _loading = true);
    try {
      final exists = await AuthService.emailExists(email);
      setState(() => _loading = false);

      if (exists) {
        // Flow A: Existing user -> Prompt password
        setState(() => _step = AuthStep.existingUserPassword);
      } else {
        // Flow B: New user -> Generate & send OTP
        await _sendOtpAndGoTo(AuthStep.verifyOtpNewAccount, email);
      }
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  /// Flow A: Existing user enters password.
  Future<void> _handleSignIn() async {
    _clearError();
    final password = _passwordCtrl.text;
    if (password.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.signIn(
      email: _emailCtrl.text.trim(),
      password: password,
    );
    setState(() => _loading = false);

    if (res.success) {
      if (!mounted) return;
      _onAuthSuccess();
    } else {
      setState(() => _error = res.errorMessage);
    }
  }

  /// Flow A -> Forgot Password link clicked.
  Future<void> _handleForgotPassword() async {
    _clearError();
    _passwordCtrl.clear();
    await _sendOtpAndGoTo(
      AuthStep.verifyOtpForgotPassword,
      _emailCtrl.text.trim(),
    );
  }

  /// Flow B: Verify OTP for new account.
  void _handleVerifyOtpNewAccount() {
    _clearError();
    final entered = _otpCtrl.text.trim();
    final err = OtpManager.verify(
      email: _emailCtrl.text.trim(),
      code: entered,
      purpose: OtpPurpose.newAccount,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _otpCtrl.clear();
    setState(() => _step = AuthStep.createAccount);
  }

  /// Flow C: Verify OTP for forgot password.
  void _handleVerifyOtpForgotPassword() {
    _clearError();
    final entered = _otpCtrl.text.trim();
    final err = OtpManager.verify(
      email: _emailCtrl.text.trim(),
      code: entered,
      purpose: OtpPurpose.forgotPassword,
    );
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    _otpCtrl.clear();
    setState(() => _step = AuthStep.setNewPassword);
  }

  /// Flow B: Create new account.
  Future<void> _handleCreateAccount() async {
    _clearError();
    final name = _nameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.createAccount(
      email: _emailCtrl.text.trim(),
      password: password,
      displayName: name,
    );
    setState(() => _loading = false);

    if (res.success) {
      if (!mounted) return;
      _onAuthSuccess();
    } else {
      setState(() => _error = res.errorMessage);
    }
  }

  /// Flow C: Set new password.
  Future<void> _handleSetNewPassword() async {
    _clearError();
    final newPass = _newPasswordCtrl.text;
    final confirmPass = _confirmPasswordCtrl.text;

    if (newPass.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() => _loading = true);
    final res = await AuthService.sendPasswordResetEmail(_emailCtrl.text.trim());
    setState(() => _loading = false);

    if (res.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset email sent! Check your inbox.'),
        ),
      );
      _onAuthSuccess();
    } else {
      setState(() => _error = res.errorMessage);
    }
  }

  /// Helper to send OTP and transition to an OTP step.
  Future<void> _sendOtpAndGoTo(AuthStep nextStep, String email) async {
    setState(() => _loading = true);
    try {
      final purpose = nextStep == AuthStep.verifyOtpForgotPassword
          ? OtpPurpose.forgotPassword
          : OtpPurpose.newAccount;

      final otp = await OtpManager.send(email: email, purpose: purpose);
      setState(() {
        _loading = false;
        _sentOtp = otp;
        _step = nextStep;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = _cleanError(e);
      });
    }
  }

  void _onAuthSuccess() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      homeRoute,
      (route) => false,
    );
  }

  void _goBackToEmail() {
    setState(() {
      _error = null;
      _sentOtp = null;
      _passwordCtrl.clear();
      _nameCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      _otpCtrl.clear();
      _step = AuthStep.enterEmail;
    });
  }

  String _cleanError(dynamic e) {
    final str = e.toString();
    if (str.contains(']')) {
      return str.split(']').last.trim();
    }
    return str.replaceAll('Exception:', '').trim();
  }

  // ───────────────────────────────────────────────────────────────────────────
  // UI Build
  // ───────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgCanvas,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepCard(context),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStepCard(BuildContext context) {
    switch (_step) {
      case AuthStep.enterEmail:
        return _buildEnterEmailCard(context);
      case AuthStep.existingUserPassword:
        return _buildExistingUserPasswordCard(context);
      case AuthStep.verifyOtpNewAccount:
        return _buildVerifyOtpCard(
          context,
          title: 'Verify Your Email',
          subtitle: 'We sent a 6-digit code to ${_emailCtrl.text.trim()}',
          onVerify: _handleVerifyOtpNewAccount,
        );
      case AuthStep.createAccount:
        return _buildCreateAccountCard(context);
      case AuthStep.verifyOtpForgotPassword:
        return _buildVerifyOtpCard(
          context,
          title: 'Reset Password Verification',
          subtitle: 'We sent a 6-digit code to ${_emailCtrl.text.trim()}',
          onVerify: _handleVerifyOtpForgotPassword,
        );
      case AuthStep.setNewPassword:
        return _buildSetNewPasswordCard(context);
    }
  }

  // ───────────────────────────────────────────────────────────────────────────
  // Step Cards
  // ───────────────────────────────────────────────────────────────────────────

  /// Header logo + title block reused across cards.
  Widget _buildHeader({required String title, required String subtitle}) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.accent.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_rounded,
              size: 32, color: context.accent),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 14,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  /// Card 1: Enter Email
  Widget _buildEnterEmailCard(BuildContext context) {
    return _SlateCard(
      key: const ValueKey('enterEmail'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: 'Welcome to ChatBud',
            subtitle: 'Enter your email to sign in or create an account',
          ),
          const SizedBox(height: 28),
          _AuthField(
            controller: _emailCtrl,
            hint: 'email@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            onSubmitted: _handleEmailSubmitted,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(_error!),
          ],
          const SizedBox(height: 20),
          _PrimaryButton(
            text: 'Continue',
            loading: _loading,
            onPressed: _handleEmailSubmitted,
          ),
          const SizedBox(height: 16),
          Text(
            'By continuing you agree to our Terms & Privacy Policy',
            textAlign: TextAlign.center,
            style: TextStyle(color: context.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  /// Card 2A: Existing User -> Enter Password
  Widget _buildExistingUserPasswordCard(BuildContext context) {
    return _SlateCard(
      key: const ValueKey('existingUserPassword'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: 'Welcome Back',
            subtitle: _emailCtrl.text.trim(),
          ),
          const SizedBox(height: 28),
          _AuthField(
            controller: _passwordCtrl,
            hint: 'Password',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: _handleSignIn,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _loading ? null : _handleForgotPassword,
              child: Text(
                'Forgot password?',
                style: TextStyle(
                  color: context.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            _ErrorMessage(_error!),
          ],
          const SizedBox(height: 16),
          _PrimaryButton(
            text: 'Sign In',
            loading: _loading,
            onPressed: _handleSignIn,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            text: 'Use a different email',
            onPressed: _goBackToEmail,
          ),
        ],
      ),
    );
  }

  /// Card 2B/2C: Verify OTP
  Widget _buildVerifyOtpCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required VoidCallback onVerify,
  }) {
    return _SlateCard(
      key: ValueKey(title),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(title: title, subtitle: subtitle),
          const SizedBox(height: 20),
          if (_sentOtp != null) _OtpBanner(otp: _sentOtp!),
          const SizedBox(height: 20),
          _OtpBoxRow(
            controller: _otpCtrl,
            onComplete: onVerify,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(_error!),
          ],
          const SizedBox(height: 24),
          _PrimaryButton(
            text: 'Verify & Continue',
            loading: _loading,
            onPressed: onVerify,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _goBackToEmail,
                child: Text(
                  'Change Email',
                  style: TextStyle(color: context.textMuted, fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: _loading
                    ? null
                    : () => _sendOtpAndGoTo(_step, _emailCtrl.text.trim()),
                child: Text(
                  'Resend Code',
                  style: TextStyle(
                    color: context.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Card 3B: New User -> Create Account (Name + Password)
  Widget _buildCreateAccountCard(BuildContext context) {
    return _SlateCard(
      key: const ValueKey('createAccount'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: 'Create Your Account',
            subtitle: 'Set up your profile details for ${_emailCtrl.text.trim()}',
          ),
          const SizedBox(height: 24),
          _AuthField(
            controller: _nameCtrl,
            hint: 'Your Full Name',
            prefixIcon: Icons.person_outline,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: _passwordCtrl,
            hint: 'Create Password (6+ chars)',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: _handleCreateAccount,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(_error!),
          ],
          const SizedBox(height: 20),
          _PrimaryButton(
            text: 'Create Account',
            loading: _loading,
            onPressed: _handleCreateAccount,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            text: 'Cancel',
            onPressed: _goBackToEmail,
          ),
        ],
      ),
    );
  }

  /// Card 3C: Set New Password
  Widget _buildSetNewPasswordCard(BuildContext context) {
    return _SlateCard(
      key: const ValueKey('setNewPassword'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(
            title: 'Set New Password',
            subtitle: 'Enter your new password below',
          ),
          const SizedBox(height: 24),
          _AuthField(
            controller: _newPasswordCtrl,
            hint: 'New Password (6+ chars)',
            prefixIcon: Icons.lock_outline,
            isPassword: true,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: _confirmPasswordCtrl,
            hint: 'Confirm New Password',
            prefixIcon: Icons.lock_clock_outlined,
            isPassword: true,
            textInputAction: TextInputAction.done,
            onSubmitted: _handleSetNewPassword,
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            _ErrorMessage(_error!),
          ],
          const SizedBox(height: 20),
          _PrimaryButton(
            text: 'Save Password & Sign In',
            loading: _loading,
            onPressed: _handleSetNewPassword,
          ),
          const SizedBox(height: 12),
          _SecondaryButton(
            text: 'Cancel',
            onPressed: _goBackToEmail,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Custom UI Components (Slate / Modern Dark Theme)
// ─────────────────────────────────────────────────────────────────────────────

/// Container card styled with Slate Dark theme borders/bg.
class _SlateCard extends StatelessWidget {
  final Widget child;

  const _SlateCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.borderSubtle, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Error banner widget.
class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.statusDanger.withValues(alpha: 0.1),
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

/// Reusable Slate-styled text field for auth steps.
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
        fontSize: 16,
        fontWeight: FontWeight.w400,
      ),
      onSubmitted: widget.onSubmitted != null ? (_) => widget.onSubmitted!() : null,
      decoration: InputDecoration(
        hintText: widget.hint,
        counterText: '',
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
      ),
    );
  }
}

/// Primary action button (Brand Accent).
class _PrimaryButton extends StatelessWidget {
  final String text;
  final bool loading;
  final VoidCallback onPressed;

  const _PrimaryButton({
    required this.text,
    required this.loading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: context.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: loading ? null : onPressed,
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
      ),
    );
  }
}

/// Secondary Outline / Text style button.
class _SecondaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SecondaryButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: context.textMuted,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// Banner showing mock OTP during development/testing.
class _OtpBanner extends StatelessWidget {
  final String otp;

  const _OtpBanner({required this.otp});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: context.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(Icons.mark_email_read_outlined,
              color: context.accent, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Demo Code Generated',
                  style: TextStyle(
                    color: context.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your 6-digit code is: $otp',
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 6-digit OTP input row using separate FocusNodes and controllers.
class _OtpBoxRow extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onComplete;

  const _OtpBoxRow({required this.controller, required this.onComplete});

  @override
  State<_OtpBoxRow> createState() => _OtpBoxRowState();
}

class _OtpBoxRowState extends State<_OtpBoxRow> {
  static const int _length = 6;
  final List<TextEditingController> _ctrls =
      List.generate(_length, (_) => TextEditingController());
  final List<FocusNode> _nodes =
      List.generate(_length, (_) => FocusNode());

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _length - 1) {
        _nodes[index + 1].requestFocus();
      } else {
        _nodes[index].unfocus();
      }
    } else if (index > 0) {
      _nodes[index - 1].requestFocus();
    }
    // Sync combined value back to parent controller
    widget.controller.text = _ctrls.map((c) => c.text).join();
    if (widget.controller.text.length == _length) {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(_length, (i) {
        return SizedBox(
          width: 44,
          height: 52,
          child: TextField(
            controller: _ctrls[i],
            focusNode: _nodes[i],
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 1,
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: '',
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.borderSubtle, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: context.accent, width: 2),
              ),
            ),
            onChanged: (val) => _onChanged(val, i),
          ),
        );
      }),
    );
  }
}
