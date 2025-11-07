import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AddMembersPage extends StatefulWidget {
  final String groupId;
  final String cropName;

  const AddMembersPage({
    Key? key,
    required this.groupId,
    required this.cropName,
  }) : super(key: key);

  @override
  State<AddMembersPage> createState() => _AddMembersPageState();
}

class _AddMembersPageState extends State<AddMembersPage> {
  final _auth = FirebaseAuth.instance;
  final _searchController = TextEditingController();
  bool _loading = false;
  bool _nearbyOnly = false;
  GeoPoint? _myLocation;

  List<Map<String, dynamic>> _farmers = [];
  List<String> _selectedFarmers = [];

  @override
  void initState() {
    super.initState();
    _loadMyLocation();
    _loadFarmers();
  }

  /// 🔹 Get farmer’s current location
  Future<void> _loadMyLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _myLocation = GeoPoint(pos.latitude, pos.longitude);
      });
    } catch (e) {
      debugPrint("⚠️ Location error: $e");
    }
  }

  /// 🔹 Load all farmers who produce same crop
  Future<void> _loadFarmers() async {
    setState(() => _loading = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('crops')
          .where('cropName', isEqualTo: widget.cropName)
          .get();

      List<Map<String, dynamic>> all = [];
      for (var doc in query.docs) {
        final data = doc.data();
        final farmerId = data['farmerId'];

        // Skip current farmer
        if (farmerId == _auth.currentUser!.uid) continue;

        data['id'] = farmerId;

        // Filter nearby if enabled
        if (_nearbyOnly && _myLocation != null && data['loc'] != null) {
          double distanceKm =
              Geolocator.distanceBetween(
                _myLocation!.latitude,
                _myLocation!.longitude,
                data['loc'].latitude,
                data['loc'].longitude,
              ) /
              1000;

          if (distanceKm <= 50) {
            data['distance'] = distanceKm;
            all.add(data);
          }
        } else {
          all.add(data);
        }
      }

      setState(() {
        _farmers = all;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading farmers: $e")));
    }
    setState(() => _loading = false);
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedFarmers.contains(id)) {
        _selectedFarmers.remove(id);
      } else {
        _selectedFarmers.add(id);
      }
    });
  }

  /// ✅ Send join requests (auto writes Firestore docs)
  Future<void> _sendRequests() async {
    if (_selectedFarmers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Select at least one farmer")),
      );
      return;
    }

    setState(() => _loading = true);
    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId);

    final fromUid = _auth.currentUser!.uid;

    for (final toUid in _selectedFarmers) {
      final requestData = {
        'fromUid': fromUid,
        'toUid': toUid,
        'cropName': widget.cropName,
        'status': 'pending',
        'sentOn': FieldValue.serverTimestamp(),
      };

      await groupRef.collection('requests').add(requestData);
    }

    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Requests sent successfully')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFarmers = _farmers
        .where(
          (f) => f['farmerName'].toString().toLowerCase().contains(
            _searchController.text.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text("Add Members - ${widget.cropName}"),
        backgroundColor: Colors.green.shade700,
      ),
      backgroundColor: Colors.green.shade50,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: "Search farmers by name...",
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text("Nearby (50 km)"),
                    Switch(
                      value: _nearbyOnly,
                      onChanged: (v) {
                        setState(() => _nearbyOnly = v);
                        _loadFarmers();
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filteredFarmers.isEmpty
                ? const Center(
                    child: Text(
                      "No farmers found 👨‍🌾",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(10),
                    itemCount: filteredFarmers.length,
                    itemBuilder: (context, i) {
                      final f = filteredFarmers[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: CheckboxListTile(
                          value: _selectedFarmers.contains(f['id']),
                          onChanged: (_) => _toggleSelection(f['id']),
                          title: Text(f['farmerName'] ?? 'Farmer'),
                          subtitle: Text(
                            "${f['cropName']} • "
                            "${f['distance'] != null ? f['distance'].toStringAsFixed(1) + ' km' : 'Distance N/A'}",
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.send),
              label: const Text("Send Requests"),
              onPressed: _loading ? null : _sendRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
