import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/events/screens/event_screen.dart';
import 'package:myapp/features/like/screens/like_page.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:myapp/core/services/chat_service.dart';
import 'package:myapp/features/profile/screens/Perfil.dart';
import 'package:myapp/features/chat/screens/chat_page.dart';
import 'package:myapp/features/settings/screens/ajustes.dart';
import 'package:myapp/core/widgets/match_animation_widget.dart';

import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/config/Theme/constants/text_styles.dart';

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
  List<Profile> _visibleProfiles = [];
  String? _pendingChatPeerUid;
  String? _pendingChatPeerName;
  String? _pendingChatPeerAvatarUrl;
  static const String _fallbackPhotoUrl =
      'https://images.unsplash.com/photo-1521119989659-a83eee488004?q=80&w=1080';

  @override
  void initState() {
    super.initState();
    _loadMoreProfiles(reset: true);
  }

  Query<Map<String, dynamic>> _profilesBaseQuery() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy(FieldPath.documentId)
        .limit(_profilesPageSize);
  }

  Profile _mapDocToProfile(
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
    final gallery =
        (data['gallery'] as List?)?.whereType<String>().toList() ?? <String>[];
    final photoUrl = (data['photoURL'] as String?)?.trim();
    final parsedAge = age is int ? age : int.tryParse('$age');
    final safeAge = (parsedAge != null && parsedAge >= 18 && parsedAge <= 99)
        ? parsedAge
        : 18;

    final detailsParts = <String>[];
    if (bio != null && bio.isNotEmpty) {
      detailsParts.add(bio);
    }
    if (parsedAge != null) {
      detailsParts.add('Edad: $safeAge');
    }
    if (interests.isNotEmpty) {
      detailsParts.add('Intereses: ${interests.join(', ')}');
    }
    if (twitter != null && twitter.isNotEmpty) {
      detailsParts.add('X/Twitter: $twitter');
    }
    if (instagram != null && instagram.isNotEmpty) {
      detailsParts.add('Instagram: $instagram');
    }
    if (tiktok != null && tiktok.isNotEmpty) {
      detailsParts.add('TikTok: $tiktok');
    }

    final details = detailsParts.isNotEmpty
        ? detailsParts.join('\n\n')
        : 'Este usuario aun no ha completado su perfil.';

    final photos = <String>{
      if (photoUrl != null && photoUrl.isNotEmpty) photoUrl,
      ...gallery.map((url) => url.trim()).where((url) => url.isNotEmpty),
    }.toList(growable: false);

    return Profile(
      id: index,
      uid: doc.id,
      name: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Usuario',
      age: safeAge,
      photos: photos.isNotEmpty ? photos : <String>[_fallbackPhotoUrl],
      bio: details,
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
            if (!knownIds.contains(doc.id)) {
              _profileDocs.add(doc);
            }
          }
          _lastProfileDoc = docs.last;
          _hasMoreProfiles = docs.length == _profilesPageSize;
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

  Stream<QuerySnapshot<Map<String, dynamic>>> _interactionsStream() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Stream<QuerySnapshot<Map<String, dynamic>>>.empty();
    }

    return FirebaseFirestore.instance
        .collection('interactions')
        .where('fromUserId', isEqualTo: currentUserId)
        .snapshots();
  }

  Future<void> _saveInteraction({
    required Profile profile,
    required String type,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

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

  Future<bool> _isMutualLike(Profile profile) async {
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

  Future<void> _prepareChatForMatch(Profile profile) async {
    await ChatService.instance.ensureDirectChat(
      peerUid: profile.uid,
      peerName: profile.name,
      peerAvatarUrl: profile.photos.first,
    );

    if (!mounted) return;
    setState(() {
      _pendingChatPeerUid = profile.uid;
      _pendingChatPeerName = profile.name;
      _pendingChatPeerAvatarUrl = profile.photos.first;
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
              title: const Text('Reiniciar perfiles'),
              content: const Text(
                'Se eliminaran tus likes/passes guardados y volveras a ver perfiles ya evaluados.\n\n¿Quieres continuar?',
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

    setState(() {
      _isResettingInteractions = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('interactions')
          .where('fromUserId', isEqualTo: currentUserId)
          .get();

      final docs = snapshot.docs;
      for (var i = 0; i < docs.length; i += 450) {
        final batch = FirebaseFirestore.instance.batch();
        final chunk = docs.skip(i).take(450);
        for (final doc in chunk) {
          batch.delete(doc.reference);
        }
        await batch.commit();
      }

      if (!mounted) return;
      setState(() {
        currentIndex = 0;
        _dragDownProgress = 0;
      });
      await _loadMoreProfiles(reset: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Interacciones reiniciadas.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo reiniciar interacciones.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isResettingInteractions = false;
        });
      }
    }
  }

  Future<void> _handlePass(Profile currentProfile, int profilesLength) async {
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

  Future<void> _handleLike(Profile currentProfile, int profilesLength) async {
    // 1. Forzamos que sea true para que la animación salte SIEMPRE
    bool isMutualLike = true;

    try {
      // Guardamos la interacción en Firebase (opcional, pero mejor dejarlo para que el perfil no repita)
      await _saveInteraction(profile: currentProfile, type: 'like');

      // Intentamos preparar el chat (aunque no sea mutuo real, para que el modal tenga datos)
      await _prepareChatForMatch(currentProfile);
    } catch (e) {
      print("Error guardando interacción: $e");
    }

    // 2. Al ser isMutualLike = true, entrará aquí SIEMPRE
    if (isMutualLike) {
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

  void _showMatchModal(Profile currentProfile, int profilesLength) {
    if (profilesLength == 0) return;
    final imageForModal = currentProfile.photos
        .map((url) => url.trim())
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
            Navigator.of(context).pop();
            setState(() {
              _selectedNavIndex = 2; // Redirige a mensajes
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
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _interactionsStream(),
      builder: (context, interactionsSnapshot) {
        if (interactionsSnapshot.connectionState == ConnectionState.waiting) {
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

        final interactedUserIds =
            interactionsSnapshot.data?.docs
                .map((doc) => doc.data()['toUserId'] as String?)
                .whereType<String>()
                .toSet() ??
            <String>{};

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final docs = _profileDocs
            .where((doc) {
              return (currentUserId == null || doc.id != currentUserId) &&
                  (doc.data()['type'] as String?) != 'staff' &&
                  !interactedUserIds.contains(doc.id);
            })
            .toList(growable: false);

        final profiles = <Profile>[
          for (var i = 0; i < docs.length; i++)
            _mapDocToProfile(docs[i], i + 1),
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
                      key: ValueKey('$safeIndex-${currentProfile.id}'),
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
              const SizedBox(height: 20),
              Column(
                children: [
                  _buildActionButtons(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isLoadingProfiles ? null : _loadMoreProfiles,
                    icon: _isLoadingProfiles
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more),
                    label: const Text('Cargar mas'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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

  Widget _buildActionButtons() {
    final hasProfiles = _visibleProfiles.isNotEmpty;
    final safeIndex = hasProfiles ? currentIndex % _visibleProfiles.length : 0;
    final currentProfile = hasProfiles ? _visibleProfiles[safeIndex] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(
          Icons.close,
          AppColors.error,
          hasProfiles
              ? () {
                  _handlePass(currentProfile!, _visibleProfiles.length);
                }
              : () {},
        ),
        _roundButton(
          Icons.favorite,
          AppColors.success,
          hasProfiles
              ? () {
                  _handleLike(currentProfile!, _visibleProfiles.length);
                }
              : () {},
        ),
      ],
    );
  }

  Widget _roundButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final Profile profile;
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
    final total = widget.profile.photos.length;
    if (total <= 1) return;
    if (_currentPhotoIndex >= total - 1) return;
    setState(() {
      _currentPhotoIndex = _currentPhotoIndex + 1;
    });
    widget.onDismissHints();
  }

  void _previousPhoto() {
    final total = widget.profile.photos.length;
    if (total <= 1) return;
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

  // --- FRENTE DE LA TARJETA (Ajustado para evitar overflow) ---
  Widget _buildCard() {
    final photos = widget.profile.photos;
    final titleText = '${widget.profile.name}, ${widget.profile.age}';
    final photoCount = photos.length;
    final currentPhoto = photos[_currentPhotoIndex.clamp(0, photos.length - 1)];
    final likeProgress = _likeProgress;
    final nopeProgress = _nopeProgress;

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.24),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        // LayoutBuilder y Column Flexible para evitar el error de RenderFlex overflow
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                // 1. Título
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          titleText,
                          style: AppTextStyles.displayMedium,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Imagen (Flexible para adaptarse al tamaño de pantalla)
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Image.network(
                              currentPhoto,
                              key: ValueKey(currentPhoto),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    color: Colors.black12,
                                    child: const Icon(Icons.broken_image),
                                  ),
                            ),
                          ),
                          // Gradiente Inferior
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.35),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // Indicadores de fotos (Barras blancas arriba)
                          Positioned(
                            top: 10,
                            left: 10,
                            right: 10,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: Row(
                                children: [
                                  for (var i = 0; i < photoCount; i++)
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        height: 3,
                                        margin: EdgeInsets.only(
                                          right: i == photoCount - 1 ? 0 : 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: i == _currentPhotoIndex
                                              ? Colors.white
                                              : Colors.white.withOpacity(0.35),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Detector de Taps para navegar fotos
                          Positioned.fill(
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTapUp: (details) =>
                                  _handleTapUp(details, constraints),
                            ),
                          ),
                          // Labels LIKE/NOPE
                          Positioned(
                            left: 14,
                            top: 22,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 90),
                              opacity: nopeProgress,
                              child: Transform.rotate(
                                angle: -0.20,
                                child: _buildBadge("NOPE", AppColors.error),
                              ),
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 22,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 90),
                              opacity: likeProgress,
                              child: Transform.rotate(
                                angle: 0.20,
                                child: _buildBadge("LIKE", AppColors.success),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Detalles del perfil (CON SCROLL para evitar el error de overflow)
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.showHints)
                          Text(
                            'Desliza derecha para match o izquierda para rechazar.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        const SizedBox(height: 10),
                        Text(
                          'Detalles del perfil',
                          style: AppTextStyles.titleMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.profile.bio,
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(10),
        color: Colors.black.withOpacity(0.25),
      ),
      child: Text(text, style: AppTextStyles.labelLarge.copyWith(color: color)),
    );
  }

  Widget _buildBackCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(Icons.person_search, size: 50, color: AppColors.primary),
          const SizedBox(height: 16),
          Text(
            "Intereses y Detalles",
            style: AppTextStyles.headlineSmall?.copyWith(
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                widget.profile.bio,
                style: AppTextStyles.bodyLarge?.copyWith(height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _toggleFlip,
            icon: const Icon(Icons.arrow_upward),
            label: const Text("Volver a la foto"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
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

class Profile {
  final int id;
  final String uid;
  final String name;
  final int age;
  final List<String> photos;
  final String bio;

  Profile({
    required this.id,
    required this.uid,
    required this.name,
    required this.age,
    required this.photos,
    required this.bio,
  });
}
