import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream para escuchar cambios de autenticación
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentUser => _firebaseAuth.currentUser;

  // Registro con correo y contraseña
  Future<UserCredential> register(
    String email,
    String password,
    String displayName, {
    String? lastName,
    DateTime? birthDate,
    String? gender,
    String? course,
  }) async {
    try {
      UserCredential userCredential = await _firebaseAuth
          .createUserWithEmailAndPassword(email: email, password: password);

      await userCredential.user?.updateDisplayName(displayName);

      // Calcular edad
      int? age;
      if (birthDate != null) {
        final now = DateTime.now();
        age = now.year - birthDate.year;
        if (now.month < birthDate.month ||
            (now.month == birthDate.month && now.day < birthDate.day)) {
          age--;
        }
      }

      // Crear documento de usuario en Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': email,
        'displayName': displayName,
        'lastName': lastName ?? '',
        'age': age ?? 0,
        'gender': gender ?? '',
        'course': course ?? '',
        'photoURL': '',
        'bio': '',
        'type': 'user',
        'blockedBy': <String>[],
        'profileComplete': false,
        'likes': 0,
        'friends': 0,
        'activities': 0,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Login con correo y contraseña
  Future<UserCredential> login(String email, String password) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }

  // Obtener datos del usuario desde Firestore
  Future<Map<String, dynamic>?> getUserDataById(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserDataByEmail(String email) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get()
          .then((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.first;
            } else {
              throw Exception('Usuario no encontrado');
            }
          });

      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) => snapshot.data() as Map<String, dynamic>?);
  }

  Future<String> getUserTypeById(String uid) async {
    try {
      final data = await getUserDataById(uid);
      final type = data?['type'] as String?;
      return (type != null && type.trim().isNotEmpty) ? type.trim() : 'user';
    } catch (e) {
      return 'user';
    }
  }
}
