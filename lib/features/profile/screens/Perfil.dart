import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:RockMeet/core/models/user_profile.dart';
import 'package:RockMeet/features/profile/interest_screen.dart';
import 'package:RockMeet/core/services/profile_service.dart';
import 'package:RockMeet/core/services/schedule_service.dart';

// Constantes (igual que en tu código original)
const String defaultAvatarUrl =
    'https://images.unsplash.com/photo-1543689604-6fe8dbcd1f59?w=400&q=80&fit=crop';

const List<String> profileImages = [
  'https://images.unsplash.com/photo-1584819332026-ac894ac5c26e?w=400&q=80&fit=crop',
  'https://images.unsplash.com/photo-1744869985867-d23cc60e3625?w=400&q=80&fit=crop',
  'https://images.unsplash.com/photo-1768725845828-a74119dc4f34?w=400&q=80&fit=crop',
  'https://images.unsplash.com/photo-1623790679957-5a20f98faef6?w=400&q=80&fit=crop',
  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&q=80&fit=crop',
];

class Perfil extends StatelessWidget {
  const Perfil({super.key});

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
  bool _isEditing = false;

  // Controladores para edición
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  late TextEditingController _twitterController;
  late TextEditingController _instagramController;
  late TextEditingController _tiktokController;
  late TextEditingController _spotifyController;
  late TextEditingController _songController;
  late TextEditingController _artistController;

  // Variables temporales para cambios antes de guardar
  List<String> _tempImages = [];
  String _tempAvatarUrl = '';
  bool _isUploadingAvatar = false;
  String? _clase;
  List<Interest> _tempInterests = [];

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

  List<Interest> _buildInterestsFromProfile(UserProfile profile) {
    final catalog = _buildInterestCatalog();
    final byLabel = <String, Interest>{
      for (final item in catalog) item.label: item,
    };

    final selected = <String>{
      ...(profile.interests ?? const <String>[])
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty),
    };

    final detail = profile.interestsDetail ?? const <String, List<String>>{};
    for (final entry in detail.entries) {
      final label = entry.key.trim();
      if (label.isEmpty) continue;
      if (!byLabel.containsKey(label)) {
        byLabel[label] = Interest(
          Icons.interests,
          label,
          subInterests: entry.value,
        );
      } else {
        final existing = byLabel[label]!;
        final mergedSub = <String>{
          ...existing.subInterests,
          ...entry.value,
        }.toList();
        byLabel[label] = Interest(
          existing.icon,
          existing.label,
          subInterests: mergedSub,
        );
      }
    }

    final labels = byLabel.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return labels
        .map((label) {
          final base = byLabel[label]!;
          final savedSubs = detail[label] ?? const <String>[];
          return Interest(
            base.icon,
            base.label,
            selected: selected.contains(label),
            subInterests: base.subInterests,
            selectedSubInterests: Set<String>.from(savedSubs),
          );
        })
        .toList(growable: false);
  }

  String _safeStatValue(dynamic value) {
    if (value == null) return '0';
    final parsed = int.tryParse('$value');
    return (parsed != null && parsed >= 0) ? parsed.toString() : '0';
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _twitterController = TextEditingController();
    _instagramController = TextEditingController();
    _tiktokController = TextEditingController();
    _spotifyController = TextEditingController();
    _songController = TextEditingController();
    _artistController = TextEditingController();
    _tempInterests = [];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _tiktokController.dispose();
    _spotifyController.dispose();
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  void _toggleEdit() => setState(() => _isEditing = !_isEditing);

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final ref = FirebaseStorage.instance.ref('profile_photos/$uid.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      setState(() => _tempAvatarUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir imagen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  void _showScheduleImage(String imageUrl, String clase) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            title: Text('Horario — $clase'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: InteractiveViewer(
            child: Center(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, e, st) =>
                    const Center(child: Icon(Icons.broken_image, size: 64)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveChanges() async {
    // Extrae los intereses seleccionados como lista simple
    final selectedInterests = _tempInterests
        .where((i) => i.selected)
        .map((i) => i.label)
        .toList();

    // Construye un mapa con los intereses y sus sub-intereses
    final interestsWithSubInterests = <String, List<String>>{};
    for (final interest in _tempInterests) {
      if (interest.selected && interest.selectedSubInterests.isNotEmpty) {
        interestsWithSubInterests[interest.label] = interest
            .selectedSubInterests
            .toList();
      }
    }

    try {
      await ProfileService.instance.updateCurrentUserProfile(
        displayName: _nameController.text,
        bio: _bioController.text,
        photoURL: _tempAvatarUrl,
        twitter: _twitterController.text,
        instagram: _instagramController.text,
        tiktok: _tiktokController.text,
        spotify: _spotifyController.text,
        favoriteSong: _songController.text,
        favoriteArtist: _artistController.text,
        gallery: _tempImages,
        interests: selectedInterests,
        interestsWithSubInterests: interestsWithSubInterests.isNotEmpty
            ? interestsWithSubInterests
            : null,
        clase: _clase,
        updateClase: true,
      );

      setState(() => _isEditing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cambios guardados exitosamente'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleRemoveImage(int index) =>
      setState(() => _tempImages.removeAt(index));

  void _handleAddImage() {
    if (_tempImages.length >= 3) return;
    final available = profileImages
        .where((img) => !_tempImages.contains(img))
        .toList();
    if (available.isNotEmpty) {
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % available.length;
      setState(() => _tempImages.add(available[randomIndex]));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay más imágenes disponibles')),
      );
    }
  }

  void _showAvatarSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.deepPurple),
              title: const Text('Subir desde galería'),
              onTap: () async {
                Navigator.pop(context);
                await _pickAndUploadImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_off, color: Colors.grey),
              title: const Text('Sin foto de perfil'),
              onTap: () {
                setState(() => _tempAvatarUrl = '');
                Navigator.pop(context);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'O elige un avatar:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
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
                final isSelected = _tempAvatarUrl == profileImages[index];
                return GestureDetector(
                  onTap: () {
                    setState(() => _tempAvatarUrl = profileImages[index]);
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
                        errorBuilder: (ctx, e, st) =>
                            const Icon(Icons.person, color: Colors.grey),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('No autenticado')));
    }

    return Scaffold(
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            // El documento no existe — lo creamos con datos mínimos del usuario autenticado
            FirebaseFirestore.instance
                .collection('users')
                .doc(currentUser.uid)
                .set({
              'displayName': currentUser.displayName ?? '',
              'email': currentUser.email ?? '',
              'photoURL': currentUser.photoURL ?? '',
              'age': 18,
              'likes': 0,
              'friends': 0,
              'activities': 0,
              'profileComplete': false,
              'createdAt': Timestamp.now(),
            }, SetOptions(merge: true));
            return const Center(child: CircularProgressIndicator());
          }

          final profile = UserProfile.fromFirestore(snapshot.data!);
          final data = snapshot.data!.data()!;

          final String displayName = profile.name.trim();
          final String email = profile.email ?? '';
          final String bio = profile.bio ?? '';
          final String avatarUrl = profile.photoURL?.trim() ?? '';
          final String twitter = profile.twitter ?? '';
          final String instagram = profile.instagram ?? '';
          final String tiktok = profile.tiktok ?? '';
          final String spotify = profile.spotify ?? '';
          final String favoriteSong = profile.favoriteSong ?? '';
          final String favoriteArtist = profile.favoriteArtist ?? '';
          final List<String> gallery =
              (data['gallery'] as List?)?.whereType<String>().toList() ?? [];
          final String likes = _safeStatValue(profile.likes);

          final String activities = _safeStatValue(profile.activities);
          final String friends = _safeStatValue(profile.friends);

          // Sincronizar datos si no estamos editando
          if (!_isEditing) {
            if (_nameController.text != displayName)
              _nameController.text = displayName;
            if (_bioController.text != bio) _bioController.text = bio;
            if (_twitterController.text != twitter)
              _twitterController.text = twitter;
            if (_instagramController.text != instagram)
              _instagramController.text = instagram;
            if (_tiktokController.text != tiktok)
              _tiktokController.text = tiktok;
            if (_spotifyController.text != spotify)
              _spotifyController.text = spotify;
            if (_songController.text != favoriteSong)
              _songController.text = favoriteSong;
            if (_artistController.text != favoriteArtist)
              _artistController.text = favoriteArtist;
            _tempAvatarUrl = avatarUrl;
            _clase = profile.clase;
            _tempImages = List.from(gallery);
            _tempInterests = _buildInterestsFromProfile(profile);
          }

          return Stack(
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

                        // Cabecera del perfil
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
                                      child: _isUploadingAvatar
                                          ? const SizedBox(
                                              width: 40,
                                              height: 40,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 3,
                                              ),
                                            )
                                          : _tempAvatarUrl.isNotEmpty
                                          ? Image.network(
                                              _tempAvatarUrl,
                                              width: 140,
                                              height: 140,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (
                                                context,
                                                child,
                                                loadingProgress,
                                              ) {
                                                if (loadingProgress == null)
                                                  return child;
                                                return const SizedBox(
                                                  width: 26,
                                                  height: 26,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                );
                                              },
                                              errorBuilder: (
                                                context,
                                                error,
                                                stackTrace,
                                              ) {
                                                return const Icon(
                                                  Icons.person,
                                                  size: 56,
                                                  color: Colors.grey,
                                                );
                                              },
                                            )
                                          : const Icon(
                                              Icons.person,
                                              size: 56,
                                              color: Colors.grey,
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
                                : Text(displayName),
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

                        // Tarjeta de estadísticas
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                StatCard(
                                  icon: Icons.favorite,
                                  label: 'Me gusta',
                                  value: likes,
                                ),

                                StatCard(
                                  icon: Icons.calendar_today,
                                  label: 'Eventos',
                                  value: activities,
                                ),
                                StatCard(
                                  icon: Icons.group,
                                  label: 'Amigos',
                                  value: friends,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Clase
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.school),
                                    SizedBox(width: 8),
                                    Text(
                                      'Clase',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                if (_isEditing)
                                  DropdownButtonFormField<String?>(
                                    value: _clase,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Selecciona tu clase',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Sin clase'),
                                      ),
                                      ...ScheduleService.availableClasses.map(
                                        (c) => DropdownMenuItem<String?>(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _clase = value),
                                  )
                                else ...[
                                  Text(
                                    _clase ?? 'Sin clase asignada',
                                    style: TextStyle(
                                      color: _clase == null
                                          ? Colors.grey.shade500
                                          : null,
                                    ),
                                  ),
                                  if (_clase != null)
                                    StreamBuilder<String?>(
                                      stream: ScheduleService.instance
                                          .watchScheduleImageUrl(_clase!),
                                      builder: (context, scheduleSnap) {
                                        final scheduleUrl = scheduleSnap.data;
                                        if (scheduleUrl == null) {
                                          return const SizedBox.shrink();
                                        }
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                            top: 12,
                                          ),
                                          child: SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton.icon(
                                              onPressed: () =>
                                                  _showScheduleImage(
                                                    scheduleUrl,
                                                    _clase!,
                                                  ),
                                              icon: const Icon(
                                                Icons.calendar_month,
                                              ),
                                              label: const Text(
                                                'Ver horario de clases',
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
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
                                    Text('${_tempImages.length} de 3'),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 0.75,
                                          ),
                                      itemCount: 3,
                                      itemBuilder: (context, index) {
                                        if (index < _tempImages.length) {
                                          final img = _tempImages[index];
                                          return Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                            null)
                                                          return child;
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          alignment:
                                                              Alignment.center,
                                                          child: const SizedBox(
                                                            width: 20,
                                                            height: 20,
                                                            child:
                                                                CircularProgressIndicator(
                                                                  strokeWidth:
                                                                      2,
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
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
                                                        _handleRemoveImage(
                                                          index,
                                                        ),
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration:
                                                          const BoxDecoration(
                                                            shape:
                                                                BoxShape.circle,
                                                            color: Colors.red,
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
                                                borderRadius:
                                                    BorderRadius.circular(12),
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
                                                    decoration:
                                                        const BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    child: Icon(
                                                      Icons.add,
                                                      color: _isEditing
                                                          ? Colors.grey
                                                          : Colors
                                                                .grey
                                                                .shade600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    'Añadir foto',
                                                    style: TextStyle(
                                                      color: _isEditing
                                                          ? Colors.grey
                                                          : Colors
                                                                .grey
                                                                .shade600,
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
                                  const SizedBox(height: 4),
                                  _isEditing
                                      ? TextFormField(
                                          controller: _bioController,
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            border: OutlineInputBorder(),
                                          ),
                                        )
                                      : Text(bio),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Canción favorita
                        if (!_isEditing && favoriteSong.isNotEmpty)
                          _SpotifyCard(
                            song: favoriteSong,
                            artist: favoriteArtist,
                          )
                        else if (_isEditing)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.music_note,
                                          color: Color(0xFF1DB954)),
                                      SizedBox(width: 8),
                                      Text(
                                        'Canción favorita',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _songController,
                                    decoration: const InputDecoration(
                                      labelText: 'Nombre de la canción',
                                      border: OutlineInputBorder(),
                                      prefixIcon:
                                          Icon(Icons.music_note_outlined),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextFormField(
                                    controller: _artistController,
                                    decoration: const InputDecoration(
                                      labelText: 'Artista o banda',
                                      border: OutlineInputBorder(),
                                      prefixIcon: Icon(Icons.mic_none_outlined),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                                              builder: (context) =>
                                                  InterestScreen(
                                                    currentInterests:
                                                        _tempInterests,
                                                  ),
                                            ),
                                          );
                                      if (result != null) {
                                        setState(() {
                                          _tempInterests = result;
                                        });
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
                                if (_tempInterests
                                    .where((i) => i.selected)
                                    .isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Text(
                                      'No hay intereses seleccionados',
                                      style: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: _tempInterests
                                        .where((i) => i.selected)
                                        .length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(height: 16),
                                    itemBuilder: (context, index) {
                                      final interest = _tempInterests
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
                                            children: interest
                                                .selectedSubInterests
                                                .map((sub) {
                                                  return Chip(
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
                                                          interest.selected =
                                                              false;
                                                        }
                                                      });
                                                    },
                                                  );
                                                })
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
                              label: 'Twitter / X',
                              value: twitter,
                              controller: _twitterController,
                              color: const Color(0xFF1DA1F2),
                            ),
                            _buildSocialRow(
                              icon: Icons.camera_alt_outlined,
                              label: 'Instagram',
                              value: instagram,
                              controller: _instagramController,
                              color: const Color(0xFFE1306C),
                            ),
                            _buildSocialRow(
                              icon: Icons.music_note,
                              label: 'TikTok',
                              value: tiktok,
                              controller: _tiktokController,
                              color: Colors.white,
                            ),
                            _buildSocialRow(
                              icon: Icons.music_note_rounded,
                              label: 'Spotify',
                              value: spotify,
                              controller: _spotifyController,
                              color: const Color(0xFF1DB954),
                              hint: 'Enlace de tu perfil',
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
          );
        },
      ),
    );
  }

  Widget _buildSocialRow({
    required IconData icon,
    required String label,
    required String value,
    required TextEditingController controller,
    Color color = Colors.grey,
    String? hint,
  }) {
    final empty = value.trim().isEmpty;
    if (!_isEditing && empty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                const SizedBox(height: 4),
                _isEditing
                    ? TextFormField(
                        controller: controller,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          hintText: hint,
                        ),
                      )
                    : Text(
                        value,
                        style: TextStyle(color: Colors.grey.shade400),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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

class _SpotifyCard extends StatelessWidget {
  final String song;
  final String artist;
  const _SpotifyCard({required this.song, required this.artist});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1DB954).withOpacity(0.15),
            Colors.black.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.35),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.music_note,
                color: Color(0xFF1DB954), size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Canción favorita',
                  style: TextStyle(
                      color: Color(0xFF1DB954),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5),
                ),
                const SizedBox(height: 3),
                Text(
                  song,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artist.isNotEmpty)
                  Text(
                    artist,
                    style: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill,
              color: Color(0xFF1DB954), size: 30),
        ],
      ),
    );
  }
}
