import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class AddCropToGroupPage extends StatefulWidget {
  final String cropId;
  final String cropName;
  final GeoPoint? cropLoc;
  final double cropQuantity;

  const AddCropToGroupPage({
    Key? key,
    required this.cropId,
    required this.cropName,
    required this.cropLoc,
    required this.cropQuantity,
  }) : super(key: key);

  @override
  State<AddCropToGroupPage> createState() => _AddCropToGroupPageState();
}

class _AddCropToGroupPageState extends State<AddCropToGroupPage> {
  final _auth = FirebaseAuth.instance;
  bool _loading = false;
  bool _nearbyOnly = true;
  String _activeTab = "my"; // "my" or "all"
  GeoPoint? _deviceLocation;

  List<QueryDocumentSnapshot> _joinedGroups = [];
  List<QueryDocumentSnapshot> _unjoinedGroups = [];

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  // 📍 Initialize and load groups
  Future<void> _initAndLoad() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        _deviceLocation = GeoPoint(pos.latitude, pos.longitude);
      }
    } catch (_) {
      // location unavailable
    }
    await _loadGroups();
  }

  // 🧩 Load all relevant groups
  Future<void> _loadGroups() async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final query = await FirebaseFirestore.instance
          .collection('groups')
          .where('cropName', isEqualTo: widget.cropName)
          .where('isOpenGroup', isEqualTo: true)
          .get();

      final joined = <QueryDocumentSnapshot>[];
      final unjoined = <QueryDocumentSnapshot>[];
      final base = widget.cropLoc ?? _deviceLocation;

      for (var doc in query.docs) {
        final data = doc.data();
        final members = (data['members'] as List?)?.cast<String>() ?? [];
        final isMember = members.contains(uid);
        final loc = data['creatorLocation'] as GeoPoint?;

        if (isMember) {
          joined.add(doc);
        } else {
          if (_nearbyOnly && base != null && loc != null) {
            final dist = _distanceKm(
              base.latitude,
              base.longitude,
              loc.latitude,
              loc.longitude,
            );
            if (dist <= 50) unjoined.add(doc);
          } else if (!_nearbyOnly) {
            unjoined.add(doc);
          }
        }
      }

      setState(() {
        _joinedGroups = joined;
        _unjoinedGroups = unjoined;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading groups: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🌎 Haversine formula
  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_deg2rad(lat1)) *
            math.cos(_deg2rad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  double _deg2rad(double d) => d * (math.pi / 180.0);

  // ✅ Direct add crop to joined group
  Future<void> _directAddToGroup(String groupId) async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);
      final groupSnap = await groupRef.get();
      if (!groupSnap.exists) throw "Group not found";

      // Update member contribution
      final memberRef = groupRef.collection('members').doc(uid);
      final memberSnap = await memberRef.get();
      if (memberSnap.exists) {
        final data = memberSnap.data()!;
        final prevQty = (data['contributionQty'] ?? 0).toDouble();
        await memberRef.update({
          'contributionQty': prevQty + widget.cropQuantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = userDoc.data() ?? {};
        await memberRef.set({
          'farmerId': uid,
          'name': userData['name'] ?? '',
          'phone': userData['phone'] ?? '',
          'address': userData['address'] ?? '',
          'contributionQty': widget.cropQuantity,
          'joinedOn': FieldValue.serverTimestamp(),
          'loc': widget.cropLoc,
        });
      }

      // Update crop doc
      await FirebaseFirestore.instance
          .collection('crops')
          .doc(widget.cropId)
          .update({'grouped': true, 'groupId': groupId});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Crop added successfully to your group!"),
        ),
      );
      await _loadGroups();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // 📩 Send join request to another group
  Future<void> _sendJoinRequest(QueryDocumentSnapshot group) async {
    setState(() => _loading = true);
    try {
      final uid = _auth.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final user = userDoc.data() ?? {};

      await FirebaseFirestore.instance
          .collection('groups')
          .doc(group.id)
          .collection('requests')
          .add({
            'fromUid': uid,
            'fromName': user['name'] ?? '',
            'fromPhone': user['phone'] ?? '',
            'fromAddress': user['address'] ?? '',
            'cropId': widget.cropId,
            'cropName': widget.cropName,
            'cropQuantity': widget.cropQuantity,
            'cropLoc': widget.cropLoc,
            'status': 'pending',
            'sentOn': FieldValue.serverTimestamp(),
          });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📩 Join request sent to group admin")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  // 🧱 Build each group card
  Widget _groupCard(QueryDocumentSnapshot g, {required bool joined}) {
    final data = g.data() as Map<String, dynamic>;
    final name = data['groupName'] ?? 'Unnamed';
    final price = (data['minPriceExpected'] ?? '-').toString();
    final adminId = data['creatorUid'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: ListTile(
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Min Price: ₹$price/kg"),
        trailing: joined
            ? ElevatedButton(
                onPressed: _loading ? null : () => _directAddToGroup(g.id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                ),
                child: const Text("Add"),
              )
            : ElevatedButton(
                onPressed: _loading ? null : () => _sendJoinRequest(g),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: const Text("Request"),
              ),
      ),
    );
  }

  // 📜 Build groups list for each tab
  Widget _buildGroupsList(List<QueryDocumentSnapshot> groups, bool joined) {
    if (groups.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          joined
              ? "You have not joined any group for this crop yet."
              : "No open groups available for this crop.",
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }
    return Column(
      children: groups.map((g) => _groupCard(g, joined: joined)).toList(),
    );
  }

  // 🌿 UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade50,
      appBar: AppBar(
        title: Text("Add ${widget.cropName} to group"),
        backgroundColor: Colors.green.shade700,
      ),
      body: RefreshIndicator(
        onRefresh: _loadGroups,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // 📍 Nearby toggle
                Row(
                  children: [
                    const Text("Show nearby (≤ 50 km)"),
                    Switch(
                      value: _nearbyOnly,
                      onChanged: (v) {
                        setState(() => _nearbyOnly = v);
                        _loadGroups();
                      },
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadGroups,
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 🧭 Tab Toggle
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = "my"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == "my"
                                ? Colors.green.shade700
                                : Colors.green.shade200,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              bottomLeft: Radius.circular(10),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "My Groups",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = "all"),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _activeTab == "all"
                                ? Colors.green.shade700
                                : Colors.green.shade200,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            "All Groups",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                _loading
                    ? const LinearProgressIndicator()
                    : _activeTab == "my"
                    ? _buildGroupsList(_joinedGroups, true)
                    : _buildGroupsList(_unjoinedGroups, false),

                const SizedBox(height: 25),
                const Text(
                  "Tip: To add this crop directly to a group, select one where you're already a member. Otherwise, send a join request.",
                  style: TextStyle(color: Colors.black54, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
