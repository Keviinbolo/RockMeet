import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/config/Theme/constants/text_styles.dart';

// 1. Modelo de Usuario
class UserProfile {
  final String uid;
  final String name;
  final int age;
  final String? photoURL;

  UserProfile({
    required this.uid,
    required this.name,
    required this.age,
    this.photoURL,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: doc.id,
      name: data['displayName'] ?? 'Usuario',
      age: data['age'] ?? 0,
      photoURL: data['photoURL'],
    );
  }
}

// 2. La Página Principal
class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Obtiene los likes del usuario actual (usuarios que le dieron like)
  /// Excluye los matches (usuarios con los que hay mutual like)
  Future<List<UserProfile>> _getLikesExcludingMatches() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return [];

    try {
      // Obtener todas las interacciones donde alguien me dio like
      final likesSnapshot = await _firestore
          .collection('interactions')
          .where('toUserId', isEqualTo: currentUser.uid)
          .where('type', isEqualTo: 'like')
          .get();

      List<UserProfile> userLikes = [];

      for (var doc in likesSnapshot.docs) {
        final fromUserId = doc['fromUserId'] as String;

        // Verificar si es un match (yo también di like a este usuario)
        final mutualLikeSnapshot = await _firestore
            .collection('interactions')
            .where('fromUserId', isEqualTo: currentUser.uid)
            .where('toUserId', isEqualTo: fromUserId)
            .where('type', isEqualTo: 'like')
            .get();

        // Solo agregar si NO es un match
        if (mutualLikeSnapshot.docs.isEmpty) {
          try {
            final userDoc =
                await _firestore.collection('users').doc(fromUserId).get();
            if (userDoc.exists) {
              userLikes.add(UserProfile.fromFirestore(userDoc));
            }
          } catch (e) {
            debugPrint('Error obteniendo usuario $fromUserId: $e');
          }
        }
      }

      return userLikes;
    } catch (e) {
      debugPrint('Error obteniendo likes: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<UserProfile>>(
          future: _getLikesExcludingMatches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar los likes',
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }

            final likes = snapshot.data ?? [];

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header ---
                  Text(
                    "Sugerencias para ti",
                    style: AppTextStyles.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    likes.isEmpty
                        ? "Aún no tienes likes"
                        : "${likes.length} ${likes.length == 1 ? 'persona' : 'personas'} están interesadas en ti",
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // --- Grid de Likes ---
                  if (likes.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 3 / 4,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: likes.length,
                      itemBuilder: (context, index) =>
                          _buildLikeCard(likes[index]),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40.0),
                        child: Text(
                          'Sigue conociendo gente',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Widget para cada tarjeta individual
  Widget _buildLikeCard(UserProfile person) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Imagen con Blur
          if (person.photoURL != null)
            Image.network(
              person.photoURL!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.person),
                );
              },
            )
          else
            Container(
              color: AppColors.surface,
              child: const Icon(Icons.person),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),
          ),

          // Gradiente inferior para legibilidad del texto
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  AppColors.background.withOpacity(0.8),
                  AppColors.background,
                ],
              ),
            ),
          ),

          // Icono de Candado
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.primary.withOpacity(0.7),
                size: 28,
              ),
            ),
          ),

          // Información del perfil
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${person.name}, ${person.age}",
                  style: AppTextStyles.titleLarge,
                ),
                Text(
                  "Dale like para ver perfil",
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}