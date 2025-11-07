import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'select_crop_for_group_page.dart';

class FarmerCreateGroupPage extends StatefulWidget {
  const FarmerCreateGroupPage({Key? key}) : super(key: key);

  @override
  State<FarmerCreateGroupPage> createState() => _FarmerCreateGroupPageState();
}

class _FarmerCreateGroupPageState extends State<FarmerCreateGroupPage> {
  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  Map<String, dynamic>? _selectedCrop;
  bool _isCreating = false;

  Future<void> _selectCrop() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(builder: (_) => const SelectCropForGroupPage()),
    );

    if (result != null) {
      setState(() {
        _selectedCrop = result;
      });
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a group name")),
      );
      return;
    }

    if (_selectedCrop == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please select a crop 🌾")));
      return;
    }

    if (_priceController.text.trim().isEmpty ||
        double.tryParse(_priceController.text.trim()) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid minimum price ₹")),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final cropId = _selectedCrop!['cropId'];
      final cropData = _selectedCrop!;
      final loc = cropData['loc'] as GeoPoint?;

      await FirebaseFirestore.instance.collection('groups').add({
        'groupName': _groupNameController.text.trim(),
        'creatorUid': uid,
        'adminId': uid,
        'isOpenGroup': true,
        'status': 'open',
        'cropId': cropId,
        'cropName': cropData['cropName'],
        'minPriceExpected': double.parse(_priceController.text.trim()),
        'members': [uid],
        'createdOn': FieldValue.serverTimestamp(),
        'creatorLocation': loc,
      });

      // ✅ Mark crop as grouped
      await FirebaseFirestore.instance.collection('crops').doc(cropId).update({
        'grouped': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Group created successfully!")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error creating group: $e")));
    } finally {
      setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: const Text("Create Group 🌾"),
        backgroundColor: Colors.green.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: "Group Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: _selectCrop,
              icon: const Icon(Icons.add),
              label: const Text("Select Crop"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),

            if (_selectedCrop != null)
              Card(
                color: Colors.green.shade100,
                margin: const EdgeInsets.only(top: 10),
                child: ListTile(
                  leading: _selectedCrop!['imageUrl'] != null
                      ? Image.network(
                          _selectedCrop!['imageUrl'],
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.image_not_supported),
                  title: Text(_selectedCrop!['cropName'] ?? 'Unknown Crop'),
                  subtitle: Text("Qty: ${_selectedCrop!['quantity']} kg"),
                ),
              ),

            const SizedBox(height: 20),

            TextField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: "Enter Minimum Price (₹ per kg)",
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),

            const Spacer(),

            _isCreating
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _createGroup,
                    icon: const Icon(Icons.check),
                    label: const Text("Create Group"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
