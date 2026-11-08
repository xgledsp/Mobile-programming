import 'package:flutter/material.dart';
import 'app_theme.dart';

class CharacterChatPage extends StatelessWidget {
  const CharacterChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: primaryBlue,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hodu (호두)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkText)),
                Text('Online', style: TextStyle(fontSize: 12, color: Colors.green.shade600)),
              ],
            ),
          ],
        ),
      ),
      body: ResponsiveLayout(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  _buildDateChip('Today'),
                  _buildChatBubble('Sarah! You got your SIM yesterday, nice. Today is dormitory day — do you know your building number?', isUser: false),
                  _buildChatBubble('Building B. What should I bring to check in?', isUser: true),
                  _buildChatBubble('Bring these 3 things to the B-dong office:\n\n• Passport (여권)\n• Check-in voucher (입주 확인서)\n• Dormitory fee receipt\n\n📍 Open: 9AM - 6PM', isUser: false),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: borderGray)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add_circle_outline, color: lightText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Message Hodu... 메시지 보내기',
                        hintStyle: const TextStyle(color: Colors.black38),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: bgColor,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String date) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderGray),
        ),
        child: Text(date, style: const TextStyle(fontSize: 12, color: lightText)),
      ),
    );
  }

  Widget _buildChatBubble(String text, {required bool isUser}) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
            bottomRight: isUser ? Radius.zero : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : darkText,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}