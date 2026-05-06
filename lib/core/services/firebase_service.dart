import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  
  factory FirebaseService() {
    return _instance;
  }
  
  FirebaseService._internal();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Subir foto a Firebase Storage
  Future<String> uploadImage(String filePath, String folder) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference ref = _storage.ref().child('$folder/$fileName');

      await ref.putFile(File(filePath));
      String downloadUrl = await ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      rethrow;
    }
  }
  
  // Obtener documentos de una colección
  Future<List<Map<String, dynamic>>> getDocuments(String collection) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
    } catch (e) {
      rethrow;
    }
  }
  
  // Stream de documentos en tiempo real
  Stream<List<Map<String, dynamic>>> getDocumentsStream(String collection) {
    return _firestore.collection(collection).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => doc.data()).toList());
  }
  
  // Crear documento
  Future<String> createDocument(String collection, Map<String, dynamic> data) async {
    try {
      DocumentReference ref = await _firestore.collection(collection).add(data);
      return ref.id;
    } catch (e) {
      rethrow;
    }
  }
  
  // Actualizar documento
  Future<void> updateDocument(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(collection).doc(docId).update(data);
    } catch (e) {
      rethrow;
    }
  }
  
  // Eliminar documento
  Future<void> deleteDocument(String collection, String docId) async {
    try {
      await _firestore.collection(collection).doc(docId).delete();
    } catch (e) {
      rethrow;
    }
  }
}