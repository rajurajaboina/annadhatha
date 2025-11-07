import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RetailerDashboardScreen> createState() =>
      _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen> {
  final _auth = FirebaseAuth.instance;

  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  final Stream<QuerySnapshot> _cropsStream = FirebaseFirestore.instance
      .collection('crops')
      .orderBy('timestamp', descending: true)
      .snapshots();

  void _openMap(double lat, double lng) async {
    final url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Retailer Dashboard 🛒"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: "Logout",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _cropsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("⚠️ Error loading crops"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No crops available yet 🌾",
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
              final crop = crops[index].data() as Map<String, dynamic>? ?? {};

              return Card(
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
                        child: crop['imageUrl'] != null
                            ? Image.network(
                                crop['imageUrl'],
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                height: 180,
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
                            crop['cropName'] ?? 'Unknown Crop',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          Text(
                            "${crop['quantity'] ?? '0'} kg",
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.brown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Colors.green),

                      _buildInfoRow(
                        Icons.person,
                        crop['farmerName'] ?? 'Unknown Farmer',
                      ),
                      _buildInfoRow(
                        Icons.phone,
                        crop['farmerContact'] ?? 'No Contact',
                      ),
                      _buildInfoRow(
                        Icons.location_on,
                        crop['farmerAddress'] ?? 'No Address',
                      ),

                      const SizedBox(height: 10),

                      if (crop['loc'] != null)
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              final gp = crop['loc'];
                              _openMap(gp.latitude, gp.longitude);
                            },
                            icon: const Icon(Icons.map),
                            label: const Text("View Location"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),

                      const SizedBox(height: 5),

                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final phone =
                                crop['farmerContact'] ?? 'Unavailable';
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("📞 Contact Farmer"),
                                content: Text("Farmer’s phone number: $phone"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Close"),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.phone),
                          label: const Text("Contact Farmer"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
