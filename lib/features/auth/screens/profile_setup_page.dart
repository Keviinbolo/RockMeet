import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';
import 'package:RockMeet/core/services/profile_service.dart';

// ─── Interest data ────────────────────────────────────────────────────────────

class _Interest {
  final IconData icon;
  final String label;
  final List<String> subInterests;
  bool selected;
  Set<String> selectedSubs;

  _Interest(
    this.icon,
    this.label, {
    this.subInterests = const [],
    this.selected = false,
    Set<String>? selectedSubs,
  }) : selectedSubs = selectedSubs ?? {};
}

List<_Interest> _buildCatalog() => [
      _Interest(Icons.music_note, 'Música',
          subInterests: ['Rock', 'Pop', 'Jazz', 'Electrónica', 'Hip-Hop', 'Metal', 'Reggaeton']),
      _Interest(Icons.sports_soccer, 'Deporte',
          subInterests: ['Fútbol', 'Baloncesto', 'Tenis', 'Running', 'Natación', 'Gimnasio']),
      _Interest(Icons.movie, 'Películas',
          subInterests: ['Acción', 'Comedia', 'Drama', 'Ciencia Ficción', 'Terror', 'Anime']),
      _Interest(Icons.book, 'Lectura',
          subInterests: ['Ficción', 'Misterio', 'Fantasía', 'Biografía', 'Manga']),
      _Interest(Icons.travel_explore, 'Viajar',
          subInterests: ['Playas', 'Montañas', 'Ciudades', 'Aventura', 'Cultural']),
      _Interest(Icons.brush, 'Arte',
          subInterests: ['Dibujo', 'Pintura', 'Fotografía', 'Diseño', 'Escultura']),
      _Interest(Icons.computer, 'Tecnología',
          subInterests: ['Programación', 'Robótica', 'IA', 'Videojuegos', 'Hacking ético']),
      _Interest(Icons.sports_esports, 'Gaming',
          subInterests: ['FPS', 'RPG', 'Estrategia', 'Battle Royale', 'Indie']),
    ];

// ─── Main widget ──────────────────────────────────────────────────────────────

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isSaving = false;

  // Step 1 – Photo
  File? _photoFile;
  bool _uploadingPhoto = false;
  final List<File?> _galleryFiles = [null, null, null];
  bool _uploadingGallery = false;

  // Step 2 – Bio & socials
  final _bioController = TextEditingController();
  final _twitterController = TextEditingController();
  final _instagramController = TextEditingController();
  final _spotifyController = TextEditingController();

  // Step 3 – Favorite song
  final _songController = TextEditingController();
  final _artistController = TextEditingController();

  // Step 4 – Interests
  late List<_Interest> _interests;

  static const int _totalSteps = 4;

  @override
  void initState() {
    super.initState();
    _interests = _buildCatalog();
    // Rebuild preview card as user types
    _songController.addListener(() => setState(() {}));
    _artistController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bioController.dispose();
    _twitterController.dispose();
    _instagramController.dispose();
    _spotifyController.dispose();
    _songController.dispose();
    _artistController.dispose();
    super.dispose();
  }

  // ─── Navigation ─────────────────────────────────────────────────────────────

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  // ─── Photo picker ────────────────────────────────────────────────────────────

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  Future<String?> _uploadPhoto() async {
    if (_photoFile == null) return null;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    setState(() => _uploadingPhoto = true);
    try {
      final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');
      await ref.putFile(_photoFile!);
      return await ref.getDownloadURL();
    } catch (_) {
      return null;
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _pickGalleryImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null && mounted) {
      setState(() => _galleryFiles[index] = File(picked.path));
    }
  }

  Future<List<String>> _uploadGalleryPhotos(String uid) async {
    final urls = <String>[];
    setState(() => _uploadingGallery = true);
    try {
      for (int i = 0; i < _galleryFiles.length; i++) {
        final file = _galleryFiles[i];
        if (file == null) continue;
        final ref = FirebaseStorage.instance.ref('users/$uid/gallery_$i.jpg');
        await ref.putFile(file);
        final url = await ref.getDownloadURL();
        urls.add(url);
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _uploadingGallery = false);
    }
    return urls;
  }

  // ─── Finish & save ───────────────────────────────────────────────────────────

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      // Upload profile photo if selected
      final photoURL = await _uploadPhoto();

      // Upload gallery photos
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final galleryUrls = await _uploadGalleryPhotos(uid);

      // Build interest maps
      final selectedInterests = _interests
          .where((i) => i.selected)
          .map((i) => i.label)
          .toList();

      final interestsDetail = <String, List<String>>{
        for (final i in _interests)
          if (i.selected && i.selectedSubs.isNotEmpty) i.label: i.selectedSubs.toList(),
      };

      // Collect non-empty optional fields
      String? bio = _bioController.text.trim().isEmpty ? null : _bioController.text.trim();
      String? twitter = _twitterController.text.trim().isEmpty ? null : _twitterController.text.trim();
      String? instagram = _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim();
      String? spotify = _spotifyController.text.trim().isEmpty ? null : _spotifyController.text.trim();
      String? song = _songController.text.trim().isEmpty ? null : _songController.text.trim();
      String? artist = _artistController.text.trim().isEmpty ? null : _artistController.text.trim();

      await ProfileService.instance.updateCurrentUserProfile(
        photoURL: photoURL,
        bio: bio,
        twitter: twitter,
        instagram: instagram,
        spotify: spotify,
        favoriteSong: song,
        favoriteArtist: artist,
        interests: selectedInterests.isNotEmpty ? selectedInterests : null,
        interestsWithSubInterests: interestsDetail.isNotEmpty ? interestsDetail : null,
        gallery: galleryUrls.isNotEmpty ? galleryUrls : null,
      );

      await ProfileService.instance.markProfileComplete();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar el perfil: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildPhotoStep(),
                  _buildBioSocialsStep(),
                  _buildSpotifyStep(),
                  _buildInterestsStep(),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ─── Header with progress ────────────────────────────────────────────────────

  Widget _buildHeader() {
    final labels = ['Foto', 'Sobre ti', 'Música', 'Intereses'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                GestureDetector(
                  onTap: _back,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.arrow_back_ios_new,
                        size: 16, color: AppColors.textPrimary),
                  ),
                )
              else
                const SizedBox(width: 32),
              const Spacer(),
              Text(
                '${_currentStep + 1} / $_totalSteps',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Step dots
          Row(
            children: List.generate(_totalSteps, (i) {
              final active = i <= _currentStep;
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 6 : 0),
                  height: 4,
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Text(
            labels[_currentStep],
            style: AppTextStyles.headlineSmall,
          ),
        ],
      ),
    );
  }

  // ─── Footer buttons ──────────────────────────────────────────────────────────

  Widget _buildFooter() {
    final isLast = _currentStep == _totalSteps - 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: Row(
        children: [
          // Skip (not last step)
          if (!isLast)
            TextButton(
              onPressed: _next,
              child: Text(
                'Omitir',
                style: AppTextStyles.labelMedium
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          const Spacer(),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (_isSaving || _uploadingPhoto) ? null : _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: (_isSaving || _uploadingPhoto)
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      isLast ? 'Empezar' : 'Siguiente',
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 1: Photo ───────────────────────────────────────────────────────────

  Widget _buildPhotoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Añade tu foto de perfil y hasta 3 fotos para tu galería',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Foto de perfil
          Text('Foto de perfil', style: AppTextStyles.labelLarge),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => _pickImage(ImageSource.gallery),
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.5),
                        width: 2.5,
                      ),
                      image: _photoFile != null
                          ? DecorationImage(
                              image: FileImage(_photoFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _photoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person, size: 48, color: AppColors.textHint),
                              const SizedBox(height: 6),
                              Text(
                                'Toca para añadir',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          )
                        : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPickerButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Galería',
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                const SizedBox(width: 12),
                _buildPickerButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Cámara',
                  onTap: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
          Divider(color: AppColors.border),
          const SizedBox(height: 20),

          // Galería de fotos
          Row(
            children: [
              Text('Mis fotos', style: AppTextStyles.labelLarge),
              const SizedBox(width: 8),
              Text(
                '(hasta 3)',
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Estas fotos se mostrarán en tu tarjeta al explorar',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: List.generate(3, (i) => _buildGallerySlot(i)),
          ),
          const SizedBox(height: 24),
          Text(
            'Puedes cambiarlas después desde tu perfil',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.textHint),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGallerySlot(int index) {
    final file = _galleryFiles[index];
    return Expanded(
      child: GestureDetector(
        onTap: () => _pickGalleryImage(index),
        child: Container(
          margin: EdgeInsets.only(right: index < 2 ? 10 : 0),
          height: 110,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: file != null
                  ? AppColors.primary.withOpacity(0.5)
                  : AppColors.border,
              width: file != null ? 2 : 1.5,
            ),
            image: file != null
                ? DecorationImage(
                    image: FileImage(file),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_photo_alternate_outlined,
                        size: 28, color: AppColors.primary.withOpacity(0.6)),
                    const SizedBox(height: 4),
                    Text(
                      'Añadir',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() => _galleryFiles[index] = null),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close,
                              size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ),
      ),
    );
  }

  // ─── Step 2: Bio & socials ───────────────────────────────────────────────────

  Widget _buildBioSocialsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Cuéntanos un poco sobre ti y cómo encontrarte',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          _buildSectionLabel('Bio'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _bioController,
            hint: 'Cuéntanos algo sobre ti...',
            maxLines: 4,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 24),
          _buildSectionLabel('Redes sociales'),
          const SizedBox(height: 8),
          _buildSocialField(
            controller: _twitterController,
            hint: '@usuario',
            icon: Icons.alternate_email,
            label: 'Twitter / X',
            iconColor: const Color(0xFF1DA1F2),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            controller: _instagramController,
            hint: '@usuario',
            icon: Icons.camera_alt_outlined,
            label: 'Instagram',
            iconColor: const Color(0xFFE1306C),
          ),
          const SizedBox(height: 12),
          _buildSocialField(
            controller: _spotifyController,
            hint: 'Tu enlace de perfil de Spotify',
            icon: Icons.music_note,
            label: 'Spotify',
            iconColor: const Color(0xFF1DB954),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(label, style: AppTextStyles.labelLarge);
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
        prefixIcon:
            icon != null ? Icon(icon, size: 20, color: AppColors.textHint) : null,
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surface),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.surface),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildSocialField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required String label,
    required Color iconColor,
    TextInputType? keyboardType,
  }) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType ?? TextInputType.text,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: iconColor, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step 3: Spotify / favorite song ────────────────────────────────────────

  Widget _buildSpotifyStep() {
    final song = _songController.text.trim();
    final artist = _artistController.text.trim();
    final hasSong = song.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            '¿Cuál es tu canción favorita ahora mismo?',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          // Preview card
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1DB954).withOpacity(0.15),
                  AppColors.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF1DB954).withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.music_note,
                    color: Color(0xFF1DB954),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasSong ? song : 'Nombre de la canción',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: hasSong
                              ? AppColors.textPrimary
                              : AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        artist.isNotEmpty ? artist : 'Artista',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: artist.isNotEmpty
                              ? AppColors.textSecondary
                              : AppColors.textHint,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.play_circle_fill,
                    color: Color(0xFF1DB954), size: 32),
              ],
            ),
          ),

          const SizedBox(height: 28),
          _buildSectionLabel('Canción'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _songController,
            hint: 'Nombre de la canción',
            icon: Icons.music_note_outlined,
          ),
          const SizedBox(height: 12),
          _buildSectionLabel('Artista'),
          const SizedBox(height: 8),
          _buildTextField(
            controller: _artistController,
            hint: 'Nombre del artista o banda',
            icon: Icons.mic_none_outlined,
          ),
          const SizedBox(height: 24),

          // Info box
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFF1DB954).withOpacity(0.2),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    size: 16, color: Color(0xFF1DB954)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Esto aparecerá en tu perfil. Puedes actualizar tu canción en cualquier momento desde ajustes.',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─── Step 4: Interests ───────────────────────────────────────────────────────

  Widget _buildInterestsStep() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Text(
            'Elige tus intereses para conectar con personas afines',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _interests.length,
            separatorBuilder: (_, __) => Divider(
              color: AppColors.surface,
              height: 1,
            ),
            itemBuilder: (context, i) => _buildInterestRow(_interests[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildInterestRow(_Interest interest) {
    return InkWell(
      onTap: () => _showSubInterestsSheet(interest),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(interest.icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(interest.label, style: AppTextStyles.bodyMedium),
                  if (interest.selectedSubs.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      interest.selectedSubs.join(', '),
                      style: AppTextStyles.labelSmall
                          .copyWith(color: AppColors.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Text(
              interest.selected ? 'Seleccionado' : 'Toca para elegir',
              style: AppTextStyles.labelSmall.copyWith(
                color: interest.selected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right,
                size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  void _showSubInterestsSheet(_Interest interest) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF141419),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    interest.label,
                    style: AppTextStyles.headlineSmall,
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        interest.selected = interest.selectedSubs.isNotEmpty;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                    child: Text('Hecho',
                        style: AppTextStyles.labelMedium
                            .copyWith(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: interest.subInterests.map((sub) {
                  final selected = interest.selectedSubs.contains(sub);
                  return GestureDetector(
                    onTap: () => setSheet(() {
                      if (selected) {
                        interest.selectedSubs.remove(sub);
                      } else {
                        interest.selectedSubs.add(sub);
                      }
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withOpacity(0.2)
                            : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        sub,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: selected
                              ? AppColors.primary
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
