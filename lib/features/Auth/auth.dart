library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smarthome/features/Auth/Views/log_in_view.dart';
import 'package:smarthome/features/smart_home/data/presentation/views/dashboard_view.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F6FB),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF7B6EF5)),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return const DashboardView();
        }

        return const LogInView();
      },
    );
  }
}
