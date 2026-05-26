import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:RockMeet/core/models/user_profile.dart';
import 'package:RockMeet/features/profile/interest_screen.dart';
import 'package:RockMeet/core/services/profile_service.dart';
import 'package:RockMeet/core/services/schedule_service.dart';
import 'package:RockMeet/core/services/supabase_service.dart';

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
  bool _isUploadingGallery = false;
  String? _clase;
  String? _course;
  List<Interest> _tempInterests = [];

  static const _courseOptions = [
    'DAM - Desarrollo de Aplicaciones Multiplataforma',
    'DAW - Desarrollo de Aplicaciones Web',
    'ASIX - Administración de Sistemas Informáticos en Red',
    'SMX - Sistemas Microinformáticos y Redes',
    'AU - Automoción',
    'IDMN - Imagen para el Diagnóstico y Medicina Nuclear',
    'HB - Higiene Bucodental',
    'MP - Marketing y Publicidad',
    'EDI - Educación Infantil',
    'Otro',
  ];

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
      final bytes = await picked.readAsBytes();
      final url = await SupabaseService.instance.uploadImage(
        path: 'profile-photos/$uid.jpg',
        bytes: bytes,
      );
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
        course: _course,
        updateCourse: true,
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

  Future<void> _handleAddImage() async {
    if (_tempImages.length >= 3) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingGallery = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
      final ts = DateTime.now().millisecondsSinceEpoch;
      final bytes = await picked.readAsBytes();
      final url = await SupabaseService.instance.uploadImage(
        path: 'gallery/$uid/photo_$ts.jpg',
        bytes: bytes,
      );
      setState(() => _tempImages.add(url));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingGallery = false);
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
            _course = _normalizeCourse(profile.course);
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
                                : Text(displayName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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

                        // Curso
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
                                      'Curso',
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
                                    value: _course,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: 'Selecciona tu curso',
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                        value: null,
                                        child: Text('Sin asignar'),
                                      ),
                                      ..._courseOptions.map(
                                        (c) => DropdownMenuItem<String?>(
                                          value: c,
                                          child: Text(c),
                                        ),
                                      ),
                                    ],
                                    onChanged: (value) =>
                                        setState(() => _course = value),
                                  )
                                else
                                  Text(
                                    _course ?? 'Sin curso asignado',
                                    style: TextStyle(
                                      color: _course == null
                                          ? Colors.grey.shade500
                                          : null,
                                    ),
                                  ),
                                // Horario de clase (si existe)
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
                                        padding: const EdgeInsets.only(top: 12),
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showScheduleImage(
                                              scheduleUrl,
                                              _clase!,
                                            ),
                                            icon: const Icon(Icons.calendar_month),
                                            label: const Text('Ver horario de clases'),
                                          ),
                                        ),
                                      );
                                    },
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
                                            onTap: (_isEditing &&
                                                    !_isUploadingGallery)
                                                ? () => _handleAddImage()
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
                                              child: _isUploadingGallery
                                                  ? const Center(
                                                      child: SizedBox(
                                                        width: 24,
                                                        height: 24,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      ),
                                                    )
                                                  : Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_photo_alternate_outlined,
                                                          size: 32,
                                                          color: _isEditing
                                                              ? Colors.grey
                                                              : Colors
                                                                    .grey
                                                                    .shade600,
                                                        ),
                                                        const SizedBox(
                                                          height: 4,
                                                        ),
                                                        Text(
                                                          'Añadir foto',
                                                          style: TextStyle(
                                                            fontSize: 12,
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

                        // Sobre mí — solo visible si hay bio o se está editando
                        if (bio.isNotEmpty || _isEditing)
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

                        // Intereses — solo visible si hay alguno o se está editando
                        if (_tempInterests.any((i) => i.selected) || _isEditing)
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

                        // Redes Sociales — solo visible si al menos una está rellena o editando
                        if (_isEditing ||
                            twitter.isNotEmpty ||
                            instagram.isNotEmpty ||
                            tiktok.isNotEmpty ||
                            spotify.isNotEmpty)
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
                              hint: 'Enlace de tu perfil'
                            ),
                            _buildSocialRow(
                              icon: Icons.camera_alt_outlined,
                              label: 'Instagram',
                              value: instagram,
                              controller: _instagramController,
                              color: const Color(0xFFE1306C),
                              hint: 'Enlace de tu perfil'
                            ),
                            _buildSocialRow(
                              icon: Icons.music_note,
                              label: 'TikTok',
                              value: tiktok,
                              controller: _tiktokController,
                              color: Colors.yellow.shade700,
                              hint: 'Enlace de tu perfil'
                            ),
                            _buildSocialRow(
                              icon: Icons.library_music,
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

  String? _normalizeCourse(String? raw) {
    if (raw == null) return null;
    if (_courseOptions.contains(raw)) return raw;
    final match = _courseOptions.firstWhere(
      (opt) => opt.startsWith('${raw.trim()} ') || opt == raw.trim(),
      orElse: () => '',
    );
    return match.isEmpty ? null : match;
  }

  String _shortenUrl(String url) {
    final trimmed = url.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.hasScheme) return trimmed;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return uri.host;
    // open.spotify.com/user/username → @username
    if (segments.length >= 2 && segments[0] == 'user') return '@${segments[1]}';
    // cualquier otra URL → último segmento del path
    return segments.last;
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
                    : GestureDetector(
                        onTap: () async {
                          final uri = Uri.tryParse(value.trim());
                          if (uri != null && uri.hasScheme && await canLaunchUrl(uri)) {
                            launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        child: Text(
                          _shortenUrl(value),
                          style: TextStyle(
                            color: color,
                            decoration: TextDecoration.underline,
                            decorationColor: color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
