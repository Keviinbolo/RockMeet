import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/features/profile/interest_screen.dart';
import 'package:myapp/core/services/profile_service.dart';

// Datos del usuario (iniciales)
const String defaultAvatarUrl =
    'https://images.unsplash.com/photo-1543689604-6fe8dbcd1f59?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMHN0dWRlbnQlMjBwb3J0cmFpdCUyMGhhcHB5fGVufDF8fHx8MTc3MjEyMDc0MHww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral';

const List<String> profileImages = [
  'https://images.unsplash.com/photo-1584819332026-ac894ac5c26e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMHlvdW5nJTIwcGVyc29uJTIwb3V0ZG9vcnxlbnwxfHx8fDE3NzIxMjA5NzF8MA&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  'https://images.unsplash.com/photo-1744869985867-d23cc60e3625?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxzdHVkZW50JTIwbGlmZXN0eWxlJTIwY2FzdWFsfGVufDF8fHx8MTc3MjEyMDk3MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  'https://images.unsplash.com/photo-1768725845828-a74119dc4f34?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwZXJzb24lMjBob2JieSUyMGFjdGl2aXR5fGVufDF8fHx8MTc3MjEyMDk3MXww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  'https://images.unsplash.com/photo-1623790679957-5a20f98faef6?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHx5b3VuZyUyMGFkdWx0JTIwdHJhdmVsfGVufDF8fHx8MTc3MjEyMDk3Mnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
  'https://images.unsplash.com/photo-1709287253135-865c51892771?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMG5hdHVyZSUyMG91dGRvb3JzfGVufDF8fHx8MTc3MjEyMDk3Mnww&ixlib=rb-4.1.0&q=80&w=1080&utm_source=figma&utm_medium=referral',
];

class UserData {
  String name;
  String email;
  String bio;
  String twitter;
  String instagram;
  String tiktok;
  String likes;
  String matches;
  String activities;
  String friends; // Nuevo campo: total de amigos

  UserData({
    required this.name,
    required this.email,
    required this.bio,
    required this.twitter,
    required this.instagram,
    required this.tiktok,
    required this.likes,
    required this.matches,
    required this.activities,
    required this.friends,
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Perfil',
      debugShowCheckedModeBanner: false,
      home: ProfilePage(uid: ''),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required String uid});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isMenuOpen = false;
  late List<String> images;
  bool _isEditing = false;
  bool _isLoadingProfile = false;

  // Datos del usuario
  late UserData _userData;
  late List<Interest> _userInterests;
  late String _avatarUrl;

  // Amigos que sigue
  String _friendsCount = '0';

  // Controladores para edición
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;

  List<Interest> _buildInterestCatalog() {
    return [
      Interest(
        Icons.music_note,
        'Música',
        subInterests: ['Rock', 'Pop', 'Jazz', 'Electrónica', 'Hip-Hop'],
      ),
      Interest(
        Icons.sports_soccer,
        'Deporte',
        subInterests: ['Fútbol', 'Baloncesto', 'Tenis', 'Running', 'Natación'],
      ),
      Interest(
        Icons.movie,
        'Películas',
        subInterests: [
          'Acción',
          'Comedia',
          'Drama',
          'Ciencia Ficción',
          'Terror',
        ],
      ),
      Interest(
        Icons.book,
        'Lectura',
        subInterests: [
          'Ficción',
          'Misterio',
          'Fantasía',
          'Biografía',
          'Tecnología',
        ],
      ),
      Interest(
        Icons.travel_explore,
        'Viajar',
        subInterests: [
          'Playas',
          'Montañas',
          'Ciudades',
          'Aventura',
          'Cultural',
        ],
      ),
    ];
  }

  String _safeStatValue(dynamic value) {
    if (value == null) return '0';
    final parsed = int.tryParse('$value');
    if (parsed == null || parsed < 0) return '0';
    return parsed.toString();
  }

  String _textOrFallback(String? value, String fallback) {
    if (value == null) return fallback;
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  @override
  void initState() {
    super.initState();
    images = profileImages.take(3).toList();
    _avatarUrl = defaultAvatarUrl;

    // Inicializar con valores por defecto
    _userData = UserData(
      name: 'Usuario',
      email: FirebaseAuth.instance.currentUser?.email ?? '',
      bio: 'Completa tu perfil para que otros usuarios te conozcan mejor.',
      twitter: '',
      instagram: '',
      tiktok: '',
      likes: '0',
      matches: '0',
      activities: '0',
      friends: '0',
    );

    _userInterests = _buildInterestCatalog();

    _nameController = TextEditingController(text: _userData.name);
    _bioController = TextEditingController(text: _userData.bio);
    _twitterController = TextEditingController(text: _userData.twitter);
    _instagramController = TextEditingController(text: _userData.instagram);
    _tiktokController = TextEditingController(text: _userData.tiktok);

    _loadProfileFromFirestore();
  }

  Future<void> _loadProfileFromFirestore() async {
    setState(() => _isLoadingProfile = true);

    try {
      final profile = await ProfileService.instance.getCurrentUserProfile();
      if (profile == null || !mounted) return;

      final displayName = profile['displayName'] as String?;
      final email = profile['email'] as String?;
      final bio = profile['bio'] as String?;
      final photoURL = profile['photoURL'] as String?;
      final twitter = profile['twitter'] as String?;
      final instagram = profile['instagram'] as String?;
      final tiktok = profile['tiktok'] as String?;
      final gallery = (profile['gallery'] as List?)?.whereType<String>().toList();
      final interests = (profile['interests'] as List?)?.whereType<String>().toList();
      final likes = profile['likes'];
      final matches = profile['matches'];
      final activities = profile['activities'];
      final friends = profile['friends'];

      setState(() {
        if (displayName != null && displayName.isNotEmpty) {
          _userData.name = displayName;
          _nameController.text = displayName;
        }
        if (email != null && email.isNotEmpty) {
          _userData.email = email;
        }
        if (bio != null) {
          _userData.bio = bio;
          _bioController.text = bio;
        }
        if (twitter != null) {
          _userData.twitter = twitter;
          _twitterController.text = twitter;
        }
        if (instagram != null) {
          _userData.instagram = instagram;
          _instagramController.text = instagram;
        }
        if (tiktok != null) {
          _userData.tiktok = tiktok;
          _tiktokController.text = tiktok;
        }
        if (photoURL != null && photoURL.isNotEmpty) {
          _avatarUrl = photoURL;
        }
        if (gallery != null && gallery.isNotEmpty) {
          images = gallery.take(3).toList();
        }
        _userData.likes = _safeStatValue(likes);
        _userData.matches = _safeStatValue(matches);
        _userData.activities = _safeStatValue(activities);
        _userData.friends = _safeStatValue(friends);
        if (interests != null && interests.isNotEmpty) {
          for (final i in _userInterests) {
            i.selected = interests.contains(i.label);
          }
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo cargar el perfil')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    super.dispose();
  }

  void _toggleEdit() {
    setState(() {
      if (_isEditing) {
        // Cancelar edición: restaurar valores originales
        _nameController.text = _userData.name;
        _bioController.text = _userData.bio;
        _twitterController.text = _userData.twitter;
        _instagramController.text = _userData.instagram;
        _tiktokController.text = _userData.tiktok;
      }
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveChanges() async {
    setState(() {
      _userData.name = _nameController.text;
      _userData.bio = _bioController.text;
      _userData.twitter = _twitterController.text;
      _userData.instagram = _instagramController.text;
      _userData.tiktok = _tiktokController.text;
      _isEditing = false;
    });

    final selectedInterests = _userInterests
        .where((i) => i.selected)
        .map((i) => i.label)
        .toList();

    await ProfileService.instance.updateCurrentUserProfile(
      displayName: _userData.name,
      bio: _userData.bio,
      photoURL: _avatarUrl,
      twitter: _userData.twitter,
      instagram: _userData.instagram,
      tiktok: _userData.tiktok,
      gallery: images,
      interests: selectedInterests,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
  }

  void _handleRemoveImage(int index) {
    setState(() {
      images.removeAt(index);
    });
    ProfileService.instance.updateCurrentUserProfile(gallery: images);
  }

  void _handleAddImage() {
    if (images.length >= 3) return;
    final available = profileImages
        .where((img) => !images.contains(img))
        .toList();
    if (available.isNotEmpty) {
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % available.length;
      setState(() {
        images.add(available[randomIndex]);
      });
      ProfileService.instance.updateCurrentUserProfile(gallery: images);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más imágenes disponibles')),
      );
    }
  }

  void _showAvatarSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cambiar foto de perfil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: profileImages.length,
              itemBuilder: (context, index) {
                final isSelected = _avatarUrl == profileImages[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _avatarUrl = profileImages[index];
                    });
                    ProfileService.instance.updateCurrentUserProfile(
                      photoURL: profileImages[index],
                    );
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Colors.deepPurple : Colors.grey,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        profileImages[index],
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Cabecera del perfil (sin correo)
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _isEditing ? _showAvatarSelector : null,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 70,
                                backgroundColor: Colors.grey.shade200,
                                child: ClipOval(
                                  child: Image.network(
                                    _avatarUrl,
                                    width: 140,
                                    height: 140,
                                    fit: BoxFit.cover,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return const SizedBox(
                                            width: 26,
                                            height: 26,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          );
                                        },
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(
                                        Icons.person,
                                        size: 56,
                                        color: Colors.grey,
                                      );
                                    },
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.deepPurple,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        _isEditing
                            ? TextFormField(
                                controller: _nameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  border: OutlineInputBorder(),
                                ),
                              )
                            : Text(_textOrFallback(_userData.name, 'Usuario')),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _toggleEdit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar perfil'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    // Tarjeta de estadísticas (ahora con 4 elementos)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            StatCard(
                              icon: Icons.favorite,
                              label: 'Me gusta',
                              value: _userData.likes,
                            ),
                            StatCard(
                              icon: Icons.people,
                              label: 'Matches',
                              value: _userData.matches,
                            ),
                            StatCard(
                              icon: Icons.calendar_today,
                              label: 'Actividades',
                              value: _userData.activities,
                            ),
                            StatCard(
                              icon: Icons.group,
                              label: 'Amigos',
                              value: _userData.friends,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Galería de fotos
                    Card(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.photo_camera),
                                const SizedBox(width: 8),
                                const Text('Mis Fotos'),
                                const Spacer(),
                                Text('${images.length} de 3'),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 0.75,
                                      ),
                                  itemCount: 3,
                                  itemBuilder: (context, index) {
                                    if (index < images.length) {
                                      final img = images[index];
                                      return Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Image.network(
                                              img,
                                              fit: BoxFit.cover,
                                              width: double.infinity,
                                              height: double.infinity,
                                              loadingBuilder:
                                                  (
                                                    context,
                                                    child,
                                                    loadingProgress,
                                                  ) {
                                                    if (loadingProgress ==
                                                        null) {
                                                      return child;
                                                    }
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const SizedBox(
                                                        width: 20,
                                                        height: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    );
                                                  },
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                    return Container(
                                                      color:
                                                          Colors.grey.shade200,
                                                      alignment:
                                                          Alignment.center,
                                                      child: const Icon(
                                                        Icons
                                                            .broken_image_outlined,
                                                      ),
                                                    );
                                                  },
                                            ),
                                          ),
                                          if (_isEditing)
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: GestureDetector(
                                                onTap: () =>
                                                    _handleRemoveImage(index),
                                                child: Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Color.fromARGB(
                                                          255,
                                                          255,
                                                          0,
                                                          0,
                                                        ),
                                                      ),
                                                  child: const Icon(
                                                    Icons.close,
                                                    size: 18,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          if (index == 0)
                                            const Positioned(
                                              top: 4,
                                              left: 4,
                                              child: Text('Principal'),
                                            ),
                                        ],
                                      );
                                    } else {
                                      return GestureDetector(
                                        onTap: _isEditing
                                            ? _handleAddImage
                                            : null,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              width: 2,
                                              style: BorderStyle.solid,
                                              color: _isEditing
                                                  ? Colors.grey
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                width: 40,
                                                height: 40,
                                                decoration: const BoxDecoration(
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.add,
                                                  color: _isEditing
                                                      ? Colors.grey
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Añadir foto',
                                                style: TextStyle(
                                                  color: _isEditing
                                                      ? Colors.grey
                                                      : Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _isEditing
                                      ? 'Toca el icono de cerrar (X) para eliminar fotos. Toca + para añadir nuevas.'
                                      : 'Haz clic en "Editar perfil" para cambiar tus fotos.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sobre mí
                    InfoSection(
                      icon: Icons.chat,
                      title: 'Sobre mí',
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Biografía'),
                              const SizedBox(height: 4),
                              _isEditing
                                  ? TextFormField(
                                      controller: _bioController,
                                      maxLines: 3,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    )
                                  : Text(
                                      _textOrFallback(
                                        _userData.bio,
                                        'Completa tu perfil para que otros usuarios te conozcan mejor.',
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Intereses
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  final result =
                                      await Navigator.push<List<Interest>>(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => InterestScreen(
                                            currentInterests: _userInterests,
                                          ),
                                        ),
                                      );
                                  if (result != null) {
                                    setState(() {
                                      _userInterests = result;
                                    });

                                    final selectedInterests = _userInterests
                                        .where((i) => i.selected)
                                        .map((i) => i.label)
                                        .toList();
                                    ProfileService.instance
                                        .updateCurrentUserProfile(
                                          interests: selectedInterests,
                                        );
                                  }
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text('Intereses'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_userInterests.where((i) => i.selected).isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  'No hay intereses seleccionados',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _userInterests
                                    .where((i) => i.selected)
                                    .length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  final interest = _userInterests
                                      .where((i) => i.selected)
                                      .toList()[index];
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.deepPurple
                                                  .withOpacity(0.1),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              interest.icon,
                                              color: Colors.deepPurple,
                                              size: 18,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            interest.label,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: interest.selectedSubInterests
                                            .map(
                                              (sub) => Chip(
                                                label: Text(sub),
                                                deleteIcon: const Icon(
                                                  Icons.close,
                                                  size: 16,
                                                ),
                                                onDeleted: () {
                                                  setState(() {
                                                    interest
                                                        .selectedSubInterests
                                                        .remove(sub);
                                                    if (interest
                                                        .selectedSubInterests
                                                        .isEmpty) {
                                                      interest.selected = false;
                                                    }
                                                  });
                                                },
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ],
                                  );
                                },
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Redes Sociales
                    InfoSection(
                      icon: Icons.public,
                      title: 'Redes Sociales',
                      children: [
                        _buildSocialRow(
                          icon: Icons.tag,
                          label: 'Twitter',
                          value: _userData.twitter,
                          controller: _twitterController,
                        ),
                        _buildSocialRow(
                          icon: Icons.photo_camera,
                          label: 'Instagram',
                          value: _userData.instagram,
                          controller: _instagramController,
                        ),
                        _buildSocialRow(
                          icon: Icons.music_note,
                          label: 'TikTok',
                          value: _userData.tiktok,
                          controller: _tiktokController,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          // Botón guardar (solo en modo edición)
          if (_isEditing)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 800),
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  child: const Text('Guardar cambios'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSocialRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(icon),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label),
                const SizedBox(height: 4),
                _isEditing
                    ? TextFormField(
                        controller: controller,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      )
                    : Text(_textOrFallback(value, '-')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widgets reutilizables
class StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const StatCard({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = value.trim().isEmpty ? '0' : value;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(shape: BoxShape.circle),
            child: Icon(icon),
          ),
          const SizedBox(height: 8),
          Text(safeValue),
          const SizedBox(height: 2),
          Text(label),
        ],
      ),
    );
  }
}

class InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;
  const InfoSection({
    required this.icon,
    required this.title,
    required this.children,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [Icon(icon), const SizedBox(width: 8), Text(title)],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}