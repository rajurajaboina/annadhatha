// lib/pages/groups_all_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'group_details_page.dart';

class GroupsAllPage extends StatelessWidget {
  const GroupsAllPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final groupsStream = FirebaseFirestore.instance
        .collection('groups')
        .where('isOpenGroup', isEqualTo: true) // show open groups only
        .orderBy('createdOn', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Groups'),
        backgroundColor: Colors.green.shade700,
      ),
      backgroundColor: Colors.green.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: groupsStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No groups available yet.',
                style: TextStyle(color: Colors.grey),
              ),
            );
          }

          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final g = docs[i].data() as Map<String, dynamic>;
              final gid = docs[i].id;
              final members = (g['members'] as List?)?.length ?? 0;
              final target = g['groupTargetQty']?.toString() ?? '-';
              final minPrice = g['minPriceExpected']?.toString() ?? '-';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  title: Text(
                    g['groupName'] ?? 'Unnamed group',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Members: $members'),
                        const SizedBox(height: 6),
                        Text('Target: $target kg • Min ₹$minPrice'),
                        if (g['locationEnabled'] == true &&
                            g['creatorLocation'] != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 6.0),
                            child: Text(
                              'Location enabled',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GroupDetailsPage(groupId: gid),
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
