import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsPage extends StatefulWidget {
  const RequestsPage({Key? key}) : super(key: key);

  @override
  State<RequestsPage> createState() => _RequestsPageState();
}

class _RequestsPageState extends State<RequestsPage> {
  final _auth = FirebaseAuth.instance;
  bool _loading = false;

  // 🔥 Stream: show groups where this farmer is admin
  Stream<QuerySnapshot> _myGroupsStream() {
    final uid = _auth.currentUser!.uid;
    return FirebaseFirestore.instance
        .collection('groups')
        .where('creatorUid', isEqualTo: uid)
        .snapshots();
  }

  Future<void> _acceptRequest(String groupId, DocumentSnapshot reqDoc) async {
    setState(() => _loading = true);
    try {
      final req = reqDoc.data() as Map<String, dynamic>;
      final fromUid = req['fromUid'] as String?;
      final cropId = req['cropId'] as String?;
      final cropQty = (req['cropQuantity'] ?? 0).toDouble();

      if (fromUid == null || cropId == null) {
        throw "Invalid request data.";
      }

      final groupRef = FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId);

      // 1️⃣ Add/Update member info under subcollection
      final memberRef = groupRef.collection('members').doc(fromUid);
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(fromUid)
          .get();
      final userData = userDoc.exists ? userDoc.data() : {};

      final memberSnap = await memberRef.get();
      if (memberSnap.exists) {
        final prev = (memberSnap.data()!['contributionQty'] ?? 0).toDouble();
        await memberRef.update({
          'contributionQty': prev + cropQty,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      } else {
        await memberRef.set({
          'farmerId': fromUid,
          'name': userData?['name'] ?? '',
          'phone': userData?['phone'] ?? '',
          'address': userData?['address'] ?? '',
          'contributionQty': cropQty,
          'joinedOn': FieldValue.serverTimestamp(),
          'loc': req['cropLoc'],
        });
      }

      // 2️⃣ Update group quantity and members list
      final groupSnap = await groupRef.get();
      final g = groupSnap.data()!;
      final prevQty = (g['groupTargetQty'] ?? 0).toDouble();
      await groupRef.update({
        'groupTargetQty': prevQty + cropQty,
        'members': FieldValue.arrayUnion([fromUid]),
      });

      // 3️⃣ Update crop doc to link to this group
      await FirebaseFirestore.instance.collection('crops').doc(cropId).update({
        'groupId': groupId,
        'grouped': true,
      });

      // 4️⃣ Mark request as accepted
      await reqDoc.reference.update({
        'status': 'accepted',
        'respondedOn': FieldValue.serverTimestamp(),
        'respondedBy': _auth.currentUser!.uid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Request accepted, farmer added to group"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _rejectRequest(DocumentSnapshot reqDoc) async {
    try {
      await reqDoc.reference.update({
        'status': 'rejected',
        'respondedOn': FieldValue.serverTimestamp(),
        'respondedBy': _auth.currentUser!.uid,
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("❌ Request rejected")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error rejecting: $e")));
    }
  }

  Future<List<QueryDocumentSnapshot>> _getRequests(String groupId) async {
    final reqs = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupId)
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .get();
    return reqs.docs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join Requests 📬"),
        backgroundColor: Colors.green.shade700,
      ),
      backgroundColor: Colors.green.shade50,
      body: StreamBuilder<QuerySnapshot>(
        stream: _myGroupsStream(),
        builder: (context, groupsSnap) {
          if (groupsSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!groupsSnap.hasData || groupsSnap.data!.docs.isEmpty) {
            return const Center(
              child: Text("You are not an admin of any groups yet."),
            );
          }

          final groups = groupsSnap.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              final gdata = group.data() as Map<String, dynamic>;
              final groupId = group.id;
              final groupName = gdata['groupName'] ?? 'Unnamed Group';
              final cropName = gdata['cropName'] ?? '';

              return ExpansionTile(
                title: Text(
                  "$groupName ($cropName)",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                subtitle: const Text("Pending requests"),
                children: [
                  FutureBuilder<List<QueryDocumentSnapshot>>(
                    future: _getRequests(groupId),
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: LinearProgressIndicator(),
                        );
                      }

                      final reqs = snap.data ?? [];
                      if (reqs.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text("No pending requests"),
                        );
                      }

                      return Column(
                        children: reqs.map((r) {
                          final data = r.data() as Map<String, dynamic>;
                          final name = data['fromName'] ?? 'Farmer';
                          final phone = data['fromPhone'] ?? '';
                          final qty = data['cropQuantity']?.toString() ?? '-';
                          final loc = data['cropLoc'] as GeoPoint?;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            child: ListTile(
                              title: Text(name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Qty: $qty kg"),
                                  if (phone.isNotEmpty) Text("📞 $phone"),
                                  if (loc != null)
                                    Text(
                                      "📍 ${loc.latitude.toStringAsFixed(4)}, ${loc.longitude.toStringAsFixed(4)}",
                                    ),
                                ],
                              ),
                              trailing: _loading
                                  ? const SizedBox(
                                      width: 40,
                                      height: 40,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Wrap(
                                      spacing: 8,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                            size: 30,
                                          ),
                                          onPressed: () =>
                                              _acceptRequest(groupId, r),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.cancel,
                                            color: Colors.red,
                                            size: 30,
                                          ),
                                          onPressed: () => _rejectRequest(r),
                                        ),
                                      ],
                                    ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
