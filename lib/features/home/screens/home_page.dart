import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;

import 'package:myapp/features/profile/screens/Perfil.dart';
import 'package:myapp/features/chat/screens/chat_page.dart';
import 'package:myapp/features/settings/screens/ajustes.dart';
// CAMBIO 1: Importar el widget de animación de match
import 'package:myapp/core/widgets/match_animation_widget.dart';

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

  final List<Profile> profiles = [
    Profile(
      id: 1,
      name: "Sofia",
      age: 24,
      photos: [
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1080",
      ],
      bio:
          "Amante de la aventura 🏔️\n\nMe encanta el senderismo y la fotografía de paisajes. Busco a alguien para compartir rutas de montaña los fines de semana.",
    ),
    Profile(
      id: 2,
      name: "Carlos",
      age: 27,
      photos: [
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=1080",
      ],
      bio:
          "Fotógrafo y viajero ✈️\n\nSiempre con la maleta lista. Si te gusta el café recién hecho y las puestas de sol, nos llevaremos muy bien.",
    ),
  ];

  void _nextProfile() {
    setState(() {
      currentIndex = (currentIndex + 1) % profiles.length;
      _isProfileFlipped = false;
      _dragDownProgress = 0;
    });
  }

  // CAMBIO 2: Agregar función para mostrar el modal de match
  void _showMatchModal() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return MatchModal(
          profile: {
            'name': profiles[currentIndex].name,
            'image': profiles[currentIndex].photos[0],
          },
          onClose: () {
            Navigator.of(context).pop();
            _nextProfile();
          },
        );
      },
    );
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
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                title: const Text("RockMeet"),
                centerTitle: true,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings),
                  ),
                ],
              ),

              Expanded(
                child: _selectedNavIndex == 0
                    ? _buildExplore()
                    : _selectedNavIndex == 3
                    ? const ProfilePage()
                    : _selectedNavIndex == 2
                    ? const ChatScreen()
                    : const Center(child: Text("Próximamente")),
              ),
              _buildBottomNav(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplore() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Blur effect layer - solo durante el arrastre
                if (_dragDownProgress > 0)
                  Positioned.fill(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 5 * (_dragDownProgress / 100),
                        sigmaY: 5 * (_dragDownProgress / 100),
                      ),
                      child: Container(
                        color: Colors.black.withOpacity(
                          0.2 * (_dragDownProgress / 100),
                        ),
                      ),
                    ),
                  ),
                // Tarjeta encima (no afectada por blur)
                SwipeableCard(
                  key: ValueKey(currentIndex),
                  profile: profiles[currentIndex],
                  onSwipeLeft: _nextProfile,
                  // CAMBIO 3: Cambiar onSwipeRight para mostrar el modal de match
                  onSwipeRight: _showMatchModal,
                  onSwipeUp: _nextProfile,
                  onFlipChanged: (isFlipped) =>
                      setState(() => _isProfileFlipped = isFlipped),
                  onDragDownProgress: (progress) =>
                      setState(() => _dragDownProgress = progress),
                ),
                // Detectar clic fuera para voltear
                if (_isProfileFlipped)
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: _toggleCardFlip,
                      child: Container(
                        color: Colors.transparent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Stack(
            children: [
              // Action buttons with animation
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
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedNavIndex,
      onTap: (index) => setState(() => _selectedNavIndex = index),
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.purple,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble),
          label: 'Mensajes',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _roundButton(Icons.close, Colors.red, _nextProfile),
        ElevatedButton(
          onPressed: _nextProfile,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.blue,
            shape: const StadiumBorder(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text(
            "GROUP",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        // CAMBIO 4: Cambiar el botón de corazón para mostrar el modal de match
        _roundButton(Icons.favorite, Colors.green, _showMatchModal),
      ],
    );
  }

  Widget _roundButton(IconData icon, Color color, VoidCallback onPressed) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
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

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
    required this.onFlipChanged,
    required this.onDragDownProgress,
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
          // Calcular el progreso del arrastre hacia abajo (0-100)
          double dragProgress = (_position.dy > 0)
              ? math.min((_position.dy / 100) * 100, 100)
              : 0;
          // Notificar el progreso del arrastre hacia abajo
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
          // GESTO ABAJO: Activa el volteo
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
          // Calculamos la rotación en Y (volteo horizontal sobre el eje central)
          final angleFlip = _flipController.value * math.pi;

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // Perspectiva para el efecto 3D
              ..translate(_position.dx, _position.dy)
              ..rotateZ(angleDrag)
              ..rotateY(angleFlip),
            alignment: Alignment.center,
            child: angleFlip < math.pi / 2
                ? _buildFront()
                : Transform(
                    // Invertimos el reverso para que el texto no se vea al revés
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
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
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
                    colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    "Desliza abajo para detalles",
                    style: TextStyle(color: Colors.white70),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.person_pin, size: 60, color: Colors.purple),
            const SizedBox(height: 10),
            Text(
              widget.profile.name,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 30),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  widget.profile.bio,
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _toggleFlip,
              icon: const Icon(Icons.flip_to_front, color: Colors.purple),
              label: const Text(
                "Cerrar info",
                style: TextStyle(color: Colors.purple),
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
  final String name;
  final int age;
  final List<String> photos;
  final String bio;
  Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.photos,
    required this.bio,
  });
}
