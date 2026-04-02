import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme/app_theme.dart';

class ApprovalGate extends StatelessWidget {
  final Widget child;
  const ApprovalGate({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return child;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));
        final data = snap.data!.data() as Map<String, dynamic>?;
        final status = data?['status'] as String? ?? 'pending';
        if (status == 'approved') return child;
        if (status == 'rejected') return _StatusScreen(approved: false);
        return _StatusScreen(approved: null);
      },
    );
  }
}

class _StatusScreen extends StatelessWidget {
  final bool? approved; // null = pending, false = rejected
  const _StatusScreen({required this.approved});

  @override
  Widget build(BuildContext context) {
    final isPending = approved == null;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isPending ? Icons.hourglass_top_rounded : Icons.cancel_rounded,
                  size: 64, color: isPending ? Colors.orange : Colors.red),
              const SizedBox(height: 24),
              Text(isPending ? 'Awaiting Approval' : 'Account Rejected',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                isPending
                    ? 'Your driver account is under review.\nAdmin will approve it shortly.'
                    : 'Your account was not approved.\nContact support for help.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                onPressed: () => FirebaseAuth.instance.signOut(),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
