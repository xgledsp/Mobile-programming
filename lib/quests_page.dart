import 'package:flutter/material.dart';
import 'app_theme.dart';

class QuestsPage extends StatefulWidget {
  const QuestsPage({super.key});

  @override
  State<QuestsPage> createState() => _QuestsPageState();
}

class _QuestsPageState extends State<QuestsPage> {
  // false = Arrival tab, true = Return tab.
  bool _showReturn = false;

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
                  children: [
                    const Expanded(
                      child: Text(
                        'Quests',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: darkText),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {}, // TODO: open the documents page
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('input your documents', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  '입국부터 귀국까지 · Your semester, step by step',
                  style: TextStyle(fontSize: 13, color: lightText),
                ),
                const SizedBox(height: 16),
                _buildTabToggle(),
                const SizedBox(height: 20),

                // Return tab content (redesigned in Q3).
                if (_showReturn) ...[
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
                ] else ...[
                  // Arrival tab content (filled in Q2).
                  const Text('Arrival quests will be here.'),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pill-shaped switch between the Arrival and Return tabs.
  Widget _buildTabToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: softBlue,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              icon: Icons.flight_land,
              label: 'Arrival 입국',
              selected: !_showReturn,
              onTap: () => setState(() => _showReturn = false),
            ),
          ),
          Expanded(
            child: _buildTabButton(
              icon: Icons.luggage_outlined,
              label: 'Return 귀국',
              selected: _showReturn,
              onTap: () => setState(() => _showReturn = true),
            ),
          ),
        ],
      ),
    );
  }

  /// One side of the toggle. White and blue when selected.
  Widget _buildTabButton({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: selected ? primaryBlue : lightText),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? primaryBlue : lightText,
              ),
            ),
          ],
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