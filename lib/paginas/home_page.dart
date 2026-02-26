import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:myapp/config/Theme/constants/colors.dart';
import 'package:myapp/paginas/Perfil.dart';
import 'package:myapp/paginas/ajustes.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentIndex = 0;
  int _selectedNavIndex = 0;

  final List<Profile> profiles = [
    Profile(
      id: 1, 
      name: "Sofia", 
      age: 24, 
      photos: [
        "https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=1080",
        "https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=1080",
        "https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=1080",
      ], 
      bio: "Amante de la aventura 🏔️"
    ),
    Profile(
      id: 2, 
      name: "Carlos", 
      age: 27, 
      photos: [
        "https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=1080",
        "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=1080",
      ], 
      bio: "Fotógrafo y viajero ✈️"
    ),
  ];

  void _nextProfile() {
    setState(() {
      currentIndex = (currentIndex + 1) % profiles.length;
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
    );
  }

  Widget _buildExplore() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Expanded(
            child: SwipeableCard(
              key: ValueKey(currentIndex),
              profile: profiles[currentIndex],
              onSwipeLeft: _nextProfile,
              onSwipeRight: _nextProfile,
              onSwipeUp: _nextProfile,
            ),
          ),
          const SizedBox(height: 20),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(onPressed: _nextProfile, icon: const Icon(Icons.close, color: AppColors.error, size: 35)),
        ElevatedButton(onPressed: _nextProfile, child: const Text("GROUP")),
        IconButton(onPressed: _nextProfile, icon: const Icon(Icons.favorite, color: AppColors.success, size: 35)),
      ],
    );
  }
}

class SwipeableCard extends StatefulWidget {
  final Profile profile;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final VoidCallback onSwipeUp;

  const SwipeableCard({
    super.key,
    required this.profile,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onSwipeUp,
  });

  @override
  State<SwipeableCard> createState() => _SwipeableCardState();
}

class _SwipeableCardState extends State<SwipeableCard> {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  int _currentImageIndex = 0;
  final PageController _pageController = PageController();

  void _prevImage() {
    if (_currentImageIndex > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  void _nextImage() {
    if (_currentImageIndex < widget.profile.photos.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 200), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    double angle = (_position.dx / 20) * (math.pi / 180);

    return GestureDetector(
      onPanStart: (_) => setState(() => _isDragging = true),
      onPanUpdate: (details) => setState(() => _position += details.delta),
      onPanEnd: (details) {
        setState(() => _isDragging = false);
        if (_position.dx < -150) widget.onSwipeLeft();
        else if (_position.dx > 150) widget.onSwipeRight();
        else if (_position.dy < -150) widget.onSwipeUp();
        else setState(() => _position = Offset.zero);
      },
      child: AnimatedContainer(
        duration: _isDragging ? Duration.zero : const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        transform: Matrix4.identity()
          ..translate(_position.dx, _position.dy)
          ..rotateZ(angle),
        child: _buildCardContent(),
      ),
    );
  }

  Widget _buildCardContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25.0),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Carrusel de imágenes
                PageView.builder(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(), // Desactivamos scroll manual para usar los clics
                  itemCount: widget.profile.photos.length,
                  onPageChanged: (index) => setState(() => _currentImageIndex = index),
                  itemBuilder: (context, index) => Image.network(widget.profile.photos[index], fit: BoxFit.cover),
                ),
                // Zonas de clic (Lados)
                Row(
                  children: [
                    Expanded(child: GestureDetector(onTap: _prevImage, child: Container(color: Colors.transparent))),
                    Expanded(child: GestureDetector(onTap: _nextImage, child: Container(color: Colors.transparent))),
                  ],
                ),
                // Indicadores (Barras superiores)
                Positioned(
                  top: 15, left: 10, right: 10,
                  child: Row(
                    children: List.generate(widget.profile.photos.length, (index) {
                      return Expanded(
                        child: Container(
                          height: 4, margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: _currentImageIndex == index ? Colors.white : Colors.white.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Overlays de acción (Aparecen al arrastrar)
                if (_position.dx > 50) _buildOverlayText("LIKE", AppColors.success, Alignment.topLeft),
                if (_position.dx < -50) _buildOverlayText("NOPE", AppColors.error, Alignment.topRight),
                if (_position.dy < -50 && _position.dx.abs() < 50) _buildOverlayText("GROUP", AppColors.secondary, Alignment.bottomCenter),
              ],
            ),
          ),
        ),
        const SizedBox(height: 15),
        Text("${widget.profile.name}, ${widget.profile.age}", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(widget.profile.bio, style: const TextStyle(fontSize: 16, color: Colors.grey)),
      ],
    );
  }

  Widget _buildOverlayText(String text, Color color, Alignment alignment) {
    return Align(
      alignment: alignment,
      child: IgnorePointer( // Importante para que no bloquee los clics de las fotos
        child: Container(
          margin: const EdgeInsets.all(40),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: 4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: TextStyle(color: color, fontSize: 32, fontWeight: FontWeight.bold)),
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
  Profile({required this.id, required this.name, required this.age, required this.photos, required this.bio});
}