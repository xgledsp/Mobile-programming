import 'package:flutter/material.dart';
import 'app_theme.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Text('My Page Placeholder', style: TextStyle(fontSize: 18, color: lightText)),
      ),
    );
  }
}