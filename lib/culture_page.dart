import 'package:flutter/material.dart';
import 'app_theme.dart';

class CulturePage extends StatelessWidget {
  const CulturePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: darkText),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Culture Coach', style: TextStyle(color: darkText, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Quiz Mode', style: TextStyle(color: primaryBlue, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          )
        ],
      ),
      body: ResponsiveLayout(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGray),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.location_on, color: primaryBlue),
                    SizedBox(width: 8),
                    Text('Situation 상황', style: TextStyle(fontWeight: FontWeight.bold, color: darkText)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'At my first group project meeting, a senior asked my age. I answered, then a second-year student bowed and called me "unnie". Was I rude?',
                style: TextStyle(fontSize: 15, height: 1.5, color: darkText),
              ),
              const SizedBox(height: 24),

              const Text('QUESTION 1', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: lightText)),
              const SizedBox(height: 12),
              _buildOption('A', "You weren't rude — they're just being friendly", false),
              const SizedBox(height: 12),
              _buildOption('B', 'Yes, you should have asked their age first', false),
              const SizedBox(height: 12),
              _buildOption('C', 'You were rude by speaking informally', false),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Next question 다음 질문 →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(String label, String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? primaryBlue : borderGray, width: isSelected ? 2 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : bgColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(label, style: TextStyle(color: isSelected ? Colors.white : lightText, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 14, color: darkText, height: 1.4)),
          )
        ],
      ),
    );
  }
}