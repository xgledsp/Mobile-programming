import 'package:flutter/material.dart';
import 'word_data.dart';
import 'dart:math' as math;
import 'app_theme.dart';

/// Opens the "Hodu's Hint" bottom sheet for the word quiz.
/// Hints unlock step by step: meaning -> first syllable -> full spelling.
/// [onHintUsed] is called with the new count every time a hint is unlocked.
void showHintSheet(
  BuildContext context, {
  required QuizWord word,
  required int hintsUsed,
  required void Function(int) onHintUsed,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    showDragHandle: true, // Small gray bar at the top of the sheet
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) => _HintSheet(
      word: word,
      hintsUsed: hintsUsed,
      onHintUsed: onHintUsed,
    ),
  );
}

class _HintSheet extends StatefulWidget {
  final QuizWord word;
  final int hintsUsed;
  final void Function(int) onHintUsed;

  const _HintSheet({
    required this.word,
    required this.hintsUsed,
    required this.onHintUsed,
  });

  @override
  State<_HintSheet> createState() => _HintSheetState();
}

class _HintSheetState extends State<_HintSheet> {
  // How many hint steps are unlocked (1 to 3).
  late int _level;

  @override
  void initState() {
    super.initState();
    // At least the first hint is shown when the sheet opens.
    // If hints were already used, continue from there.
    _level = math.max(1, widget.hintsUsed);
    // Tell the quiz page after this frame is drawn (not during build).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onHintUsed(_level);
    });
  }

  void _nextHint() {
    if (_level >= 3) return; // Already at the last hint
    setState(() {
      _level += 1;
    });
    widget.onHintUsed(_level);
  }

  /// Top row: Hodu avatar, title, progress text and close button.
  Widget _buildHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 22,
          backgroundColor: softBlue,
          child: Text('🌱', style: TextStyle(fontSize: 22)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Hodu's Hint",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '호두의 힌트 · Hint $_level of 3 unlocked', 
                style: const TextStyle(fontSize: 12, color: lightText),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close, size: 20, color: lightText),
          style: IconButton.styleFrom(backgroundColor: bgColor),
          onPressed: () => Navigator.of(context).pop(), 
        ),
      ],
    );
  }
  /// Three-part progress bar: Meaning / First syllable / Full spelling.
  /// Unlocked steps are blue, locked steps are gray.
  Widget _buildProgressBar() {
    const List<String> labels = ['Meaning', 'First syllable', 'Full spelling'];
    return Row(
      children: List.generate(3, (int i) {
        // Step i is unlocked when it is below the current level.
        final bool unlocked = i < _level; 
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: unlocked ? primaryBlue : borderGray,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: unlocked ? FontWeight.bold : FontWeight.normal,
                    color: unlocked ? primaryBlue : lightText, 
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
           _buildProgressBar(),      
          const SizedBox(height: 16),

          // Hint 1: meaning
          Text('Meaning: ${widget.word.meaning}'),

          // Hint 2: first syllable (학교 -> 학)
          if (_level >= 2)
            Text('First syllable: ${widget.word.hangul.substring(0, 1)}'),

          // Hint 3: full spelling in jamo (ㅎ ㅏ ㄱ ㄱ ㅛ)
          if (_level >= 3) Text('Full spelling: ${widget.word.jamo.join(' ')}'),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _level < 3 ? _nextHint : null,
              child: const Text('Next hint'),
            ),
          ),
        ],
      ),
    );
  }
}
