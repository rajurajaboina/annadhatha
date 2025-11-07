import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'auth_page.dart';
import 'farmer_dashboard.dart';
import 'retailer_dashboard.dart';
import 'role_selection_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateUser();
  }

  Future<void> _navigateUser() async {
    await Future.delayed(const Duration(seconds: 3)); // splash delay

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Fetch user role from Firestore
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final role = userDoc['role'];

          if (role == 'farmer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const FarmerDashboardScreen(),
              ),
            );
          } else if (role == 'retailer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RetailerDashboardScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const RoleSelectionPage(),
              ),
            );
          }
        } else {
          // User record not found → redirect to role selection
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
          );
        }
      } else {
        // No user logged in → go to role selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
        );
      }
    } catch (e) {
      // On any error, go to role selection page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade100,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo Image
            Image.asset('assets/logo.png', height: 120, width: 120),
            const SizedBox(height: 20),
            // App Name
            const Text(
              "Annadhatha 🌾",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
