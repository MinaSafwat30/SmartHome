import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smarthome/features/Auth/auth_repository.dart';
import 'package:smarthome/features/Auth/log_in_cubit/log_in_cubit.dart';
import 'package:smarthome/features/Auth/sign_up_cubit/sign_up_cubit.dart';
import 'package:smarthome/features/Auth/Views/sign_up_view.dart';
import 'package:smarthome/features/Auth/Views/forgot_password_view.dart';
import 'package:smarthome/features/Auth/widgets/auth_widgets.dart';

const _kPurple = Color(0xFF7B6EF5);
const _kTextDark = Color(0xFF1E2340);
const _kTextMid = Color(0xFF8A91B4);

class LogInView extends StatefulWidget {
  const LogInView({super.key});

  @override
  State<LogInView> createState() => _LogInViewState();
}

class _LogInViewState extends State<LogInView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit(BuildContext ctx) {
    if (_formKey.currentState!.validate()) {
      ctx.read<LogInCubit>().loginUser(
            _emailCtrl.text.trim(),
            _passwordCtrl.text,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LogInCubit(AuthRepository()),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: BlocConsumer<LogInCubit, LogInState>(
          listener: (context, state) {
            if (state is LogInSuccess) {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
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
                      const SizedBox(height: 24),

                      Center(child: _AuthLogo()),
                      const SizedBox(height: 32),

                      const Text(
                        'Welcome back 👋',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: _kTextDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Sign in to control your smart home',
                        style: TextStyle(fontSize: 14, color: _kTextMid),
                      ),
                      const SizedBox(height: 28),

                      if (state is LogInFailure) ...[
                        AuthErrorBanner(state.errorMessage),
                        const SizedBox(height: 16),
                      ],

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
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        controller: _passwordCtrl,
                        isPassword: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter your password';
                          return null;
                        },
                      ),

                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Transform.scale(
                            scale: 0.85,
                            child: Switch.adaptive(
                              value: _rememberMe,
                              activeThumbColor: Colors.white,
                              activeTrackColor: _kPurple,
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: const Color(0xFFDEDFF0),
                              onChanged: (v) => setState(() => _rememberMe = v),
                            ),
                          ),
                          const Text('Remember me',
                              style:
                                  TextStyle(fontSize: 13, color: _kTextMid)),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordView()),
                            ),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: _kPurple,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      AuthPrimaryButton(
                        label: 'Sign In',
                        isLoading: state is LogInLoading,
                        onPressed: () => _submit(context),
                      ),
                      const SizedBox(height: 28),

                      Row(
                        children: const [
                          Expanded(child: Divider(color: Color(0xFFE0E2F0))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text('or',
                                style:
                                    TextStyle(color: _kTextMid, fontSize: 13)),
                          ),
                          Expanded(child: Divider(color: Color(0xFFE0E2F0))),
                        ],
                      ),
                      const SizedBox(height: 24),

                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("Don't have an account? ",
                                style: TextStyle(
                                    fontSize: 14, color: _kTextMid)),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => BlocProvider(
                                    create: (_) =>
                                        SignUpCubit(AuthRepository()),
                                    child: const SignUpView(),
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
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


class _AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8B80F9), Color(0xFF9B5DFA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: _kPurple.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Icon(Icons.home_rounded, color: Colors.white, size: 44),
    );
  }
}
