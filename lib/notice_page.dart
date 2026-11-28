import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'me_models.dart';
import 'notice_models.dart';
import 'notice_service.dart';

// ================================================================
// NOTICE EXPLAINED (Campus tab)
// ================================================================
//
//  input   -> paste the notice text (text only; no file attachments)
//  loading -> explaining
//  result  -> original, what it means, what to do, add to calendar
//  error   -> something failed, try again
//
// If the user pastes something that is not text (an image, a picture of
// a table, a keyboard sticker...), the page says so instead of explaining.
//
// Labels are bilingual (English + 한국어) so users get used to Korean.
// The explanation itself is English only.
// ================================================================

enum _Stage { input, loading, result, error }

class NoticePage extends StatefulWidget {
  final NoticeAnalyzer analyzer;

  const NoticePage({
    super.key,
    this.analyzer = const LocalNoticeAnalyzer(),
  });

  @override
  State<NoticePage> createState() => _NoticePageState();
}

class _NoticePageState extends State<NoticePage> {
  _Stage _stage = _Stage.input;

  final TextEditingController _pasteController = TextEditingController();
  String _lastText = '';

  /// True while the "it wasn't text" message is shown.
  bool _notTextError = false;

  NoticeAnalysis? _analysis;
  bool _showFullOriginal = false;

  @override
  void initState() {
    super.initState();
    _pasteController.addListener(() {
      final String text = _pasteController.text;
      setState(() {
        if (text != _lastText) {
          // A pasted image shows up as U+FFFC: say so right away.
          // Any other new text hides the "not text" message.
          _notTextError = text.contains('￼');
        }
        _lastText = text;
      });
    });
  }

  @override
  void dispose() {
    _pasteController.dispose();
    super.dispose();
  }

  bool get _canExplain => _pasteController.text.trim().isNotEmpty;

  // --------------------------------------------------------------
  // Actions
  // --------------------------------------------------------------

  void _showNotTextError() => setState(() => _notTextError = true);

  Future<void> _explain() async {
    if (!_canExplain) return;
    final String text = _pasteController.text.trim();
    if (!looksLikeText(text)) {
      _showNotTextError();
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _stage = _Stage.loading);

    try {
      final NoticeAnalysis analysis = await widget.analyzer.analyze(text);
      if (!mounted) return;
      setState(() {
        _analysis = analysis;
        _showFullOriginal = false;
        _stage = _Stage.result;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _stage = _Stage.error);
    }
  }

  void _startOver() {
    setState(() {
      _stage = _Stage.input;
      _analysis = null;
      _pasteController.clear();
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openCalendarSheet() async {
    final NoticeAnalysis? analysis = _analysis;
    if (analysis == null) return;

    final List<ScheduleEvent>? chosen =
        await showModalBottomSheet<List<ScheduleEvent>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CalendarSheet(deadlines: analysis.deadlines),
    );

    if (chosen == null || chosen.isEmpty || !mounted) return;
    // Each plan keeps the "SO, WHAT DO I DO?" steps as its details.
    final int added = eventStore.addAll([
      for (final ScheduleEvent e in chosen)
        e.withSteps(whatToDoForEvent(e, analysis)),
    ]);
    setState(() {}); // refresh the "already added" state of the button
    _showSnack(added == 1
        ? 'Added 1 date to your calendar · 일정 1개를 추가했어요'
        : 'Added $added dates to your calendar · 일정 $added개를 추가했어요');
  }

  // --------------------------------------------------------------
  // Build
  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        // This page is a bottom tab, so there is nothing to go back to.
        automaticallyImplyLeading: false,
        title: const Text('Notice Explained · 공지 해석',
            style: TextStyle(
                color: darkText, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: ResponsiveLayout(
        child: switch (_stage) {
          _Stage.input => _buildInput(),
          _Stage.loading => _buildLoading(),
          _Stage.result => _buildResult(_analysis!),
          _Stage.error => _buildError(),
        },
      ),
    );
  }

  // --- input ------------------------------------------------------

  Widget _buildInput() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Got a Korean notice from school?',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: darkText),
          ),
          const SizedBox(height: 4),
          const Text(
            '학교 공지를 받으셨나요? 공지 내용을 붙여넣으면 무엇을 해야 하는지 알려드릴게요.',
            style: TextStyle(fontSize: 13, color: lightText),
          ),
          const SizedBox(height: 20),
          _buildPasteBox(),
          if (_notTextError) ...[
            const SizedBox(height: 8),
            _buildNotTextMessage(),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _canExplain ? _explain : null,
              icon: const Icon(Icons.auto_awesome, size: 20),
              label: const Text('Explain this notice · 공지 해석하기',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: borderGray,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// An empty box, like a translator app: tap it, then paste with the
  /// phone's own long-press "Paste" menu.
  Widget _buildPasteBox() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        TextField(
          controller: _pasteController,
          minLines: 10,
          maxLines: 16,
          keyboardType: TextInputType.multiline,
          style: const TextStyle(fontSize: 13, height: 1.5, color: darkText),
          // Images/GIFs/stickers pasted from the keyboard (e.g. Gboard on
          // Android) arrive here instead of as text.
          contentInsertionConfiguration: ContentInsertionConfiguration(
            onContentInserted: (_) => _showNotTextError(),
          ),
          decoration: InputDecoration(
            hintText:
                'Tap here and paste the text you copied\n여기를 눌러 복사한 공지 내용을 붙여넣으세요',
            hintStyle: const TextStyle(fontSize: 13, color: lightText),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: borderGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _notTextError ? Colors.red.shade300 : borderGray),
            ),
          ),
        ),
        if (_pasteController.text.isNotEmpty)
          TextButton.icon(
            onPressed: _pasteController.clear,
            icon: const Icon(Icons.close, size: 18),
            label: const Text('Clear · 지우기'),
          ),
      ],
    );
  }

  Widget _buildNotTextMessage() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.red.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notTextMessage,
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.red.shade900),
                ),
                const SizedBox(height: 2),

                /// 텍스트가 아닌 이미지나 특수기호만 입력하면, 이걸 띄움.
                Text(
                  '텍스트가 아니라서 해석할 수 없어요. 텍스트를 붙여넣어 주세요.',
                  style: TextStyle(fontSize: 12, color: Colors.red.shade800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- loading / error -------------------------------------------

  Widget _buildLoading() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: primaryBlue),
          const SizedBox(height: 16),
          const Text('Explaining the notice · 공지 해석 중',
              style: TextStyle(fontSize: 14, color: lightText)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
            const SizedBox(height: 12),
            const Text("Couldn't read this notice",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: darkText)),
            const SizedBox(height: 4),
            const Text('공지를 읽지 못했어요. 다시 시도해 주세요.',
                style: TextStyle(fontSize: 13, color: lightText)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _explain,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Try again · 다시 시도'),
            ),
            TextButton(
                onPressed: _startOver, child: const Text('Start over · 처음으로')),
          ],
        ),
      ),
    );
  }

  // --- result -----------------------------------------------------

  Widget _buildResult(NoticeAnalysis a) {
    final bool allAdded =
        a.deadlines.isNotEmpty && a.deadlines.every(eventStore.contains);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'AI explanation. Always double-check exact dates in the official notice.',
                    style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(a.title,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold, color: darkText)),
          const SizedBox(height: 20),
          _label('YOUR NOTICE 원문 (Korean)'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderGray),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.originalText,
                  maxLines: _showFullOriginal ? null : 6,
                  overflow: _showFullOriginal ? null : TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: darkText),
                ),
                if ('\n'.allMatches(a.originalText).length >= 6 ||
                    a.originalText.length > 200)
                  TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () =>
                        setState(() => _showFullOriginal = !_showFullOriginal),
                    child: Text(_showFullOriginal
                        ? 'Show less · 접기'
                        : 'Show all · 전체 보기'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _label('WHAT IT MEANS 뜻'),
          const SizedBox(height: 8),
          Text(a.summary,
              style:
                  const TextStyle(fontSize: 14, height: 1.5, color: darkText)),
          const SizedBox(height: 24),
          _label('SO, WHAT DO I DO? 어떻게 해야 할까요?'),
          const SizedBox(height: 12),
          for (int i = 0; i < a.steps.length; i++) ...[
            _buildStep(i + 1, a.steps[i]),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 18),
          if (a.deadlines.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderGray),
              ),
              child: const Row(
                children: [
                  Icon(Icons.event_busy, color: lightText),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'No dates found in this notice · 이 공지에는 일정이 없어요',
                        style: TextStyle(fontSize: 13, color: lightText)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: allAdded ? null : _openCalendarSheet,
                icon: Icon(allAdded ? Icons.check : Icons.calendar_today,
                    size: 20),
                label: Text(
                  allAdded
                      ? 'Added to calendar · 캘린더에 추가됨'
                      : 'Add dates to calendar · 캘린더에 추가',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: softBlue,
                  disabledForegroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _startOver,
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Explain another notice · 다른 공지 해석하기'),
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryBlue,
                side: const BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.bold, color: lightText));

  Widget _buildStep(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: const BoxDecoration(
            color: primaryBlue,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text('$number',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(text,
                style: const TextStyle(
                    fontSize: 14, height: 1.4, color: darkText)),
          ),
        ),
      ],
    );
  }
}

// ================================================================
// "Add to calendar" bottom sheet: pick which dates to add.
// Past dates and dates already in the calendar can't be picked.
// Pops with the chosen events, or null if cancelled.
// ================================================================

class _CalendarSheet extends StatefulWidget {
  final List<ScheduleEvent> deadlines;

  const _CalendarSheet({required this.deadlines});

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late final Set<ScheduleEvent> _selected;

  bool _isPast(ScheduleEvent e) => e.dateTime.isBefore(DateTime.now());
  bool _canPick(ScheduleEvent e) => !_isPast(e) && !eventStore.contains(e);

  @override
  void initState() {
    super.initState();
    // Upcoming dates start checked.
    _selected = widget.deadlines.where(_canPick).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final int count = _selected.length;

    return SafeArea(
      child: ConstrainedBox(
        constraints:
            BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text('Add to your calendar?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: darkText)),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text('캘린더에 추가할 일정을 선택하세요',
                  style: TextStyle(fontSize: 13, color: lightText)),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final ScheduleEvent e in widget.deadlines) _buildRow(e),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48)),
                      child: const Text('Not now · 취소'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: count == 0
                          ? null
                          : () => Navigator.of(context).pop(widget.deadlines
                              .where(_selected.contains)
                              .toList()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text('Add $count · $count개 추가'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(ScheduleEvent e) {
    final bool added = eventStore.contains(e);
    final bool past = _isPast(e);
    final String? tag = added ? 'Added · 추가됨' : (past ? 'Passed · 지남' : null);

    return CheckboxListTile(
      value: added || _selected.contains(e),
      onChanged: _canPick(e)
          ? (v) =>
              setState(() => v == true ? _selected.add(e) : _selected.remove(e))
          : null,
      activeColor: primaryBlue,
      controlAffinity: ListTileControlAffinity.leading,
      title: Text('${e.titleEn} · ${e.titleKo}',
          style: TextStyle(
              fontSize: 14, color: past && !added ? lightText : darkText)),
      subtitle: Text(
          e.startDateTime == null
              ? formatNoticeDate(e.dateTime)
              : '${formatNoticeDate(e.startDateTime!)} ~\n'
                  '${formatNoticeDate(e.dateTime)}',
          style: const TextStyle(fontSize: 12)),
      secondary: tag == null
          ? null
          : Text(tag, style: const TextStyle(fontSize: 11, color: lightText)),
    );
  }
}
