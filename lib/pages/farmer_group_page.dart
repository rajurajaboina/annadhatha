import 'package:flutter/material.dart';
import 'farmer_create_group_page.dart';
import 'farmer_my_groups_page.dart';
import 'groups_all_page.dart';

class FarmerGroupPage extends StatelessWidget {
  const FarmerGroupPage({Key? key}) : super(key: key);

  Widget _optionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          height: 100,
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Icon(icon, size: 42, color: Colors.green.shade700),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Groups 👨‍🌾"),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _optionCard(
              icon: Icons.group_add,
              title: "Create New Group",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FarmerCreateGroupPage(),
                  ),
                );
              },
            ),
            _optionCard(
              icon: Icons.groups,
              title: "My Groups",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FarmerMyGroupsPage()),
                );
              },
            ),
            _optionCard(
              icon: Icons.people_alt,
              title: "All Groups",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GroupsAllPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
