import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:firebase_project/home_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SignInScreen(
            providers: [
              EmailAuthProvider(),
              GoogleProvider(clientId: "585508054843-tp4cnehetm0jhu7mvct6bddqsuu5h1u0.apps.googleusercontent.com")
            ],
            showPasswordVisibilityToggle: true,
          );
        }
        return const HomeScreen();
      },
    );
  }
}
