import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }

        if (!authSnapshot.hasData || authSnapshot.data == null) {
          return const LoginScreen();
        }

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(authSnapshot.data!.uid)
              .get(),
          builder: (context, userSnapshot) {

            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.background,
                body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              );
            }

            if (userSnapshot.hasData && userSnapshot.data!.exists) {
              final data = userSnapshot.data!.data() as Map<String, dynamic>;
              String roleString = data['role'] ?? 'student';
              UserRole role = roleString == 'teacher' ? UserRole.teacher : UserRole.student;
              String userName = data.containsKey('name') ? data['name'] : 'مستخدم';
              return MainScreen(role: role, userName: userName);
            }

            // ✅ REPLACE THE OLD CASE 5 WITH THIS
            return FutureBuilder(
              future: Future.delayed(
                const Duration(seconds: 2),
                () => FirebaseFirestore.instance
                    .collection('users')
                    .doc(authSnapshot.data!.uid)
                    .get(),
              ),
              builder: (context, retrySnapshot) {
                if (retrySnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    backgroundColor: AppColors.background,
                    body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                }

                if (retrySnapshot.hasData && retrySnapshot.data!.exists) {
                  final data = retrySnapshot.data!.data() as Map<String, dynamic>;
                  String roleString = data['role'] ?? 'student';
                  UserRole role = roleString == 'teacher' ? UserRole.teacher : UserRole.student;
                  String userName = data.containsKey('name') ? data['name'] : 'مستخدم';
                  return MainScreen(role: role, userName: userName);
                }

                // Only sign out if STILL not found after retry
                FirebaseAuth.instance.signOut();
                return const LoginScreen();
              },
            );
          },
        );
      },
    );
  }
}