import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Shows the "How to Play" dialog of the word quiz.
/// Returns true when the user ticked "Don't show this again".
Future<bool?> showHowToPlayDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => const _HowToPlayDialog(),
  );
}

class _HowToPlayDialog extends StatefulWidget {
  const _HowToPlayDialog();

  @override
  State<_HowToPlayDialog> createState() => _HowToPlayDialogState();
}

class _HowToPlayDialogState extends State<_HowToPlayDialog> {
  bool _dontShowAgain = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 18),
              _buildStep(
                number: 1,
                title: 'Type letter by letter',
                body: 'Each Korean syllable is split into its letters (jamo). '
                    'One tile = one letter.',
                extra: _buildSampleWord(),
              ),
              const SizedBox(height: 16),
              _buildStep(
                number: 2,
                title: 'Read the tile colors',
                extra: Column(
                  children: [
                    _buildColorRow(primaryBlue, 'ㄱ', 'Blue', 'right letter, right spot'),
                    const SizedBox(height: 8),
                    _buildColorRow(tileOrange, 'ㄱ', 'Orange', 'in the word, wrong spot'),
                    const SizedBox(height: 8),
                    _buildColorRow(tileGray, 'ㄴ', 'Gray', 'not in the word'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildStep(
                number: 3,
                title: 'Check your words',
                body: 'Every finished word is saved for review as Correct or '
                    'Incorrect. Tap a word in the list to see it again.',
                extra: Row(
                  children: [
                    _buildFakeButton('Review', filled: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _dontShowAgain),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: const Text(
                    "Got it, let's play!",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _dontShowAgain = !_dontShowAgain;
                    });
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: _dontShowAgain,
                        activeColor: primaryBlue,
                        onChanged: (bool? value) {
                          setState(() {
                            _dontShowAgain = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        "Don't show this again",
                        style: TextStyle(fontSize: 13, color: lightText),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.eco, color: Color(0xFF7CB342)),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How to Play',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
              Text(
                '게임 방법 · Guess the word',
                style: TextStyle(fontSize: 12, color: lightText),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: darkText),
          onPressed: () => Navigator.pop(context, _dontShowAgain),
        ),
      ],
    );
  }

  Widget _buildStep({
    required int number,
    required String title,
    String? body,
    Widget? extra,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: primaryBlue,
              child: Text(
                '$number',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: darkText,
                ),
              ),
            ),
          ],
        ),
        if (body != null) ...[
          const SizedBox(height: 6),
          Text(
            body,
            style: const TextStyle(fontSize: 13, color: darkText, height: 1.4),
          ),
        ],
        if (extra != null) ...[
          const SizedBox(height: 10),
          extra,
        ],
      ],
    );
  }

  Widget _buildSampleWord() {
    const List<String> letters = ['ㅇ', 'ㅕ', 'ㄴ', 'ㅍ', 'ㅣ', 'ㄹ'];
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: softBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            '연필',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward, size: 16, color: lightText),
        ),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: letters.map((String letter) {
              return Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: borderGray),
                ),
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: darkText,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildColorRow(Color color, String letter, String name, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            letter,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: ' · $text'),
              ],
            ),
            style: const TextStyle(fontSize: 13, color: darkText),
          ),
        ),
      ],
    );
  }

  Widget _buildFakeButton(String label, {required bool filled}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: filled ? primaryBlue : softBlue,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryBlue),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: filled ? Colors.white : primaryBlue,
        ),
      ),
    );
  }
}
