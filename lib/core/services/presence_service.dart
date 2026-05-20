import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _observerAdded = false;

  void init() {
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    _setOnline(true);
  }

  void deactivate() {
    _setOnline(false);
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set(
      {'isOnline': isOnline, 'lastSeen': Timestamp.now()},
      SetOptions(merge: true),
    );
  }

  Stream<bool> watchOnlineStatus(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] as bool? ?? false);
  }
}
