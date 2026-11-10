import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'how_to_play_dialog.dart';
import 'quiz_session.dart';
import 'review_page.dart';
import 'word_data.dart';

enum _QuizStatus { playing, solved, failed }

/// Wordle-style Korean word quiz where every tile is one letter (jamo) of the
/// word. Opened from Home > Start Quiz.
class WordQuizPage extends StatefulWidget {
  const WordQuizPage({super.key});

  @override
  State<WordQuizPage> createState() => _WordQuizPageState();
}

class _WordQuizPageState extends State<WordQuizPage> {
  // Remembered while the app is running ("Don't show this again").
  static bool _hideHowToPlay = false;

  final math.Random _random = math.Random();

  late QuizWord _word;
  late List<String> _answer;
  List<List<String>> _guesses = [];
  List<List<TileState>> _results = [];
  List<String> _current = [];
  _QuizStatus _status = _QuizStatus.playing;
  // Shared with the review screen opened from Home.
  List<ReviewEntry> get _history => QuizSession.instance.history;

  void _setWord(QuizWord word) {
    _word = word;
    _answer = word.jamo;
  }

  @override
  void initState() {
    super.initState();
    _setWord(pickRandomWord(_random));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hideHowToPlay) {
        _openHowToPlay();
      }
    });
  }

  // ---------------------------------------------------------------- actions

  Future<void> _openHowToPlay() async {
    final bool? dontShowAgain = await showHowToPlayDialog(context);
    if (dontShowAgain == true) {
      _hideHowToPlay = true;
    }
  }

  void _showMessage(String text) {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  void _onKey(String key) {
    if (key == 'ENTER') {
      _onEnter();
    } else if (key == '⌫') {
      _onBackspace();
    } else {
      _onLetter(key);
    }
  }

  void _onLetter(String letter) {
    if (_status != _QuizStatus.playing || _current.length >= _answer.length) {
      return;
    }
    setState(() {
      _current.add(letter);
    });
  }

  void _onBackspace() {
    if (_status != _QuizStatus.playing || _current.isEmpty) {
      return;
    }
    setState(() {
      _current.removeLast();
    });
  }

  void _onEnter() {
    if (_status != _QuizStatus.playing) {
      return;
    }
    if (_current.length < _answer.length) {
      _showMessage('Not enough letters | 글자가 부족해요');
      return;
    }

    final List<TileState> result = evaluateGuess(_current, _answer);
    final bool solved = result.every((TileState s) => s == TileState.correct);

    setState(() {
      _guesses.add(List<String>.of(_current));
      _results.add(result);
      _current = [];
      if (solved) {
        _status = _QuizStatus.solved;
      } else if (_guesses.length >= quizMaxRows) {
        _status = _QuizStatus.failed;
      }
    });

    if (solved) {
      _recordResult(true);
      _showMessage('Correct! | 정답이에요!');
    } else if (_status == _QuizStatus.failed) {
      _recordResult(false);
      _showMessage('The word was ${_word.hangul} | 정답은 ${_word.hangul}');
    }
  }

  void _recordResult(bool solved) {
    _history.add(ReviewEntry(word: _word, solved: solved));
  }

  void _openReview() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ReviewPage(
          history: List<ReviewEntry>.of(_history),
          currentWord: _word,
          onNextWord: _nextWord,
        ),
      ),
    );
  }

  void _nextWord() {
    // A word that was skipped after at least one guess is saved for review.
    if (_status == _QuizStatus.playing && _guesses.isNotEmpty) {
      _recordResult(false);
    }
    // New words and words answered wrongly before are mixed together.
    final QuizWord next =
        pickRandomWord(_random, history: _history, current: _word);

    setState(() {
      _setWord(next);
      _guesses = [];
      _results = [];
      _current = [];
      _status = _QuizStatus.playing;
    });
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsiveLayout(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              const double gap = 8;
              final double available = constraints.maxWidth - 48;
              final double tileSize = math.min(
                64.0,
                (available - gap * (quizMaxCols - 1)) / quizMaxCols,
              );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: darkText,
                          ),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const Expanded(
                          child: Text(
                            'Word Quiz',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: darkText,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'How to play',
                          icon: const Icon(Icons.help_outline, color: lightText),
                          onPressed: _openHowToPlay,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildTitleRow(),
                    const SizedBox(height: 20),
                    Center(child: _buildGrid(tileSize, gap)),
                    const SizedBox(height: 12),
                    _buildStatusText(),
                    _buildLegend(),
                    const SizedBox(height: 16),
                    _buildKeyboard(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTitleRow() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Korean Word Quiz',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              SizedBox(height: 2),
              Text(
                "한국어 단어 퀴즈 · Today's campus word",
                style: TextStyle(fontSize: 12, color: lightText),
              ),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: _openReview,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
          ),
          child: const Text(
            'Review',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(double tileSize, double gap) {
    final int wordLength = _answer.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(quizMaxRows, (int row) {
        return Padding(
          padding: EdgeInsets.only(bottom: row == quizMaxRows - 1 ? 0 : gap),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(quizMaxCols, (int col) {
              return Padding(
                padding: EdgeInsets.only(right: col == quizMaxCols - 1 ? 0 : gap),
                child: _buildTile(row, col, tileSize, wordLength),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildTile(int row, int col, double size, int wordLength) {
    String letter = '';
    TileState? state;

    final bool isCurrentRow =
        _status == _QuizStatus.playing && row == _guesses.length;

    if (row < _guesses.length) {
      if (col < _guesses[row].length) {
        letter = _guesses[row][col];
        state = _results[row][col];
      }
    } else if (isCurrentRow && col < _current.length) {
      letter = _current[col];
    }

    final bool disabled = col >= wordLength;
    final bool isActive = isCurrentRow && !disabled && col == _current.length;

    Color fill = Colors.white;
    Color border = borderGray;
    Color textColor = darkText;
    double borderWidth = 1.5;

    if (state == TileState.correct) {
      fill = primaryBlue;
      border = primaryBlue;
      textColor = Colors.white;
    } else if (state == TileState.present) {
      fill = tileOrange;
      border = tileOrange;
      textColor = Colors.white;
    } else if (state == TileState.absent) {
      fill = tileGray;
      border = tileGray;
      textColor = Colors.white;
    } else if (isActive) {
      fill = softBlue;
      border = primaryBlue;
      borderWidth = 2;
    } else if (letter.isNotEmpty) {
      border = darkText;
      borderWidth = 2;
    }

    final Widget tile = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border, width: borderWidth),
      ),
      child: Text(
        letter,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );

    // Tiles beyond the word's letter count are shown semi-transparent.
    return disabled ? Opacity(opacity: 0.3, child: tile) : tile;
  }

  Widget _buildStatusText() {
    if (_status == _QuizStatus.playing) {
      return const SizedBox.shrink();
    }
    final bool solved = _status == _QuizStatus.solved;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Center(
        child: Text(
          solved
              ? 'Solved! Tap Review to continue | 정답!'
              : 'Answer: ${_word.hangul} · Tap Review to continue',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: solved ? primaryBlue : tileOrange,
          ),
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(primaryBlue, 'Right spot'),
        const SizedBox(width: 16),
        _legendItem(tileOrange, 'Wrong spot'),
        const SizedBox(width: 16),
        _legendItem(tileGray, 'Not in word'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: lightText)),
      ],
    );
  }

  Widget _buildKeyboard() {
    return Column(
      children: quizKeyboardRows.map(_buildKeyRow).toList(),
    );
  }

  bool _isSpecialKey(String key) => key == 'ENTER' || key == '⌫';

  Widget _buildKeyRow(List<String> keys) {
    // The middle row has 9 keys, so it is centered with half-key spacers.
    final bool needsSpacers = keys.length == 9 && !keys.contains('ENTER');
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          if (needsSpacers) const Spacer(flex: 1),
          for (final String key in keys)
            Expanded(
              flex: _isSpecialKey(key) ? 3 : 2,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: _buildKey(key),
              ),
            ),
          if (needsSpacers) const Spacer(flex: 1),
        ],
      ),
    );
  }

  Widget _buildKey(String key) {
    final bool isBackspace = key == '⌫';
    final bool isEnter = key == 'ENTER';
    return Material(
      color: const Color(0xFFEDEFF1),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _onKey(key),
        child: SizedBox(
          height: 46,
          child: Center(
            child: isBackspace
                ? const Icon(Icons.backspace_outlined, size: 18, color: darkText)
                : Text(
                    key,
                    style: TextStyle(
                      fontSize: isEnter ? 11 : 17,
                      fontWeight: FontWeight.w600,
                      color: darkText,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
