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
  bool _isProfileFlipped = false;
  double _dragDownProgress = 0;
  List<Profile> _visibleProfiles = [];
  String? _pendingChatPeerUid;
  String? _pendingChatPeerName;
  String? _pendingChatPeerAvatarUrl;

  Stream<QuerySnapshot<Map<String, dynamic>>> _profilesStream() {
    return FirebaseFirestore.instance.collection('users').limit(50).snapshots();
  }

  Profile _mapDocToProfile(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
    int index,
  ) {
    final data = doc.data();

    final displayName = (data['displayName'] as String?)?.trim();
    final bio = (data['bio'] as String?)?.trim();
    final age = data['age'];
    final gallery =
        (data['gallery'] as List?)?.whereType<String>().toList() ?? <String>[];
    final photoUrl = (data['photoURL'] as String?)?.trim();

    final photos = <String>[
      if (photoUrl != null && photoUrl.isNotEmpty) photoUrl,
      ...gallery.where((url) => url.trim().isNotEmpty),
    ];

    return Profile(
      id: index,
      uid: doc.id,
      name: (displayName != null && displayName.isNotEmpty)
          ? displayName
          : 'Usuario',
      age: age is int ? age : int.tryParse('$age') ?? 18,
      photos: photos.isNotEmpty
          ? photos
          : <String>[
              'https://images.unsplash.com/photo-1521119989659-a83eee488004?q=80&w=1080',
            ],
      bio: (bio != null && bio.isNotEmpty)
          ? bio
          : 'Este usuario aun no ha agregado una biografia.',
    );
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
    var isMutualLike = false;

    try {
      await _saveInteraction(profile: currentProfile, type: 'like');
      isMutualLike = await _isMutualLike(currentProfile);

      if (isMutualLike) {
        await _prepareChatForMatch(currentProfile);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar la interacción.')),
        );
      }
      _nextProfile(profilesLength);
      return;
    }

    if (isMutualLike) {
      _showMatchModal(currentProfile, profilesLength);
      return;
    }

    _nextProfile(profilesLength);
  }

  void _nextProfile(int profilesLength) {
    if (profilesLength == 0) return;
    setState(() {
      currentIndex = (currentIndex + 1) % profilesLength;
      _isProfileFlipped = false;
      _dragDownProgress = 0;
    });
  }

  void _showMatchModal(Profile currentProfile, int profilesLength) {
    if (profilesLength == 0) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MatchModal(
          profile: {
            'name': currentProfile.name,
            'image': currentProfile.photos.first,
          },
          onSendMessage: () {
            Navigator.of(context).pop();
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

  // NUEVO: Función para manejar acciones del menú de la tarjeta
  void _handleCardMenuAction(String action, Profile profile) {
    switch (action) {
      case 'report':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Denunci usuario'),
            content: Text('¿Estás seguro de que quieres denunciar a ${profile.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Aquí iría la lógica de reporte
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Usuario reportado. Gracias por tu ayuda.')),
                  );
                  Navigator.pop(context);
                  _nextProfile(); // Opcional: pasar al siguiente perfil
                },
                child: const Text('Reportar'),
              ),
            ],
          ),
        );
        break;
      case 'block':
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bloquear usuario'),
            content: Text('¿Quieres bloquear a ${profile.name}? No volverás a ver su perfil.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  // Lógica de bloqueo
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${profile.name} ha sido bloqueado.')),
                  );
                  Navigator.pop(context);
                  _nextProfile();
                },
                child: const Text('Bloquear'),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _resetFlip() {
    setState(() {
      _isProfileFlipped = false;
      _dragDownProgress = 0;
    });
  }

  void _toggleCardFlip() {
    setState(() {
      _isProfileFlipped = false;
    });
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
                child: _selectedNavIndex == 0
                    ? _buildExplore()
                    : _selectedNavIndex == 1
                    ? const LikesPage()
                    : _selectedNavIndex == 2
                    ? ChatScreen(
                        key: ValueKey('chat-${_pendingChatPeerUid ?? 'none'}'),
                        initialPeerUid: _pendingChatPeerUid,
                        initialPeerName: _pendingChatPeerName,
                        initialPeerAvatarUrl: _pendingChatPeerAvatarUrl,
                      )
                    : _selectedNavIndex == 3
                    ? const EventScreen()
                    : _selectedNavIndex == 4
                    ? const ProfilePage()
                    : const Center(child: Text("Página no encontrada")),
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
      stream: _profilesStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'No se pudieron cargar perfiles.\n${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
        final docs =
            (snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where(
                  (doc) => currentUserId == null || doc.id != currentUserId,
                )
                .toList(growable: false);
        final profiles = <Profile>[
          for (var i = 0; i < docs.length; i++)
            _mapDocToProfile(docs[i], i + 1),
        ];
        _visibleProfiles = profiles;

        if (profiles.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Todavia no hay perfiles disponibles para mostrar.',
                textAlign: TextAlign.center,
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
                      onSwipeLeft: () =>
                          _handlePass(currentProfile, profiles.length),
                      onSwipeRight: () =>
                          _handleLike(currentProfile, profiles.length),
                      onSwipeUp: () => _nextProfile(profiles.length),
                      onFlipChanged: (isFlipped) =>
                          setState(() => _isProfileFlipped = isFlipped),
                      onDragDownProgress: (progress) =>
                          setState(() => _dragDownProgress = progress),
                    ),
                    if (_isProfileFlipped)
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _toggleCardFlip,
                          child: Container(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                SwipeableCard(
                  key: ValueKey(currentIndex),
                  profile: profiles[currentIndex],
                  onSwipeLeft: _nextProfile,
                  onSwipeRight: _showMatchModal,
                  onSwipeUp: _nextProfile,
                  onFlipChanged: (isFlipped) =>
                      setState(() => _isProfileFlipped = isFlipped),
                  onDragDownProgress: (progress) =>
                      setState(() => _dragDownProgress = progress),
                  // NUEVO: Pasamos el callback del menú
                  onMenuAction: (action) => _handleCardMenuAction(action, profiles[currentIndex]),
                ),
              ),
              const SizedBox(height: 20),
              Stack(
                children: [
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: _isProfileFlipped ? 0.0 : 1.0,
                    child: _buildActionButtons(),
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
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeUp;
  final Function(bool) onFlipChanged;
  final Function(double) onDragDownProgress;
  // NUEVO: Callback para acciones del menú de tres puntos
  final Function(String) onMenuAction;

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    required this.onFlipChanged,
    required this.onDragDownProgress,
    required this.onMenuAction, // NUEVO
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  bool _isFlipped = false;
  late AnimationController _flipController;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    setState(() {
      _isFlipped = !_isFlipped;
      _isFlipped ? _flipController.forward() : _flipController.reverse();
      widget.onFlipChanged(_isFlipped);
    });
  }

  @override
  Widget build(BuildContext context) {
    double angleDrag = (_position.dx / 20) * (math.pi / 180);

    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
          double dragProgress = (_position.dy > 0)
              ? math.min((_position.dy / 100) * 100, 100)
              : 0;
          widget.onDragDownProgress(dragProgress);
        });
      },
      onPanEnd: (details) {
        setState(() => _isDragging = false);

        if (_position.dx < -140) {
          widget.onSwipeLeft();
        } else if (_position.dx > 140) {
          widget.onSwipeRight();
        } else if (_position.dy < -140) {
          widget.onSwipeUp();
        } else if (_position.dy > 100) {
          _toggleFlip();
        }

        setState(() {
          _position = Offset.zero;
          widget.onDragDownProgress(0);
        });
      },
      child: AnimatedBuilder(
        animation: _flipController,
        builder: (context, child) {
          final angleFlip = _flipController.value * math.pi;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(_position.dx, _position.dy)
              ..rotateZ(angleDrag)
              ..rotateY(angleFlip),
            alignment: Alignment.center,
            child: angleFlip < math.pi / 2
                ? _buildFront()
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return AspectRatio(
      aspectRatio: 0.75,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          image: DecorationImage(
            image: NetworkImage(widget.profile.photos[0]),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      AppColors.background.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 20,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${widget.profile.name}, ${widget.profile.age}",
                    style: AppTextStyles.displayMedium,
                  ),
                  Text(
                    "Desliza abajo para detalles",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBack() {
    return AspectRatio(
      aspectRatio: 0.75,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.26),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // NUEVO: Botón de menú (tres puntos) en la esquina superior derecha
            Positioned(
              top: -10,
              right: -16,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: AppColors.textSecondary),
                onSelected: (value) {
                  widget.onMenuAction(value);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'report',
                    child: Text('Denunciar'),
                  ),
                  const PopupMenuItem(
                    value: 'block',
                    child: Text('Bloquear usuario'),
                  ),
                ],
              ),
            ),
            // Contenido principal centrado
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_pin,
                    size: 60,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.profile.name,
                    style: AppTextStyles.headlineSmall,
                  ),
                  const Divider(height: 30, color: AppColors.divider),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        widget.profile.bio,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: _toggleFlip,
                    icon: Icon(
                      Icons.flip_to_front,
                      color: AppColors.primary,
                    ),
                    label: Text(
                      "Cerrar info",
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
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