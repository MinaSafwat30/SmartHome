import 'package:flutter/material.dart';
import 'package:smarthome/features/Auth/auth_repository.dart';
import 'package:smarthome/features/Auth/widgets/auth_widgets.dart';

const _kPurple = Color(0xFF7B6EF5);
const _kTextDark = Color(0xFF1E2340);
const _kTextMid = Color(0xFF8A91B4);

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _repo = AuthRepository();

  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _repo.sendPasswordReset(_emailCtrl.text.trim());
      if (mounted) setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Could not send reset email. Check the address and try again.';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const AuthBackButton(),
              const SizedBox(height: 32),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _kPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: _kPurple, size: 40),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Forgot Password? 🔐',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your email and we'll send you a link to reset your password.",
                style: TextStyle(fontSize: 14, color: _kTextMid, height: 1.5),
              ),
              const SizedBox(height: 32),

              if (_emailSent) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEFFF5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.mark_email_read_rounded,
                          color: Color(0xFF2ECC71), size: 40),
                      SizedBox(height: 12),
                      Text(
                        'Reset email sent!',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E2340)),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Check your inbox and follow the link to reset your password.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: _kTextMid),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Back to Sign In',
                  onPressed: () => Navigator.maybePop(context),
                ),
              ] else ...[
                if (_errorMessage != null) ...[
                  AuthErrorBanner(_errorMessage!),
                  const SizedBox(height: 16),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const AuthFieldLabel('Email Address'),
                      AuthTextField(
                        hint: 'you@email.com',
                        icon: Icons.email_outlined,
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your email';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      AuthPrimaryButton(
                        label: 'Send Reset Link',
                        isLoading: _isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
