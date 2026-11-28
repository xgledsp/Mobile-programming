import 'me_models.dart';

// ================================================================
// NOTICE EXPLAINED DATA MODELS
// 공지 해석 결과 데이터 구조
// ================================================================
//
// The analysis is written in English only (the UI labels around it are
// bilingual, but the explanation itself is not).
// Deadlines reuse [ScheduleEvent] so they can go straight into the
// Me tab calendar through [eventStore].
// ================================================================

class NoticeAnalysis {
  /// Short English title, e.g. "Winter session 2026 schedule".
  final String title;

  /// The Korean notice text (pasted, or extracted from the PDF).
  final String originalText;

  /// "What it means": a plain-English summary.
  final String summary;

  /// "So, what do I do?": the to-do steps, in order.
  final List<String> steps;

  /// Dates that can be added to the calendar. Empty if the notice has none.
  final List<ScheduleEvent> deadlines;

  const NoticeAnalysis({
    required this.title,
    required this.originalText,
    required this.summary,
    required this.steps,
    required this.deadlines,
  });
}

const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const List<String> _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// "Fri, Nov 20, 2026 · 23:59"
String formatNoticeDate(DateTime d) {
  final String hh = d.hour.toString().padLeft(2, '0');
  final String mm = d.minute.toString().padLeft(2, '0');
  return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year} · $hh:$mm';
}
