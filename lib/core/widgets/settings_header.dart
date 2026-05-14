import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:RockMeet/config/Theme/app_theme.dart';

class SettingsHeader extends StatelessWidget {
  final String title;
  final double fontSize;

  const SettingsHeader({
    super.key,
    required this.title,
    this.fontSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.primaryGradientBox,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
