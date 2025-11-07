import 'package:flutter/material.dart';
import '../widgets/role_button.dart';
import 'auth_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F0),
      appBar: AppBar(
        title: const Text('Select Your Role'),
        backgroundColor: const Color(0xFF3E7C17),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RoleButton(
              icon: Icons.agriculture,
              label: 'Farmer',
              color: Colors.green.shade600,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthPage(role: 'farmer'),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            RoleButton(
              icon: Icons.store,
              label: 'Retailer',
              color: Colors.brown.shade500,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AuthPage(role: 'retailer'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
