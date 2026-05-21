import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PresenceService with WidgetsBindingObserver {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  bool _observerAdded = false;
  Timer? _heartbeatTimer;

  // Un usuario se considera online si su lastSeen fue hace menos de este umbral.
  static const _onlineThreshold = Duration(minutes: 2);
  // Frecuencia del heartbeat: debe ser menor que el umbral.
  static const _heartbeatInterval = Duration(seconds: 60);

  void init() {
    if (!_observerAdded) {
      WidgetsBinding.instance.addObserver(this);
      _observerAdded = true;
    }
    _startHeartbeat();
  }

  void deactivate() {
    _stopHeartbeat();
    _setOnline(false);
    if (_observerAdded) {
      WidgetsBinding.instance.removeObserver(this);
      _observerAdded = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startHeartbeat();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _stopHeartbeat();
      _setOnline(false);
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    // Actualiza inmediatamente y luego cada minuto.
    _setOnline(true);
    _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) => _setOnline(true));
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  Future<void> _setOnline(bool isOnline) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection('users').doc(uid).set(
      {'isOnline': isOnline, 'lastSeen': Timestamp.now()},
      SetOptions(merge: true),
    );
  }

  // Un usuario está online si isOnline=true Y su lastSeen es reciente.
  // Así, aunque isOnline quede atascado en true por un cierre abrupto,
  // tras _onlineThreshold sin heartbeat el usuario aparecerá desconectado.
  Stream<bool> watchOnlineStatus(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          final data = doc.data();
          if (data == null) return false;
          final isOnline = data['isOnline'] as bool? ?? false;
          if (!isOnline) return false;
          final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
          if (lastSeen == null) return false;
          return DateTime.now().difference(lastSeen) < _onlineThreshold;
        });
  }
}
