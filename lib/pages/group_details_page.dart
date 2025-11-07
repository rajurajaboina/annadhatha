import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class GroupDetailsPage extends StatelessWidget {
  final String groupId;
  const GroupDetailsPage({Key? key, required this.groupId}) : super(key: key);

  Future<double> _calculateCurrentQuantity() async {
    final membersSnap = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('members')
        .get();

    double total = 0;
    for (var doc in membersSnap.docs) {
      final data = doc.data();
      total += (data['contributionQty'] ?? 0).toDouble();
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId);

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Group Details"),
        backgroundColor: Colors.green.shade700,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: groupRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Group not found"));
          }

          final group = snapshot.data!.data() as Map<String, dynamic>;
          final groupName = group['groupName'] ?? 'Unnamed';
          final cropName = group['cropName'] ?? '';
          final minPrice = (group['minPriceExpected'] ?? 0).toString();
          final createdOn = (group['createdOn'] as Timestamp?)?.toDate();
          final adminId = group['creatorUid'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  groupName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 8),
                Text("Crop: $cropName"),
                FutureBuilder<double>(
                  future: _calculateCurrentQuantity(),
                  builder: (context, qtySnap) {
                    if (!qtySnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: LinearProgressIndicator(),
                      );
                    }
                    return Text(
                      "Current Quantity: ${qtySnap.data!.toStringAsFixed(2)} kg",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.brown,
                      ),
                    );
                  },
                ),
                Text("Min Price: ₹$minPrice/kg"),
                if (createdOn != null)
                  Text("Created On: ${createdOn.toLocal()}"),
                const Divider(height: 30),

                // 🧑‍🌾 Admin Info
                FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(adminId)
                      .get(),
                  builder: (context, adminSnap) {
                    if (!adminSnap.hasData) {
                      return const SizedBox();
                    }
                    final adminData =
                        adminSnap.data!.data() as Map<String, dynamic>? ?? {};
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Admin Details",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text("Name: ${adminData['name'] ?? 'Unknown'}"),
                        Text("Phone: ${adminData['phone'] ?? 'N/A'}"),
                        Text("Address: ${adminData['address'] ?? 'N/A'}"),
                      ],
                    );
                  },
                ),
                const Divider(height: 30),

                const Text(
                  "Members",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                StreamBuilder<QuerySnapshot>(
                  stream: groupRef.collection('members').snapshots(),
                  builder: (context, membersSnap) {
                    if (!membersSnap.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final members = membersSnap.data!.docs;
                    if (members.isEmpty) {
                      return const Text("No members yet.");
                    }

                    return Column(
                      children: members.map((m) {
                        final data = m.data() as Map<String, dynamic>? ?? {};
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            leading: const Icon(
                              Icons.person,
                              color: Colors.green,
                            ),
                            title: Text(data['name'] ?? 'Farmer'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Qty: ${data['contributionQty']} kg"),
                                if (data['phone'] != null)
                                  Text("📞 ${data['phone']}"),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
