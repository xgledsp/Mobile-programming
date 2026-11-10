import 'package:flutter/material.dart';

// We moved AppLanguage here so all files can access it without circular imports.
// (You can remove the AppLanguage enum from onboarding.dart if you put it here).
enum AppLanguage {
  english,
  korean,
}

// --- REUSABLE COLORS ---
const Color primaryBlue = Color(0xFF0969C7);
const Color darkText = Color(0xFF333333);
const Color lightText = Color(0xFF777777);
const Color borderGray = Color(0xFFE2E2E2);
const Color bgColor = Color(0xFFF8F9FA);

// --- WORD QUIZ TILE COLORS (Figma: Right spot / Wrong spot / Not in word) ---
const Color tileOrange = Color(0xFFF5A623);
const Color tileGray = Color(0xFFA5A9A8);
const Color softBlue = Color(0xFFEAF3FC);

// --- RESPONSIVE LAYOUT WRAPPER ---
// This centers the content and keeps it at a max width of 600 on Tablets.
class ResponsiveLayout extends StatelessWidget {
  final Widget child;
  const ResponsiveLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}