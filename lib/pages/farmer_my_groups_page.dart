import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_details_page.dart';

class FarmerMyGroupsPage extends StatelessWidget {
  const FarmerMyGroupsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final groupsStream = FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: uid)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Groups 👨‍🌾"),
        backgroundColor: Colors.green.shade700,
      ),
      backgroundColor: Colors.green.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: groupsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final groups = snapshot.data!.docs;

          if (groups.isEmpty) {
            return const Center(
              child: Text(
                "You’re not part of any group yet 🌱",
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, i) {
              final group = groups[i].data() as Map<String, dynamic>;
              final groupId = groups[i].id;
              final groupName = group['groupName'] ?? 'Unnamed Group';
              final cropName = group['cropName'] ?? 'Unknown Crop';
              final minPrice = group['minPriceExpected']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  title: Text(
                    groupName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: Text(
                    "Crop: $cropName  |  Min ₹$minPrice",
                    style: const TextStyle(fontSize: 14),
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailsPage(groupId: groupId),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
