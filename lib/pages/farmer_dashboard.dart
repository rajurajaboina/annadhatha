// lib/pages/farmer_dashboard.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'farmer_add_crop_page.dart';
import 'farmer_my_crops_page.dart';
import 'farmer_group_page.dart';
import 'requests_page.dart';
import 'package:farmer_retailer_app/widgets/requests_badge.dart';
import 'requests_page.dart'; // Your RequestsPage file

class FarmerDashboardScreen extends StatefulWidget {
  const FarmerDashboardScreen({Key? key}) : super(key: key);

  @override
  State<FarmerDashboardScreen> createState() => _FarmerDashboardScreenState();
}

class _FarmerDashboardScreenState extends State<FarmerDashboardScreen> {
  int _selectedIndex = 0;
  final _auth = FirebaseAuth.instance;

  final List<Widget> _pages = const [
    FarmerAddCropPage(),
    FarmerMyCropsPage(),
    FarmerGroupPage(),
    RequestsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green.shade700,
        title: const Text("Farmer Dashboard 🌾"),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.account_circle, size: 30),
            onSelected: (value) {
              if (value == 'profile') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile Page Coming Soon ⭐")),
                );
              } else if (value == 'logout') {
                FirebaseAuth.instance.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 10),
                    Text("My Profile"),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 10),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),

      body: _pages[_selectedIndex],

      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: uid == null
            ? const Stream.empty()
            : FirebaseFirestore.instance
                  .collectionGroup('requests')
                  .where('toUid', isEqualTo: uid)
                  .where('status', isEqualTo: 'pending')
                  .snapshots(),
        builder: (context, snapshot) {
          int pendingCount = snapshot.data?.docs.length ?? 0;

          return BottomNavigationBar(
            currentIndex: _selectedIndex,
            backgroundColor: Colors.green.shade100,
            selectedItemColor: Colors.green.shade700,
            unselectedItemColor: Colors.grey.shade600,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            onTap: (index) => setState(() => _selectedIndex = index),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.add_box_outlined),
                label: "Add Crop",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: "My Crops",
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.group),
                label: "Groups",
              ),
              BottomNavigationBarItem(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.mail_outline),
                    if (pendingCount > 0)
                      Positioned(
                        right: -6,
                        top: -3,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            pendingCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                label: "Requests",
              ),
            ],
          );
        },
      ),
    );
  }
}
