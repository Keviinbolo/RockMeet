import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';
import 'package:RockMeet/core/models/user_profile.dart';
import 'package:RockMeet/core/services/chat_service.dart';
import 'package:RockMeet/core/services/interaction_service.dart';
import 'package:RockMeet/core/services/profile_service.dart';
import 'package:RockMeet/core/widgets/match_animation_widget.dart';
import 'package:RockMeet/features/chat/screens/chat_page.dart';
import 'package:RockMeet/features/events/screens/event_screen.dart';
import 'package:RockMeet/features/home/widgets/swipeable_card.dart';
import 'package:RockMeet/features/like/screens/like_page.dart';
import 'package:RockMeet/features/profile/screens/Perfil.dart';
import 'package:RockMeet/features/settings/screens/ajustes.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  int _selectedNavIndex = 0;
  double _dragDownProgress = 0;
  bool _showCardHints = true;
  static const int _profilesPageSize = 20;
  bool _isResettingInteractions = false;
  bool _isLoadingProfiles = false;
  bool _hasMoreProfiles = true;
  String? _profilesError;
  DocumentSnapshot<Map<String, dynamic>>? _lastProfileDoc;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> _profileDocs = [];
  List<UserProfile> _visibleProfiles = [];
  bool _isLoadingInitialInteractions = true;
  Set<String> _interactedUserIds = {};
  String? _pendingChatPeerUid;
  String? _pendingChatPeerName;
  String? _pendingChatPeerAvatarUrl;
  UserProfile? _currentUserProfile;
  static const String _fallbackPhotoUrl =
      'https://images.unsplash.com/photo-1521119989659-a83eee488004?q=80&w=1080';

  @override
  void initState() {
    super.initState();
    _initInteractionsAndLoadProfiles();
    _loadCurrentUserProfile();
  }

  Future<void> _loadCurrentUserProfile() async {
    final profile = await _getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _currentUserProfile = profile;
      });
    }
  }

  Future<void> _initInteractionsAndLoadProfiles() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        _interactedUserIds =
            await InteractionService.instance.loadInteractedUserIds(currentUserId);
      } catch (e) {
        print('Error loading initial interactions: $e');
      }
    }

    if (mounted) {
      setState(() {
        _isLoadingInitialInteractions = false;
      });
      _loadMoreProfiles(reset: true);
    }
  }

  Query<Map<String, dynamic>> _profilesBaseQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy(FieldPath.documentId)
        .limit(_profilesPageSize);
  }

  UserProfile _mapDocToProfile(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int index,
  ) {
    final data = doc.data();

    final displayName = (data['displayName'] as String?)?.trim();
    final bio = (data['bio'] as String?)?.trim();
    final age = data['age'];
    final twitter = (data['twitter'] as String?)?.trim();
    final instagram = (data['instagram'] as String?)?.trim();
    final tiktok = (data['tiktok'] as String?)?.trim();
    final gender = (data['gender'] as String?)?.trim();
    final course = (data['course'] as String?)?.trim();
    final interests =
        (data['interests'] as List?)?.whereType<String>().toList() ??
        <String>[];
    final interestsDetailMap = <String, List<String>>{};
    final rawDetail = data['interestsDetail'];
    if (rawDetail is Map) {
      for (final entry in rawDetail.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (key.trim().isNotEmpty && val is List) {
          interestsDetailMap[key] = val.whereType<String>().toList();
        }
      }
    }
    final gallery =
        (data['gallery'] as List?)?.whereType<String>().toList() ?? <String>[];
    final photoUrl = (data['photoURL'] as String?)?.trim();
    final parsedAge = age is int ? age : int.tryParse('$age');
    final safeAge = (parsedAge != null && parsedAge >= 18 && parsedAge <= 99)
        ? parsedAge
        : 18;

    final photos = <String>{
      if (photoUrl != null && photoUrl.isNotEmpty) photoUrl,
      ...gallery.map((url) => url.trim()).where((url) => url.isNotEmpty),
    }.toList(growable: false);

    final spotify = (data['spotify'] as String?)?.trim();
    final favoriteSong = (data['favoriteSong'] as String?)?.trim();
    final favoriteArtist = (data['favoriteArtist'] as String?)?.trim();

    return UserProfile(
      uid: doc.id,
      name: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Usuario',
      age: safeAge,
      photos: photos.isNotEmpty ? photos : <String>[_fallbackPhotoUrl],
      bio: (bio != null && bio.isNotEmpty) ? bio : null,
      interests: interests.isNotEmpty ? interests : null,
      interestsDetail: interestsDetailMap.isNotEmpty ? interestsDetailMap : null,
      twitter: (twitter != null && twitter.isNotEmpty) ? twitter : null,
      instagram: (instagram != null && instagram.isNotEmpty) ? instagram : null,
      tiktok: (tiktok != null && tiktok.isNotEmpty) ? tiktok : null,
      spotify: (spotify != null && spotify.isNotEmpty) ? spotify : null,
      favoriteSong: (favoriteSong != null && favoriteSong.isNotEmpty) ? favoriteSong : null,
      favoriteArtist: (favoriteArtist != null && favoriteArtist.isNotEmpty) ? favoriteArtist : null,
      isStaff: data['isStaff'] as bool? ?? false,
    );
  }

  Future<void> _loadMoreProfiles({bool reset = false}) async {
    if (_isLoadingProfiles) return;
    if (!reset && !_hasMoreProfiles) return;

    setState(() {
      _isLoadingProfiles = true;
      _profilesError = null;
      if (reset) {
        _profileDocs.clear();
        _lastProfileDoc = null;
        _hasMoreProfiles = true;
        currentIndex = 0;
      }
    });

    try {
      Query<Map<String, dynamic>> query = _profilesBaseQuery();
      if (_lastProfileDoc != null && !reset) {
        query = query.startAfterDocument(_lastProfileDoc!);
      }

      final snapshot = await query.get();
      final docs = snapshot.docs;
      final visibleDocs = docs
          .where((doc) {
            final data = doc.data();
            return (data['type'] as String?) != 'staff';
          })
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        if (docs.isEmpty) {
          _hasMoreProfiles = false;
        } else {
          final knownIds = _profileDocs.map((doc) => doc.id).toSet();
          for (final doc in visibleDocs) {
            if (!knownIds.contains(doc.id) &&
                !_interactedUserIds.contains(doc.id)) {
              _profileDocs.add(doc);
            }
          }
          _lastProfileDoc = docs.last;
          _hasMoreProfiles = docs.length == _profilesPageSize;

          // If after filtering we have no new docs but there are more in DB, load next page automatically
          if (_profileDocs.isEmpty && _hasMoreProfiles) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _loadMoreProfiles();
            });
          }
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _profilesError = 'No se pudieron cargar perfiles: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingProfiles = false;
        });
      }
    }
  }

  Future<void> _saveInteraction({
    required UserProfile profile,
    required String type,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _interactedUserIds.add(profile.uid);
    await InteractionService.instance.save(
      fromUserId: currentUser.uid,
      toUserId: profile.uid,
      type: type,
    );
  }

  Future<bool> _isMutualLike(UserProfile profile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    return InteractionService.instance.isMutualLike(
      fromUserId: currentUser.uid,
      toUserId: profile.uid,
    );
  }

  Future<void> _prepareChatForMatch(UserProfile profile) async {
    await ChatService.instance.ensureDirectChat(
      peerUid: profile.uid,
      peerName: profile.name,
      peerAvatarUrl: profile.photos?.first,
    );

    if (!mounted) return;
    setState(() {
      _pendingChatPeerUid = profile.uid;
      _pendingChatPeerName = profile.name;
      _pendingChatPeerAvatarUrl = profile.photos?.first;
    });
  }

  Future<UserProfile?> _getCurrentUserProfile() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;

      final displayName = (data['displayName'] as String?)?.trim();
      final age = data['age'];
      final parsedAge = age is int ? age : int.tryParse('$age');
      final safeAge = (parsedAge != null && parsedAge >= 18 && parsedAge <= 99)
          ? parsedAge
          : 18;
      final interests =
          (data['interests'] as List?)?.whereType<String>().toList() ??
          <String>[];
      final gender = (data['gender'] as String?)?.trim();
      final course = (data['course'] as String?)?.trim();

      return UserProfile(
        uid: currentUser.uid,
        name: displayName ?? 'Usuario',
        age: safeAge,
        isStaff: false,
        interests: interests.isNotEmpty ? interests : null,
        gender: gender,
        course: course,
      );
    } catch (e) {
      print('Error getting current user profile: $e');
      return null;
    }
  }

  int _calculateCompatibility(UserProfile currentUser, UserProfile otherUser) {
    int compatibilityScore = 0;

    // Edad similar (dentro de 3 años): 25 puntos
    final ageDifference = (currentUser.age - otherUser.age).abs();
    if (ageDifference <= 3) {
      compatibilityScore += 25;
    } else if (ageDifference <= 5) {
      compatibilityScore += 15;
    }

    // Mismos intereses: 35 puntos
    if (currentUser.interests != null &&
        otherUser.interests != null &&
        currentUser.interests!.isNotEmpty &&
        otherUser.interests!.isNotEmpty) {
      final commonInterests = currentUser.interests!
          .toSet()
          .intersection(otherUser.interests!.toSet());
      if (commonInterests.isNotEmpty) {
        final matchPercentage = commonInterests.length / 
            ((currentUser.interests!.length + otherUser.interests!.length) / 2);
        compatibilityScore += (35 * matchPercentage).toInt();
      }
    }

    // Mismo curso: 20 puntos
    if (currentUser.course != null &&
        otherUser.course != null &&
        currentUser.course!.isNotEmpty &&
        otherUser.course!.isNotEmpty &&
        currentUser.course == otherUser.course) {
      compatibilityScore += 20;
    }

    // Limitar a 100 puntos máximo
    return compatibilityScore.clamp(0, 100);
  }

  Future<void> _resetInteractions() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null || _isResettingInteractions) return;

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Reiniciar interacciones'),
              content: const Text(
                'Se borrarán todos los likes, matches y chats (enviados y recibidos) y se resetearán los contadores de Likes y Amigos.\n\n¿Quieres continuar?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Reiniciar'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!confirmed) return;

    setState(() => _isResettingInteractions = true);

    try {
      await InteractionService.instance.deleteAllForUser(currentUserId);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .set({'likes': 0, 'friends': 0}, SetOptions(merge: true));

      // Borrar todos los chats (con sus mensajes) en los que participa el usuario
      await ChatService.instance.deleteAllChatsForUser(currentUserId);

      if (!mounted) return;

      setState(() {
        _interactedUserIds.clear();
        _pendingChatPeerUid = null;
        _pendingChatPeerName = null;
        _pendingChatPeerAvatarUrl = null;
        currentIndex = 0;
        _dragDownProgress = 0;
      });

      await _loadMoreProfiles(reset: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interacciones, chats y contadores reiniciados.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al reiniciar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isResettingInteractions = false);
      }
    }
  }

  Future<void> _handlePass(
    UserProfile currentProfile,
    int profilesLength,
  ) async {
    try {
      await _saveInteraction(profile: currentProfile, type: 'pass');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la interacción.')),
        );
      }
    } finally {
      _nextProfile(profilesLength);
    }
  }

  Future<void> _handleLike(
    UserProfile currentProfile,
    int profilesLength,
  ) async {
    try {
      await _saveInteraction(profile: currentProfile, type: 'like');
    } catch (e) {
      print("Error guardando interacción: $e");
      if (mounted) _nextProfile(profilesLength);
      return;
    }

    // Incrementar likes: no crí­tico, no bloquea el flujo
    ProfileService.instance
        .incrementLikesCountForUser(currentProfile.uid)
        .catchError((e) => print("Error incrementando likes: $e"));

    final isMutualLike = await _isMutualLike(currentProfile);

    if (isMutualLike) {
      try {
        await _prepareChatForMatch(currentProfile);
      } catch (e) {
        print("Error preparando chat: $e");
      }
      // Contadores de amigos: no crí­ticos, no bloquean el modal
      ProfileService.instance
          .incrementFriendsCount()
          .catchError((e) => print("Error incrementando amigos: $e"));
      ProfileService.instance
          .incrementFriendsCountForUser(currentProfile.uid)
          .catchError((e) => print("Error incrementando amigos del otro: $e"));
      _showMatchModal(currentProfile, profilesLength);
    } else {
      _nextProfile(profilesLength);
    }
  }

  void _nextProfile(int profilesLength) {
    if (profilesLength == 0) return;
    setState(() {
      currentIndex = (currentIndex + 1) % profilesLength;
      _dragDownProgress = 0;
    });
  }

  void _showMatchModal(UserProfile currentProfile, int profilesLength) {
    if (profilesLength == 0) return;
    final imageForModal = currentProfile.photos
        ?.map((url) => url.trim())
        .firstWhere((url) => url.isNotEmpty, orElse: () => _fallbackPhotoUrl);

    // MEJORA: Usar showGeneralDialog para que la animación ocupe toda la pantalla correctamente
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "Match",
      pageBuilder: (context, anim1, anim2) {
        return MatchModal(
          profile: {'name': currentProfile.name, 'image': imageForModal},
          onSendMessage: () {
            // El botón del modal ya invoca Navigator.pop; aquí­ solo cambiamos de pestaña
            setState(() {
              _selectedNavIndex = 2;
            });
          },
          onClose: () {
            Navigator.of(context).pop();
            _nextProfile(profilesLength);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                backgroundColor: AppColors.surface,
                title: Image.asset(
                  'lib/config/Theme/Logo/RockMeetLogo.png',
                  height: 40,
                  fit: BoxFit.contain,
                ),
                centerTitle: true,
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: _isResettingInteractions
                        ? null
                        : _resetInteractions,
                    icon: _isResettingInteractions
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    color: AppColors.textPrimary,
                    tooltip: 'Reiniciar perfiles',
                  ),
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings),
                    color: AppColors.textPrimary,
                  ),
                ],
              ),
              Expanded(
                child: IndexedStack(
                  // Recomendado usar IndexedStack para mantener el estado de las páginas
                  index: _selectedNavIndex,
                  children: [
                    _buildExplore(),
                    const LikesPage(),
                    // CHAT SCREEN
                    ChatScreen(
                      // El ValueKey es vital: si _pendingChatPeerUid cambia, Flutter recrea el widget
                      key: ValueKey('chat_${_pendingChatPeerUid ?? "list"}'),
                      initialPeerUid: _pendingChatPeerUid,
                      initialPeerName: _pendingChatPeerName,
                      initialPeerAvatarUrl: _pendingChatPeerAvatarUrl,
                    ),
                    const EventScreen(),
                    const ProfilePage(uid: ''),
                  ],
                ),
              ),
              _buildBottomNav(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplore() {
    if (_isLoadingInitialInteractions) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profilesError != null && _profileDocs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_profilesError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _loadMoreProfiles(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Filter locally based on current session's interacted users
    final docs = _profileDocs
        .where((doc) {
          return (currentUserId == null || doc.id != currentUserId) &&
              (doc.data()['type'] as String?) != 'staff' &&
              !_interactedUserIds.contains(doc.id);
        })
        .toList(growable: false);

    final profiles = <UserProfile>[
      for (var i = 0; i < docs.length; i++) _mapDocToProfile(docs[i], i + 1),
    ];
    _visibleProfiles = profiles;

    if (currentIndex >= profiles.length && profiles.isNotEmpty) {
      currentIndex = 0;
    }

    if (profiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'No hay mas perfiles nuevos por ahora.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoadingProfiles ? null : _loadMoreProfiles,
                icon: _isLoadingProfiles
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more),
                label: Text(
                  _hasMoreProfiles
                      ? 'Cargar mas perfiles'
                      : 'No hay perfiles disponibles',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final safeIndex = currentIndex % profiles.length;
    final currentProfile = profiles[safeIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                if (_dragDownProgress > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 5 * (_dragDownProgress / 100),
                        sigmaY: 5 * (_dragDownProgress / 100),
                      ),
                      child: Container(
                        color: AppColors.background.withOpacity(
                          0.2 * (_dragDownProgress / 100),
                        ),
                      ),
                    ),
                  ),
                SwipeableCard(
                  key: ValueKey('$safeIndex-${currentProfile.uid}'),
                  profile: currentProfile,
                  currentUserProfile: _currentUserProfile,
                  showHints: _showCardHints,
                  onDismissHints: () {
                    if (!_showCardHints) return;
                    setState(() {
                      _showCardHints = false;
                    });
                  },
                  onSwipeLeft: () =>
                      _handlePass(currentProfile, profiles.length),
                  onSwipeRight: () =>
                      _handleLike(currentProfile, profiles.length),
                  onDragDownProgress: (progress) =>
                      setState(() => _dragDownProgress = progress),
                  calculateCompatibility: _calculateCompatibility,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) => setState(() => _selectedNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      backgroundColor: AppColors.surface,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Mensajes',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Eventos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
