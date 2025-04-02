// ignore_for_file: unused_element

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:Escolarize/models/user_model.dart';
import 'package:Escolarize/screens/login_pages/login_screen.dart';
import 'package:Escolarize/screens/student/student_dashboard.dart';
import 'package:Escolarize/screens/teacher/teacher_dashboard.dart';
import 'package:Escolarize/screens/admin/admin_dashboard.dart';
import 'package:Escolarize/services/auth_provider.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future:
            Provider.of<AuthProvider>(context, listen: false).initializeAuth(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingScreen();
          }

          return Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isLoading) {
                return _buildLoadingScreen();
              }

              if (auth.user == null) {
                return const LoginScreen();
              }

              return _buildDashboard(auth.user!);
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 120, height: 120),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Carregando...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard(UserModel user) {
    switch (user.role) {
      case UserRole.student:
        return StudentDashboard(user: user);
      case UserRole.teacher:
        return TeacherDashboard(user: user);
      case UserRole.admin:
        return AdminDashboard(user: user);
    }
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Erro'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }
}
