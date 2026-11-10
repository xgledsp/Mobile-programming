import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'word_data.dart';

/// "Review Session" screen of the word quiz.
///
/// The list shows every finished word, newest first, marked Correct or
/// Incorrect. The blue card on top shows the word selected in the list; if
/// nothing was tapped it shows the most recent word.
class ReviewPage extends StatefulWidget {
  /// Finished words in the order they were played (oldest first).
  final List<ReviewEntry> history;

  /// The word of the round in progress. Only shown while nothing has been
  /// finished yet; null when the screen is opened from Home before any quiz.
  final QuizWord? currentWord;

  final VoidCallback onNextWord;

  const ReviewPage({
    super.key,
    required this.history,
    this.currentWord,
    required this.onNextWord,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final ScrollController _scrollController = ScrollController();

  // Index into the newest-first list. null means "nothing tapped", which
  // shows the most recent word (index 0).
  int? _selectedIndex;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _selectEntry(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // The blue card is above the list, so bring it back into view.
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Newest first.
    final List<ReviewEntry> items = widget.history.reversed.toList();
    final int shownIndex = _selectedIndex ?? 0;
    final ReviewEntry? shown = items.isEmpty ? null : items[shownIndex];

    final QuizWord? shownWord = shown?.word ?? widget.currentWord;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveLayout(
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.chevron_left, size: 20),
                  label: const Text(
                    'Word Quiz',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryBlue,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Review Session',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),
                const SizedBox(height: 20),
                _buildWordCard(shownWord),
                const SizedBox(height: 20),
                _buildHistoryCard(items, shownIndex),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onNextWord();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Next word',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWordCard(QuizWord? word) {
    if (word == null) {
      return _buildEmptyWordCard();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                word.hangul,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '[${word.romanization}]',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ),
            ],
          ),
          Text(
            word.meaning,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          _JamoTiles(word: word, onBlue: true),
        ],
      ),
    );
  }

  Widget _buildEmptyWordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'No word yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Play the word quiz first. 먼저 단어 퀴즈를 풀어보세요.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(List<ReviewEntry> items, int shownIndex) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No finished words yet. Solved and missed words will be '
                'listed here.\n아직 완료한 단어가 없어요.',
                style: TextStyle(fontSize: 13, color: lightText, height: 1.5),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 320),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: items.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(height: 6),
                itemBuilder: (BuildContext context, int index) {
                  return _buildHistoryRow(
                    items[index],
                    selected: index == shownIndex,
                    onTap: () => _selectEntry(index),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(
    ReviewEntry entry, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    final bool ok = entry.solved;
    final Color chipColor = ok ? const Color(0xFF1E7B34) : const Color(0xFFB45309);

    return Material(
      color: selected ? softBlue : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? primaryBlue : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.word.hangul,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _JamoTiles(word: entry.word, onBlue: false),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: ok ? const Color(0xFFE6F4EA) : const Color(0xFFFFF1E3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: chipColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      ok ? 'Correct' : 'Incorrect',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: chipColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A word shown as small jamo tiles, grouped by syllable.
class _JamoTiles extends StatelessWidget {
  final QuizWord word;
  final bool onBlue;

  const _JamoTiles({required this.word, required this.onBlue});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 14,
      runSpacing: 6,
      children: word.hangul.split('').map((String syllable) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: Hangul.toJamo(syllable).map(_buildTile).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildTile(String letter) {
    return Container(
      width: 26,
      height: 26,
      margin: const EdgeInsets.only(right: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: onBlue ? Colors.white : primaryBlue),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: primaryBlue,
        ),
      ),
    );
  }
}
