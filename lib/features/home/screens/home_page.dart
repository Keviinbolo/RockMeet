import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:RockMeet/core/models/user_profile.dart';
import 'package:RockMeet/features/events/screens/event_screen.dart';
import 'package:RockMeet/features/like/screens/like_page.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'package:RockMeet/core/services/chat_service.dart';
import 'package:RockMeet/features/profile/screens/Perfil.dart';
import 'package:RockMeet/features/chat/screens/chat_page.dart';
import 'package:RockMeet/features/settings/screens/ajustes.dart';
import 'package:RockMeet/core/widgets/match_animation_widget.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';
import 'package:RockMeet/core/services/profile_service.dart';

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
  static const String _fallbackPhotoUrl =
      'https://images.unsplash.com/photo-1521119989659-a83eee488004?q=80&w=1080';

  @override
  void initState() {
    super.initState();
    _initInteractionsAndLoadProfiles();
  }

  Future<void> _initInteractionsAndLoadProfiles() async {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('interactions')
            .where('fromUserId', isEqualTo: currentUserId)
            .get();
        _interactedUserIds = snapshot.docs
            .map((doc) => doc.data()['toUserId'] as String?)
            .whereType<String>()
            .toSet();
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

  // Removed _interactionsStream as we now use local Set for current session

  Future<void> _saveInteraction({
    required UserProfile profile,
    required String type,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    _interactedUserIds.add(profile.uid);

    final interactionId = '${currentUser.uid}_${profile.uid}';
    await FirebaseFirestore.instance
        .collection('interactions')
        .doc(interactionId)
        .set({
          'fromUserId': currentUser.uid,
          'toUserId': profile.uid,
          'type': type,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<bool> _isMutualLike(UserProfile profile) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;

    final inverseId = '${profile.uid}_${currentUser.uid}';
    final inverseDoc = await FirebaseFirestore.instance
        .collection('interactions')
        .doc(inverseId)
        .get();

    if (!inverseDoc.exists) {
      return false;
    }

    final data = inverseDoc.data();
    return data != null && data['type'] == 'like';
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
      final firestore = FirebaseFirestore.instance;

      // Interacciones que YO envié (likes/passes a otros)
      final sentSnap = await firestore
          .collection('interactions')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      // Interacciones que OTROS me enviaron a mí
      final receivedSnap = await firestore
          .collection('interactions')
          .where('toUserId', isEqualTo: currentUserId)
          .get();

      // Unir ambos resultados evitando duplicados (un doc podría coincidir en ambas queries si alguien
      // tiene el mismo UID en from y to, aunque eso no debería ocurrir)
      final allDocs = {
        for (final d in sentSnap.docs) d.id: d,
        for (final d in receivedSnap.docs) d.id: d,
      }.values.toList();

      // Eliminar en batches de 450 (el límite de Firestore es 500 por batch)
      for (var i = 0; i < allDocs.length; i += 450) {
        final batch = firestore.batch();
        for (final doc in allDocs.skip(i).take(450)) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      // Resetear contadores propios a 0
      await firestore.collection('users').doc(currentUserId).update({
        'likes': 0,
        'friends': 0,
      });

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

    // Incrementar likes: no crítico, no bloquea el flujo
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
      // Contadores de amigos: no críticos, no bloquean el modal
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
            // El botón del modal ya invocó Navigator.pop; aquí solo cambiamos de pestaña
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
                title: Text("RockMeet", style: AppTextStyles.headlineSmall),
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

class SwipeableCard extends StatefulWidget {
  final UserProfile profile;
  final bool showHints;
  final VoidCallback onDismissHints;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final Function(double) onDragDownProgress;

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.showHints,
    required this.onDismissHints,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onDragDownProgress,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with TickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  int _currentPhotoIndex = 0;
  bool _isAnimatingSwipe = false;

  bool _isFlipped = false;
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;

  late final AnimationController _swipeController;
  Animation<Offset>? _swipeAnimation;
  VoidCallback? _pendingSwipeAction;

  @override
  void initState() {
    super.initState();
    _swipeController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 260),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            final action = _pendingSwipeAction;
            _pendingSwipeAction = null;

            if (action != null) {
              action();
            }

            if (!mounted) return;
            setState(() {
              _position = Offset.zero;
              _isAnimatingSwipe = false;
            });
          }
        });

    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _swipeController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      _isFlipped ? _flipController.forward() : _flipController.reverse();
    });
  }

  void _nextPhoto() {
    final total = widget.profile.photos?.length;
    if (total! <= 1) return;
    if (_currentPhotoIndex >= total - 1) return;
    setState(() {
      _currentPhotoIndex = _currentPhotoIndex + 1;
    });
    widget.onDismissHints();
  }

  void _previousPhoto() {
    final total = widget.profile.photos?.length;
    if (total! <= 1) return;
    if (_currentPhotoIndex <= 0) return;
    setState(() {
      _currentPhotoIndex = _currentPhotoIndex - 1;
    });
    widget.onDismissHints();
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) {
    if (_isAnimatingSwipe || _isDragging) return;

    final dx = details.localPosition.dx;
    final width = constraints.maxWidth;
    if (width <= 0) {
      return;
    }

    final leftZone = width * 0.33;
    final rightZone = width * 0.67;

    if (dx < leftZone) {
      _previousPhoto();
      return;
    }
    if (dx > rightZone) {
      _nextPhoto();
      return;
    }
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  double get _likeProgress => _clamp01(_position.dx / 120);
  double get _nopeProgress => _clamp01((-_position.dx) / 120);

  void _animateSwipeOut({required bool like}) {
    if (_isAnimatingSwipe) return;

    final width = MediaQuery.of(context).size.width;
    final targetX = like ? width * 1.25 : -width * 1.25;
    final target = Offset(targetX, _position.dy * 0.15);

    _swipeAnimation = Tween<Offset>(begin: _position, end: target).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    _pendingSwipeAction = like ? widget.onSwipeRight : widget.onSwipeLeft;

    setState(() {
      _isAnimatingSwipe = true;
    });

    _swipeController.forward(from: 0);
  }

  void _animateBackToCenter() {
    if (_isAnimatingSwipe) return;

    _swipeAnimation = Tween<Offset>(begin: _position, end: Offset.zero).animate(
      CurvedAnimation(parent: _swipeController, curve: Curves.easeOutCubic),
    );

    setState(() {
      _isAnimatingSwipe = true;
    });

    _swipeController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _isAnimatingSwipe = false;
        _position = Offset.zero;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        if (_isAnimatingSwipe) return;
        setState(() => _isDragging = true);
      },
      onPanUpdate: (details) {
        if (_isAnimatingSwipe) return;
        setState(() {
          _position += details.delta;
          double dragProgress = (_position.dy > 0)
              ? math.min((_position.dy / 100) * 100, 100)
              : 0;
          widget.onDragDownProgress(dragProgress);
        });
      },
      onPanEnd: (details) {
        if (_isAnimatingSwipe) return;

        setState(() => _isDragging = false);

        final dx = _position.dx;
        final dy = _position.dy;
        const trigger = 90.0;

        if (dx.abs() >= trigger && dx.abs() > dy.abs()) {
          if (dx < 0) {
            widget.onDismissHints();
            _animateSwipeOut(like: false);
          } else {
            widget.onDismissHints();
            _animateSwipeOut(like: true);
          }
        } else if (dy > 100 && dx.abs() < 90 && !_isFlipped) {
          _toggleFlip();
          _animateBackToCenter();
        } else if (dy < -100 && dx.abs() < 90 && _isFlipped) {
          _toggleFlip();
          _animateBackToCenter();
        } else if (_position.dx < -140) {
          widget.onDismissHints();
          _animateSwipeOut(like: false);
        } else if (_position.dx > 140) {
          widget.onDismissHints();
          _animateSwipeOut(like: true);
        } else {
          _animateBackToCenter();
        }

        widget.onDragDownProgress(0);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([_swipeController, _flipController]),
        builder: (context, child) {
          final renderPosition = _isAnimatingSwipe && _swipeAnimation != null
              ? _swipeAnimation!.value
              : _position;

          final flipAngle = _flipAnimation.value * math.pi;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(renderPosition.dx, renderPosition.dy)
              ..rotateZ((renderPosition.dx / 20) * (math.pi / 180))
              ..rotateX(flipAngle),
            alignment: Alignment.center,
            child: flipAngle < (math.pi / 2)
                ? _buildCard()
                : Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateX(math.pi),
                    child: _buildBackCard(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCard() {
    final photos = widget.profile.photos;
    final photoCount = photos?.length ?? 1;
    final currentPhoto = photos != null && photos.isNotEmpty
        ? photos[_currentPhotoIndex.clamp(0, photos.length - 1)]
        : '';
    final likeProgress = _likeProgress;
    final nopeProgress = _nopeProgress;
    final categories = widget.profile.interestsDetail?.keys.toList()
        ?? widget.profile.interests
        ?? [];

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.18),
              blurRadius: 22,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Stack(
              fit: StackFit.expand,
              children: [
                // Foto a pantalla completa
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Image.network(
                    currentPhoto,
                    key: ValueKey(currentPhoto),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.surface,
                        child: const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white38,
                            size: 64,
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Viñeta superior sutil
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.center,
                        colors: [
                          Colors.black.withOpacity(0.45),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Gradiente inferior fuerte
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.42, 0.70, 1.0],
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.62),
                          Colors.black.withOpacity(0.94),
                        ],
                      ),
                    ),
                  ),
                ),

                // Indicadores de fotos
                Positioned(
                  top: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      for (var i = 0; i < photoCount; i++)
                        Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            height: 3,
                            margin: EdgeInsets.only(
                              right: i == photoCount - 1 ? 0 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: i == _currentPhotoIndex
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Badge NOPE
                Positioned(
                  left: 14,
                  top: 32,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 90),
                    opacity: nopeProgress,
                    child: Transform.rotate(
                      angle: -0.20,
                      child: _buildBadge("NOPE", AppColors.error),
                    ),
                  ),
                ),

                // Badge LIKE
                Positioned(
                  right: 14,
                  top: 32,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 90),
                    opacity: likeProgress,
                    child: Transform.rotate(
                      angle: 0.20,
                      child: _buildBadge("LIKE", AppColors.success),
                    ),
                  ),
                ),

                // Info inferior: nombre, edad e intereses
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Expanded(
                              child: Text(
                                widget.profile.name,
                                style: AppTextStyles.displaySmall.copyWith(
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.7),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 8,
                                  sigmaY: 8,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    '${widget.profile.age}',
                                    style: AppTextStyles.titleLarge.copyWith(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (categories.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          _buildInterestChips(categories),
                        ],
                      ],
                    ),
                  ),
                ),

                // Detector de taps para navegar fotos
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) => _handleTapUp(details, constraints),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2.5),
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withOpacity(0.35),
      ),
      child: Text(
        text,
        style: AppTextStyles.labelLarge.copyWith(
          color: color,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildInterestChips(List<String> interests) {
    final shown = interests.take(4).toList();
    final extra = interests.length - 4;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final interest in shown) _buildFrontChip(interest),
        if (extra > 0) _buildFrontChip('+$extra', isCounter: true),
      ],
    );
  }

  Widget _buildFrontChip(String label, {bool isCounter = false}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isCounter
                ? Colors.white.withOpacity(0.12)
                : AppColors.primary.withOpacity(0.25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isCounter
                  ? Colors.white.withOpacity(0.28)
                  : AppColors.primary.withOpacity(0.6),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    final interestsDetail = widget.profile.interestsDetail;
    final interests = widget.profile.interests ?? [];
    final bio = widget.profile.bio;

    return SizedBox.expand(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.surface,
              const Color(0xFF1A0F1F),
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.14),
              blurRadius: 22,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cabecera
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppColors.gradientPrimary,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.person_search,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.name,
                        style: AppTextStyles.titleLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Intereses y detalles',
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 14),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bio != null && bio.isNotEmpty) ...[
                      Text('Bio', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 6),
                      Text(
                        bio,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    Text('Intereses', style: AppTextStyles.labelLarge),
                    const SizedBox(height: 10),

                    if (interestsDetail != null && interestsDetail.isNotEmpty)
                      _buildBackInterestCategories(interestsDetail)
                    else if (interests.isNotEmpty)
                      _buildBackInterestChips(interests)
                    else
                      Text(
                        'No se han especificado intereses.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textHint,
                        ),
                      ),

                    if (widget.profile.twitter != null ||
                        widget.profile.instagram != null ||
                        widget.profile.tiktok != null) ...[
                      const SizedBox(height: 18),
                      Text('Redes sociales', style: AppTextStyles.labelLarge),
                      const SizedBox(height: 8),
                      _buildSocialLinks(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            ElevatedButton.icon(
              onPressed: _toggleFlip,
              icon: const Icon(Icons.keyboard_arrow_up, size: 20),
              label: const Text('Volver a la foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackInterestCategories(Map<String, List<String>> detail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: detail.entries.map((entry) {
        final category = entry.key;
        final subs = entry.value;
        final color = _interestColor(category);
        final icon = _interestIcon(category);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              if (subs.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: subs
                      .map(
                        (sub) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: color.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            sub,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: color.withOpacity(0.85),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBackInterestChips(List<String> interests) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: interests.map((interest) {
        final color = _interestColor(interest);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.5), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_interestIcon(interest), size: 13, color: color),
              const SizedBox(width: 5),
              Text(
                interest,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSocialLinks() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (widget.profile.twitter != null)
          _buildSocialChip(
            'X · ${widget.profile.twitter}',
            Icons.alternate_email,
            const Color(0xFF1DA1F2),
          ),
        if (widget.profile.instagram != null)
          _buildSocialChip(
            'IG · ${widget.profile.instagram}',
            Icons.camera_alt_outlined,
            const Color(0xFFE1306C),
          ),
        if (widget.profile.tiktok != null)
          _buildSocialChip(
            'TikTok · ${widget.profile.tiktok}',
            Icons.music_note,
            Colors.white,
          ),
      ],
    );
  }

  Widget _buildSocialChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: Colors.white.withOpacity(0.85),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Color _interestColor(String interest) {
    final l = interest.toLowerCase();
    if (l.contains('músi') || l.contains('musi') || l.contains('rock') || l.contains('metal') || l.contains('banda')) {
      return const Color(0xFF9C27B0);
    }
    if (l.contains('deport') || l.contains('fútbol') || l.contains('futbol') || l.contains('gym') || l.contains('ejercicio')) {
      return const Color(0xFF4CAF50);
    }
    if (l.contains('pelí') || l.contains('peli') || l.contains('cine') || l.contains('serie') || l.contains('anime')) {
      return const Color(0xFF2196F3);
    }
    if (l.contains('viaje') || l.contains('travel') || l.contains('aventura')) {
      return const Color(0xFF00BCD4);
    }
    if (l.contains('lectura') || l.contains('libro') || l.contains('leer')) {
      return const Color(0xFFFF9800);
    }
    if (l.contains('arte') || l.contains('dibujo') || l.contains('diseño') || l.contains('fotog')) {
      return const Color(0xFFE91E63);
    }
    if (l.contains('tecno') || l.contains('progra') || l.contains('código') || l.contains('codigo')) {
      return const Color(0xFF00E5FF);
    }
    if (l.contains('juego') || l.contains('gaming') || l.contains('videojuego')) {
      return const Color(0xFF8BC34A);
    }
    return AppColors.primary;
  }

  IconData _interestIcon(String interest) {
    final l = interest.toLowerCase();
    if (l.contains('músi') || l.contains('musi') || l.contains('rock') || l.contains('metal') || l.contains('banda')) {
      return Icons.music_note;
    }
    if (l.contains('deport') || l.contains('fútbol') || l.contains('futbol') || l.contains('gym')) {
      return Icons.sports_soccer;
    }
    if (l.contains('pelí') || l.contains('peli') || l.contains('cine') || l.contains('serie') || l.contains('anime')) {
      return Icons.movie;
    }
    if (l.contains('viaje') || l.contains('travel') || l.contains('aventura')) {
      return Icons.flight;
    }
    if (l.contains('lectura') || l.contains('libro') || l.contains('leer')) {
      return Icons.menu_book;
    }
    if (l.contains('arte') || l.contains('dibujo') || l.contains('diseño') || l.contains('fotog')) {
      return Icons.brush;
    }
    if (l.contains('tecno') || l.contains('progra') || l.contains('código') || l.contains('codigo')) {
      return Icons.computer;
    }
    if (l.contains('juego') || l.contains('gaming') || l.contains('videojuego')) {
      return Icons.sports_esports;
    }
    return Icons.interests;
  }
}

class _NavHintChip extends StatelessWidget {
  const _NavHintChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 2),
            Text(
              text,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
