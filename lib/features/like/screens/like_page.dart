import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';
import 'package:RockMeet/core/models/user_profile.dart';

class LikesPage extends StatefulWidget {
  const LikesPage({super.key});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  late final Stream<List<UserProfile>> _likesStream;

  @override
  void initState() {
    super.initState();
    _likesStream = _buildLikesStream();
  }

  /// Stream en tiempo real: personas que me dieron like, excluyendo matches mutuos.
  Stream<List<UserProfile>> _buildLikesStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('interactions')
        .where('toUserId', isEqualTo: currentUser.uid)
        .where('type', isEqualTo: 'like')
        .snapshots()
        .asyncMap((snapshot) => _processSnapshot(snapshot, currentUser.uid));
  }

  Future<List<UserProfile>> _processSnapshot(
    QuerySnapshot snapshot,
    String currentUserId,
  ) async {
    final result = <UserProfile>[];

    for (final doc in snapshot.docs) {
      final fromUserId = doc.data() is Map
          ? (doc.data() as Map<String, dynamic>)['fromUserId'] as String? ?? ''
          : '';
      if (fromUserId.isEmpty) continue;

      // Si yo también di like → es match → no aparece aquí
      final mutualDoc = await _firestore
          .collection('interactions')
          .doc('${currentUserId}_$fromUserId')
          .get();

      if (mutualDoc.exists && mutualDoc.data()?['type'] == 'like') continue;

      try {
        final userDoc =
            await _firestore.collection('users').doc(fromUserId).get();
        if (userDoc.exists) {
          result.add(UserProfile.fromFirestore(userDoc));
        }
      } catch (_) {}
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<List<UserProfile>>(
          stream: _likesStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
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
                  Text(
                    'Sugerencias para ti',
                    style: AppTextStyles.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    likes.isEmpty
                        ? 'Aún no tienes likes'
                        : '${likes.length} ${likes.length == 1 ? 'persona' : 'personas'} están interesadas en ti',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

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
                        child: Column(
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 56,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Sigue conociendo gente',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
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

  Widget _buildLikeCard(UserProfile person) {
    final photo = person.photoURL ??
        (person.photos != null && person.photos!.isNotEmpty
            ? person.photos!.first
            : null);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppColors.surface,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Foto con blur (privacy)
          if (photo != null)
            Image.network(
              photo,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.surface,
                child: const Icon(Icons.person, color: Colors.white38, size: 48),
              ),
            )
          else
            Container(
              color: AppColors.surface,
              child: const Icon(Icons.person, color: Colors.white38, size: 48),
            ),

          // Blur de privacidad
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(color: Colors.black.withOpacity(0.18)),
            ),
          ),

          // Gradiente inferior
          Positioned.fill(
            child: DecoratedBox(
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
          ),

          // Candado central
          Center(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.55),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Icon(
                Icons.lock_outline,
                color: AppColors.primary.withOpacity(0.9),
                size: 26,
              ),
            ),
          ),

          // Info
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${person.name}, ${person.age}',
                  style: AppTextStyles.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Dale like para ver el perfil',
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
