import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'me_models.dart';
import 'me_strings.dart';

// ================================================================
// ADD / EDIT A PLAN (bottom sheet of the Me calendar)
// 사용자가 직접 일정을 추가하거나, 연필 버튼으로 일정을 수정하는 화면
// ================================================================
//
//  Title ........ required
//  Period ....... off: one date + time / on: start ~ end
//  Memo ......... optional, shown in the plan's details
//
// Pops with the new [ScheduleEvent], or null when cancelled.
// The "what do I do?" steps and the source of an edited plan are kept.
// ================================================================

/// Opens the form. [initial] = the plan to edit (null = new plan on [day]).
Future<ScheduleEvent?> showEventFormSheet(
  BuildContext context, {
  required MeStrings s,
  ScheduleEvent? initial,
  DateTime? day,
}) {
  return showModalBottomSheet<ScheduleEvent>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _EventFormSheet(s: s, initial: initial, day: day),
  );
}

class _EventFormSheet extends StatefulWidget {
  final MeStrings s;
  final ScheduleEvent? initial;
  final DateTime? day;

  const _EventFormSheet({required this.s, this.initial, this.day});

  @override
  State<_EventFormSheet> createState() => _EventFormSheetState();
}

class _EventFormSheetState extends State<_EventFormSheet> {
  late final TextEditingController _title;
  late final TextEditingController _memo;
  late final String _initialTitle;
  late bool _isPeriod;

  /// Used only when [_isPeriod] is on.
  late DateTime _start;

  /// The single date, or the end of the period.
  late DateTime _end;

  String? _error;

  MeStrings get s => widget.s;

  @override
  void initState() {
    super.initState();
    final ScheduleEvent? e = widget.initial;
    if (e != null) {
      _initialTitle = s.isEnglish ? e.titleEn : e.titleKo;
      _memo = TextEditingController(text: e.description ?? '');
      _isPeriod = e.startDateTime != null && e.startDateTime != e.dateTime;
      _end = e.dateTime;
      _start = e.startDateTime ?? DateTime(_end.year, _end.month, _end.day, 9);
    } else {
      final DateTime d = widget.day ?? DateTime.now();
      _initialTitle = '';
      _memo = TextEditingController();
      _isPeriod = false;
      _start = DateTime(d.year, d.month, d.day, 9);
      _end = DateTime(d.year, d.month, d.day, 9);
    }
    _title = TextEditingController(text: _initialTitle);
  }

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    super.dispose();
  }

  void _togglePeriod(bool on) {
    setState(() {
      _isPeriod = on;
      _error = null;
      if (on && !_end.isAfter(_start)) {
        // Default period: from this day 09:00 to the next day 23:59.
        _start = DateTime(_end.year, _end.month, _end.day, 9);
        _end = DateTime(_end.year, _end.month, _end.day + 1, 23, 59);
      }
    });
  }

  Future<DateTime?> _pickDate(DateTime current) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day, current.hour, current.minute);
  }

  Future<DateTime?> _pickTime(DateTime current) async {
    final TimeOfDay? t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (t == null) return null;
    return DateTime(current.year, current.month, current.day, t.hour, t.minute);
  }

  void _save() {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _error = s.titleRequired);
      return;
    }
    if (_isPeriod && !_end.isAfter(_start)) {
      setState(() => _error = s.endBeforeStart);
      return;
    }

    final ScheduleEvent? old = widget.initial;
    // An unchanged title keeps both languages of a notice plan.
    final bool keepTitle = old != null && title == _initialTitle;
    final String memo = _memo.text.trim();

    Navigator.of(context).pop(ScheduleEvent(
      titleEn: keepTitle ? old.titleEn : title,
      titleKo: keepTitle ? old.titleKo : title,
      dateTime: _end,
      startDateTime: _isPeriod ? _start : null,
      description: memo.isEmpty ? null : memo,
      steps: old?.steps ?? const [],
      sourceEn: old?.sourceEn ?? s.addedByMeEn,
      sourceKo: old?.sourceKo ?? s.addedByMeKo,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Keep the form above the keyboard.
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.initial == null ? s.addPlan : s.editPlan,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: darkText,
                ),
              ),
              const SizedBox(height: 16),
              _label(s.planTitle),
              const SizedBox(height: 6),
              TextField(
                key: const Key('planTitleField'),
                controller: _title,
                autofocus: widget.initial == null,
                textInputAction: TextInputAction.next,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: _inputDecoration(s.planTitleHint),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                value: _isPeriod,
                onChanged: _togglePeriod,
                contentPadding: EdgeInsets.zero,
                activeThumbColor: primaryBlue,
                title: Text(
                  s.isPeriod,
                  style: const TextStyle(fontSize: 13, color: darkText),
                ),
              ),
              if (_isPeriod) ...[
                _dateTimeRow(s.startLabel, _start, (v) => _start = v),
                const SizedBox(height: 8),
                _dateTimeRow(s.endLabel, _end, (v) => _end = v),
              ] else
                _dateTimeRow(s.whenLabel, _end, (v) => _end = v),
              const SizedBox(height: 14),
              _label(s.memo),
              const SizedBox(height: 6),
              TextField(
                controller: _memo,
                minLines: 2,
                maxLines: 5,
                decoration: _inputDecoration(s.memoHint),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  style: TextStyle(fontSize: 12, color: Colors.red.shade700),
                ),
              ],
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(s.cancel),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: Text(s.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: lightText,
        ),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: lightText),
        isDense: true,
        contentPadding: const EdgeInsets.all(12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGray),
        ),
      );

  /// "Start   [2026. 11. 25 (수)]  [09:00]"
  Widget _dateTimeRow(
      String label, DateTime value, void Function(DateTime) assign) {
    Future<void> change(Future<DateTime?> picked) async {
      final DateTime? v = await picked;
      if (v == null || !mounted) return;
      setState(() {
        assign(v);
        _error = null;
      });
    }

    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: darkText),
          ),
        ),
        Expanded(
          child: _pickerChip(
            Icons.calendar_today_outlined,
            s.formDate(value),
            () => change(_pickDate(value)),
          ),
        ),
        const SizedBox(width: 8),
        _pickerChip(
          Icons.schedule,
          s.formTime(value),
          () => change(_pickTime(value)),
        ),
      ],
    );
  }

  Widget _pickerChip(IconData icon, String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: softBlue,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primaryBlue),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
