import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:farmer_retailer_app/pages/add_crop_to_group_page.dart';
import 'package:farmer_retailer_app/pages/group_details_page.dart';

class FarmerMyCropsPage extends StatefulWidget {
  const FarmerMyCropsPage({Key? key}) : super(key: key);

  @override
  State<FarmerMyCropsPage> createState() => _FarmerMyCropsPageState();
}

class _FarmerMyCropsPageState extends State<FarmerMyCropsPage> {
  final _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text("User not logged in 😕"));
    }

    final Stream<QuerySnapshot> myCropsStream = FirebaseFirestore.instance
        .collection('crops')
        .where('farmerId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("My Crops 🌾"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: myCropsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "⚠️ Error loading crops: ${snapshot.error}",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "You haven’t added any crops yet 🌱",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final crops = snapshot.data!.docs;

          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final doc = crops[index];
              final crop = doc.data() as Map<String, dynamic>? ?? {};

              final cropName = crop['cropName'] ?? 'Unknown Crop';
              final quantity = (crop['quantity'] ?? '0').toString();
              final imageUrl = crop['imageUrl'] as String?;
              final loc = crop['loc'] as GeoPoint?;
              final cropId = doc.id;
              final isGrouped = crop['grouped'] == true;
              final groupId = crop['groupId'];

              return Opacity(
                opacity: isGrouped ? 0.6 : 1,
                child: Card(
                  elevation: 5,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  height: 160,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 160,
                                  color: Colors.green.shade100,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    size: 60,
                                    color: Colors.green,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              cropName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            Text(
                              "$quantity kg",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.brown,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20, color: Colors.green),
                        if (loc != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Location: ${loc.latitude.toStringAsFixed(5)}, ${loc.longitude.toStringAsFixed(5)}",
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: isGrouped
                                  ? null
                                  : () {
                                      final cropQty =
                                          double.tryParse(quantity) ?? 0.0;
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddCropToGroupPage(
                                            cropId: cropId,
                                            cropName: cropName,
                                            cropLoc: loc,
                                            cropQuantity: cropQty,
                                          ),
                                        ),
                                      );
                                    },
                              icon: const Icon(Icons.group_add),
                              label: Text(
                                isGrouped ? "Already in Group" : "Add to Group",
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade700,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "✏️ Edit feature coming soon",
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Delete Crop"),
                                    content: const Text(
                                      "Are you sure you want to delete this crop?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        child: const Text("Delete"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  await FirebaseFirestore.instance
                                      .collection('crops')
                                      .doc(cropId)
                                      .delete();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Crop deleted ✅"),
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        if (isGrouped && groupId != null) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  "Linked to group: $groupId",
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      GroupDetailsPage(groupId: groupId),
                                ),
                              );
                            },
                            icon: const Icon(Icons.info_outline),
                            label: const Text("View Group Details"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade700,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
