import 'package:flutter/material.dart';
import 'word_data.dart';
import 'dart:math' as math;

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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Hodu's Hint · $_level of 3"),
          const SizedBox(height: 12),

          // Hint 1: meaning
          Text('Meaning: ${widget.word.meaning}'),

          // Hint 2: first syllable (학교 -> 학)
          if (_level >= 2)
            Text('First syllable: ${widget.word.hangul.substring(0, 1)}'),

          // Hint 3: full spelling in jamo (ㅎ ㅏ ㄱ ㄱ ㅛ)
          if (_level >= 3)
            Text('Full spelling: ${widget.word.jamo.join(' ')}'),

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