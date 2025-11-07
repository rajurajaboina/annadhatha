import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/services.dart' show rootBundle;

class FarmerAddCropPage extends StatefulWidget {
  const FarmerAddCropPage({Key? key}) : super(key: key);

  @override
  State<FarmerAddCropPage> createState() => _FarmerAddCropPageState();
}

class _FarmerAddCropPageState extends State<FarmerAddCropPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _manualLatController = TextEditingController();
  final TextEditingController _manualLngController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  File? _imageFile;
  bool _isUploading = false;
  double? _lat;
  double? _lng;

  Map<String, dynamic>? _farmerData;
  List<Map<String, dynamic>> _allCrops = [];
  List<Map<String, dynamic>> _filteredCrops = [];
  String? _selectedCropName;
  String? _selectedCropType;

  @override
  void initState() {
    super.initState();
    _fetchFarmerData();
    _loadAllowedCrops();
  }

  Future<void> _fetchFarmerData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        setState(() {
          _farmerData = doc.data();
        });
      }
    }
  }

  Future<void> _loadAllowedCrops() async {
    final String response = await rootBundle.loadString(
      'assets/crops_list.json',
    );
    final data = json.decode(response) as List;
    setState(() {
      _allCrops = data.map((e) => Map<String, dynamic>.from(e)).toList();
      _filteredCrops = _allCrops;
    });
  }

  void _filterCrops(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredCrops = _allCrops;
      } else {
        _filteredCrops = _allCrops
            .where(
              (crop) => crop['cropName'].toString().toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<void> _detectLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location permission denied")),
      );
      return;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _manualLatController.text = _lat!.toString();
      _manualLngController.text = _lng!.toString();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("📍 Location detected: $_lat , $_lng")),
    );
  }

  Future<void> _uploadCrop() async {
    if (_selectedCropName == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a crop 🌾')));
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select an image')));
      return;
    }

    setState(() => _isUploading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseStorage.instance.ref().child(
        'crop_images/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await ref.putFile(_imageFile!);
      final imageUrl = await ref.getDownloadURL();

      double latToSave =
          _lat ?? double.tryParse(_manualLatController.text.trim()) ?? 0.0;
      double lngToSave =
          _lng ?? double.tryParse(_manualLngController.text.trim()) ?? 0.0;

      await FirebaseFirestore.instance.collection('crops').add({
        'farmerId': user.uid,
        'farmerName': _farmerData?['name'] ?? '',
        'farmerAddress': _farmerData?['address'] ?? '',
        'farmerContact': _farmerData?['phone'] ?? '',
        'cropName': _selectedCropName ?? '',
        'cropType': _selectedCropType ?? '',
        'quantity': _quantityController.text.trim(),
        'imageUrl': imageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'loc': GeoPoint(latToSave, lngToSave),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Crop added successfully!')),
      );

      _quantityController.clear();
      _manualLatController.clear();
      _manualLngController.clear();
      setState(() {
        _imageFile = null;
        _lat = null;
        _lng = null;
        _selectedCropName = null;
        _selectedCropType = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      body: CustomScrollView(
        slivers: [
          // 🌾 Sticky AppBar
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: Colors.green.shade700,
            expandedHeight: 110,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Add Your Crop 🌾",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_farmerData != null)
                    Text(
                      "👋 Welcome, ${_farmerData!['name']}",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 🔍 Sticky Search Bar
          SliverPersistentHeader(
            pinned: true,
            delegate: _StickySearchBar(
              child: Container(
                color: Colors.green.shade50,
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  onChanged: _filterCrops,
                  decoration: InputDecoration(
                    hintText: 'Search crop name...',
                    prefixIcon: const Icon(Icons.search, color: Colors.green),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 🧩 Crop Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: _filteredCrops.isEmpty
                  ? const Center(child: Text("No crops found 😕"))
                  : GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1,
                          ),
                      itemCount: _filteredCrops.length,
                      itemBuilder: (context, index) {
                        final crop = _filteredCrops[index];
                        final isSelected =
                            _selectedCropName == crop['cropName'];
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedCropName = crop['cropName'];
                              _selectedCropType = crop['category'];
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.green.shade100
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? Colors.green
                                    : Colors.grey.shade300,
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  crop['image'],
                                  height: 40,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  crop['cropName'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.green.shade800
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),

          // 🌿 Form Section (below grid)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (_selectedCropName != null)
                      Chip(
                        backgroundColor: _selectedCropType == 'Non-Perishable'
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                        label: Text(
                          "$_selectedCropName (${_selectedCropType ?? ''})",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    const SizedBox(height: 15),

                    TextFormField(
                      controller: _quantityController,
                      decoration: const InputDecoration(
                        labelText: "Quantity (kg)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.scale),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.isEmpty ? "Enter quantity" : null,
                    ),
                    const SizedBox(height: 15),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _manualLatController,
                            decoration: const InputDecoration(
                              labelText: "Latitude",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _manualLngController,
                            decoration: const InputDecoration(
                              labelText: "Longitude",
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: _detectLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text("Use My Current Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),

                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.green.shade50,
                        ),
                        child: _imageFile == null
                            ? const Center(
                                child: Text("Tap to select crop image"),
                              )
                            : Image.file(_imageFile!, fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 25),

                    ElevatedButton(
                      onPressed: _isUploading ? null : _uploadCrop,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 60,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Upload Crop",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🧩 Helper widget: Sticky header for the search bar
class _StickySearchBar extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickySearchBar({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 70;
  @override
  double get minExtent => 70;
  @override
  bool shouldRebuild(_StickySearchBar oldDelegate) => false;
}
