import 'package:flutter/material.dart';
import 'app_theme.dart';

class QuestsPage extends StatelessWidget {
  const QuestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quests',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkText),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, color: lightText),
                      onPressed: () {},
                    )
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '일일 퀘스트를 완료하고, 보상을 받아요',
                  style: TextStyle(fontSize: 14, color: lightText),
                ),
                const SizedBox(height: 20),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderGray),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('D-12', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryBlue)),
                          Text('Dec 30, 2026', style: TextStyle(fontSize: 12, color: lightText)),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text('Return 타이머', style: TextStyle(color: primaryBlue)),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                const Text('Pack your suitcase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkText)),
                const SizedBox(height: 8),
                const Text('(목표: 4/4) Collect 4 essential items', style: TextStyle(fontSize: 13, color: lightText)),
                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSuitcaseItem(Icons.sim_card, 'SIM'),
                    _buildSuitcaseItem(Icons.credit_card, 'Bank card'),
                    _buildSuitcaseItem(Icons.money, 'Cash'),
                    _buildSuitcaseItem(Icons.badge, 'ARC'),
                  ],
                ),
                const SizedBox(height: 30),

                _buildQuestTile(Icons.phone_iphone, 'Carpool phone plan', '통신사 요금제 (KT, SKT, LG U+)'),
                const SizedBox(height: 12),
                _buildQuestTile(Icons.account_balance, 'Clone bank account', '은행 계좌 개설하기'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuitcaseItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: borderGray),
          ),
          child: Icon(icon, color: primaryBlue, size: 28),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: darkText, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildQuestTile(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGray),
      ),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: darkText)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: lightText)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: lightText),
        ],
      ),
    );
  }
}