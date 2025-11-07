import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RequestsBadge extends StatelessWidget {
  final VoidCallback onTap;

  const RequestsBadge({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return IconButton(
        icon: const Icon(Icons.notifications),
        onPressed: onTap,
      );
    }

    final stream = FirebaseFirestore.instance
        .collectionGroup('requests')
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (context, snapshot) {
        int count = snapshot.data?.docs.length ?? 0;
        return Stack(
          children: [
            IconButton(icon: const Icon(Icons.notifications), onPressed: onTap),
            if (count > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
