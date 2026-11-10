import 'word_data.dart';

/// Word quiz results that are shared between the quiz screen and the review
/// screen, so "Review Quiz" on Home shows the same list the quiz produced.
/// The data lives while the app is running.
class QuizSession {
  QuizSession._();

  static final QuizSession instance = QuizSession._();

  /// Finished words in the order they were played (oldest first).
  final List<ReviewEntry> history = [];
}
