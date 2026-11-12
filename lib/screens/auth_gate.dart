import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'habit_home_page.dart';
import 'auth_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, required this.authService});

  final AuthService authService;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      initialData: authService.currentUser,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(
              child: Text('Unable to check your sign-in status. Restart the app.'),
            ),
          );
        }

        if (snapshot.data == null) {
          return AuthScreen(authService: authService);
        }

        return HabitHomePage(
          authService: authService,
          user: snapshot.data!,
        );
      },
    );
  }
}
