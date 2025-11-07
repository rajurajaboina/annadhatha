import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SelectCropForGroupPage extends StatefulWidget {
  const SelectCropForGroupPage({Key? key}) : super(key: key);

  @override
  State<SelectCropForGroupPage> createState() => _SelectCropForGroupPageState();
}

class _SelectCropForGroupPageState extends State<SelectCropForGroupPage> {
  final _auth = FirebaseAuth.instance;
  String? _selectedCropId;
  Map<String, dynamic>? _selectedCrop;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser!;
    final myCropsStream = FirebaseFirestore.instance
        .collection('crops')
        .where('farmerId', isEqualTo: user.uid)
        .snapshots();

    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Select Crop for Group"),
        backgroundColor: Colors.green.shade700,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: myCropsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No crops found"));
          }

          final docs = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final cropDoc = docs[index];
              final crop = cropDoc.data() as Map<String, dynamic>;
              final cropId = cropDoc.id;
              final isGrouped = crop['grouped'] == true;

              return Opacity(
                opacity: isGrouped ? 0.5 : 1,
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: crop['imageUrl'] != null
                        ? Image.network(
                            crop['imageUrl'],
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          )
                        : const Icon(Icons.image_not_supported),
                    title: Text(crop['cropName'] ?? 'Unknown Crop'),
                    subtitle: Text("Qty: ${crop['quantity']} kg"),
                    trailing: isGrouped
                        ? const Icon(Icons.lock, color: Colors.red)
                        : Radio<String>(
                            value: cropId,
                            groupValue: _selectedCropId,
                            onChanged: (val) {
                              setState(() {
                                _selectedCropId = val;
                                _selectedCrop = {
                                  'cropId': cropId,
                                  'cropName': crop['cropName'],
                                  'quantity': crop['quantity'],
                                  'imageUrl': crop['imageUrl'],
                                  'loc': crop['loc'],
                                };
                              });
                            },
                          ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: _selectedCrop != null
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.pop(context, _selectedCrop);
              },
              icon: const Icon(Icons.done),
              label: const Text("Use This Crop"),
              backgroundColor: Colors.green.shade700,
            )
          : null,
    );
  }
}
