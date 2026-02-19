import 'package:flutter/material.dart';
import 'utils/auth_helper.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const StudentAttendanceApp());
}

class StudentAttendanceApp extends StatelessWidget {
  const StudentAttendanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Attendance Tracker App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _AuthGate(),
    );
  }
}

/// Decides which screen to show on launch based on auth state.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AuthStatus>(
      future: _resolveAuth(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        switch (snap.data!) {
          case _AuthStatus.noAdmin:
            return const RegisterPage();
          case _AuthStatus.loggedOut:
            return const LoginPage();
          case _AuthStatus.loggedIn:
            return const HomePage();
        }
      },
    );
  }

  Future<_AuthStatus> _resolveAuth() async {
    if (!await AuthHelper.hasAdmin()) return _AuthStatus.noAdmin;
    if (!await AuthHelper.isLoggedIn()) return _AuthStatus.loggedOut;
    return _AuthStatus.loggedIn;
  }
}

enum _AuthStatus { noAdmin, loggedOut, loggedIn }
