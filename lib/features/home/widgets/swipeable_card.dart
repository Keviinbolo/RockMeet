import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:RockMeet/core/models/user_profile.dart';
import 'package:RockMeet/config/Theme/constants/colors.dart';
import 'package:RockMeet/config/Theme/constants/text_styles.dart';

class SwipeableCard extends StatefulWidget {
  final UserProfile profile;
  final UserProfile? currentUserProfile;
  final bool showHints;
  final VoidCallback onDismissHints;
  final VoidCallback onSwipeLeft;
  final VoidCallback onSwipeRight;
  final Function(double) onDragDownProgress;
  final int Function(UserProfile, UserProfile)? calculateCompatibility;

  const SwipeableCard({
    super.key,
    required this.profile,
    this.currentUserProfile,
    required this.showHints,
    required this.onDismissHints,
    required this.onSwipeLeft,
    required this.onSwipeRight,
    required this.onDragDownProgress,
    this.calculateCompatibility,
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
    if (width <= 0) return;

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

                // Viñeta superior
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

                // Gradiente inferior
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

                // Info inferior
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
                                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
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
    final favoriteSong = widget.profile.favoriteSong;
    final favoriteArtist = widget.profile.favoriteArtist;

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

                    if (favoriteSong != null && favoriteSong.isNotEmpty) ...[
                      _buildSongCard(favoriteSong, favoriteArtist),
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
                        widget.profile.tiktok != null ||
                        widget.profile.spotify != null) ...[
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
        if (widget.profile.spotify != null)
          _buildSocialChip(
            'Spotify',
            Icons.music_note_rounded,
            const Color(0xFF1DB954),
          ),
      ],
    );
  }

  Widget _buildSongCard(String song, String? artist) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1DB954).withOpacity(0.15),
            AppColors.surface.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF1DB954).withOpacity(0.35),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF1DB954).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.music_note,
                color: Color(0xFF1DB954), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (artist != null && artist.isNotEmpty)
                  Text(
                    artist,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const Icon(Icons.play_circle_fill,
              color: Color(0xFF1DB954), size: 22),
        ],
      ),
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
