import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/features/Auth/auth_repository.dart';
import 'package:smarthome/features/Auth/sign_up_cubit/sign_up_cubit.dart';
import 'package:smarthome/features/Auth/widgets/auth_widgets.dart';
import 'package:smarthome/features/smart_home/data/presentation/views/dashboard_view.dart';

const _kPurple = Color(0xFF7B6EF5);
const _kTextDark = Color(0xFF1E2340);
const _kTextMid = Color(0xFF8A91B4);

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (_formKey.currentState!.validate()) {
      ctx.read<SignUpCubit>().signUpUser(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SignUpCubit(AuthRepository()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<SignUpCubit, SignUpState>(
          listener: (context, state) {
            if (state is SignUpSuccess) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const DashboardView()),
                (_) => false,
              );
            }
          },
          builder: (context, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      const AuthBackButton(),
                      const SizedBox(height: 24),

                      const Text(
                        'Create Account ✨',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set up your smart home profile',
                        style: TextStyle(fontSize: 14, color: _kTextMid),
                      ),
                      const SizedBox(height: 24),

                      if (state is SignUpFailure) ...[
                        AuthErrorBanner(state.errorMessage),
                        const SizedBox(height: 16),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AuthFieldLabel('First Name'),
                                AuthTextField(
                                  hint: 'First Name',
                                  icon: Icons.person_outline_rounded,
                                  controller: _firstNameCtrl,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AuthFieldLabel('Last Name'),
                                AuthTextField(
                                  hint: 'Last Name',
                                  icon: Icons.person_outline_rounded,
                                  controller: _lastNameCtrl,
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const AuthFieldLabel('Email'),
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

                      const AuthFieldLabel('Password'),
                      AuthTextField(
                        hint: 'Min. 6 characters',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter a password';
                          if (v.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),

                      const AuthFieldLabel('Confirm Password'),
                      AuthTextField(
                        hint: 'Re-enter password',
                        icon: Icons.lock_outline_rounded,
                        controller: _confirmPassCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Confirm your password';
                          }
                          if (v != _passwordCtrl.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      AuthPrimaryButton(
                        label: 'Create Account',
                        isLoading: state is SignUpLoading,
                        onPressed: () => _submit(context),
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Already have an account? ',
                              style: TextStyle(fontSize: 14, color: _kTextMid),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.maybePop(context),
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _kPurple,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
