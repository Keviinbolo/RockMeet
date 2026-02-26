import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/paginas/Perfil.dart';
import 'package:myapp/paginas/ajustes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RockMeet',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  bool _isProfileFlipped = false;
  late AnimationController _flipController;

  final List<Profile> profiles = [
    Profile(
      name: "Sofia",
      age: 24,
      photo: "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1080",
      interests: ["Senderismo", "Fotografía", "Rock", "Viajes", "Aventura"],
      bio: "Amante de la aventura 🏔️. Me encanta el senderismo y la fotografía de paisajes.",
    ),
    Profile(
      name: "Carlos",
      age: 27,
      photo: "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=1080",
      interests: ["Gimnasio", "Cocina", "Ciclismo"],
      bio: "Siempre con la maleta lista para una nueva ruta.",
    ),
  ];

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _toggleFlip() {
    if (_isProfileFlipped) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() {
      _isProfileFlipped = !_isProfileFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("RockMeet"), centerTitle: true, actions: [
        IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())), icon: const Icon(Icons.settings))
      ],),
      body: _selectedNavIndex == 0
          ? _buildExplore()
          : _selectedNavIndex == 3
              ? const ProfilePage()
              : const Center(child: Text("Próximamente")),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Explorar'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Likes'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Mensajes'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: SwipeableCard(
              key: ValueKey(currentIndex),
              profile: profiles[currentIndex],
              isFlipped: _isProfileFlipped,
              flipController: _flipController,
              onFlip: _toggleFlip,
              onNext: () {
                _flipController.reset();
                setState(() {
                  currentIndex = (currentIndex + 1) % profiles.length;
                  _isProfileFlipped = false;
                });
              },
            ),
          ),
          if (!_isProfileFlipped)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _actionIcon(Icons.close, Colors.red),
                  _actionIcon(Icons.favorite, Colors.green),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.close) {
          setState(() {
            currentIndex = (currentIndex + 1) % profiles.length;
            _isProfileFlipped = false;
            _flipController.reset();
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }
}

class SwipeableCard extends StatefulWidget {
  final Profile profile;
  final bool isFlipped;
  final AnimationController flipController;
  final VoidCallback onFlip;
  final VoidCallback onNext;

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.isFlipped,
    required this.flipController,
    required this.onFlip,
    required this.onNext,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  Offset _position = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          _position += details.delta;
        });
      },
      onPanEnd: (details) {
        // Detectar deslizamiento hacia abajo para voltear
        if (_position.dy > 80) {
          widget.onFlip();
        }
        // Detectar deslizamiento horizontal para siguiente perfil
        else if (_position.dx.abs() > 100 && !widget.isFlipped) {
          widget.onNext();
        }
        
        // Resetear posición
        setState(() {
          _position = Offset.zero;
        });
      },
      child: AnimatedBuilder(
        animation: widget.flipController,
        builder: (context, child) {
          final angle = widget.flipController.value * math.pi;
          
          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.004)
              ..translate(_position.dx, _position.dy)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: angle < math.pi / 2 ? _buildFront() : _buildBack(),
          );
        },
      ),
    );
  }

  Widget _buildFront() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(widget.profile.photo),
            fit: BoxFit.cover,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
            ),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
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
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "⬇️ Desliza abajo",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Text(
              widget.profile.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.purple.shade400,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "INTERESES",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 15),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: widget.profile.interests.map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.purple.withOpacity(0.3)),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.purple,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

class Profile {
  final String name;
  final int age;
  final String photo;
  final List<String> interests;
  final String bio;

  Profile({
    required this.name,
    required this.age,
    required this.photo,
    required this.interests,
    required this.bio,
  });
}