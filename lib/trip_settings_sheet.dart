import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'quest_data.dart';

/// Opens the My stay sheet with the [current] values.
/// Returns the new settings, or null if the sheet is closed without saving.
Future<TripSettings?> showTripSettingsSheet(
  BuildContext context,
  TripSettings current,
) {
  return showModalBottomSheet<TripSettings>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (BuildContext context) => _TripSettingsSheet(current: current),
  );
}

class _TripSettingsSheet extends StatefulWidget {
  final TripSettings current;

  const _TripSettingsSheet({required this.current});

  @override
  State<_TripSettingsSheet> createState() => _TripSettingsSheetState();
}

class _TripSettingsSheetState extends State<_TripSettingsSheet> {
  late bool _hideCompleted;
  DateTime? _arrival;
  DateTime? _departure;
  String? _error; // Shown in red when the dates do not make sense

  // Today without the time, so day calculations stay simple.
  final DateTime _today = DateUtils.dateOnly(DateTime.now());

  @override
  void initState() {
    super.initState();
    // Start with the saved values.
    _hideCompleted = widget.current.hideCompleted;
    _arrival = widget.current.arrivalDate;
    _departure = widget.current.departureDate;
  }

  /// Keeps [date] between [min] and [max].
  /// The date picker crashes if its first date is outside its range.
  DateTime _clamp(DateTime date, DateTime min, DateTime max) {
    if (date.isBefore(min)) return min;
    if (date.isAfter(max)) return max;
    return date;
  }

  /// Short date text like "2026. 9. 1".
  String _format(DateTime? date) {
    if (date == null) return 'Not set · 아직 없음';
    return '${date.year}. ${date.month}. ${date.day}';
  }

  /// Arrival can be from 1 year ago to 1 year from today.
  Future<void> _pickArrival() async {
    final DateTime first = DateTime(_today.year - 1, _today.month, _today.day);
    final DateTime last = DateTime(_today.year + 1, _today.month, _today.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _clamp(_arrival ?? _today, first, last),
      firstDate: first,
      lastDate: last,
      helpText: 'Arrival date · 입국일',
    );
    if (picked == null) return; // Closed without picking
    setState(() {
      _arrival = picked;
      _error = null;
    });
  }

  /// Return date can be from the day after arrival to 2 years after arrival.
  Future<void> _pickDeparture() async {
    final DateTime start = _arrival ?? _today;
    final DateTime first = start.add(const Duration(days: 1));
    final DateTime last = DateTime(start.year + 2, start.month, start.day);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _clamp(_departure ?? first, first, last),
      firstDate: first,
      lastDate: last,
      helpText: 'Return date · 귀국일',
    );
    if (picked == null) return;
    setState(() {
      _departure = picked;
      _error = null;
    });
  }

  /// Checks the dates, then closes the sheet with the new settings.
  void _save() {
    final DateTime? arrival = _arrival;
    final DateTime? departure = _departure;

    // Example: arrival was changed to a day after the departure date.
    if (arrival != null && departure != null && !departure.isAfter(arrival)) {
      setState(() => _error = 'Return date must be after arrival.');
      return;
    }

    final TripSettings result = TripSettings(
      arrivalDate: arrival,
      departureDate: departure,
      hideCompleted: _hideCompleted,
      hideRecommendations: widget.current.hideRecommendations,
      hideReturnRecommendations: widget.current.hideReturnRecommendations,
    );
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'My stay · 내 체류 정보',
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: darkText),
          ),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flight_land, color: primaryBlue),
            title: const Text('Arrival date · 입국일'),
            subtitle: Text(_format(_arrival)),
            trailing:
                const Icon(Icons.edit_calendar_outlined, color: lightText),
            onTap: _pickArrival,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flight_takeoff, color: primaryBlue),
            title: const Text('Return date · 귀국일'),
            subtitle: Text(_format(_departure)),
            trailing:
                const Icon(Icons.edit_calendar_outlined, color: lightText),
            onTap: _pickDeparture,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 4),
              child: Text(
                _error!,
                style: const TextStyle(fontSize: 12, color: Colors.red),
              ),
            ),
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Hide completed quests'),
            subtitle: const Text('완료한 퀘스트 숨기기'),
            value: _hideCompleted,
            onChanged: (bool value) => setState(() => _hideCompleted = value),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Save · 저장',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
