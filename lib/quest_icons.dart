import 'package:flutter/material.dart';

/// Icons the user can pick for a quest.
/// Only the key (like 'home') is saved, so it is easy to store later.
const Map<String, IconData> questIcons = {
  'flag': Icons.flag_outlined,
  'phone': Icons.phone_iphone,
  'arc': Icons.badge,
  'bank': Icons.account_balance,
  'home': Icons.home_outlined,
  'school': Icons.school_outlined,
  'food': Icons.restaurant,
  'transport': Icons.directions_subway,
  'hospital': Icons.local_hospital_outlined,
  'gift': Icons.card_giftcard,
  'wave': Icons.waving_hand_outlined,
};


/// Icon for each time group on the Return tab.
const Map<String, IconData> phaseIcons = {
  'anytime': Icons.schedule,
  'lastWeek': Icons.date_range,
  'returnDay': Icons.flight_takeoff,
};
