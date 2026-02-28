import 'package:flutter/material.dart';

import '../constants/app_icons.dart';

/// Maps a [CategoryEntity.iconName] string to its [IconData] constant.
///
/// The iconName is stored as a plain string in the DB (e.g. "food", "transport").
/// This mapper converts it to the correct [AppIcons.*] constant.
/// Falls back to [AppIcons.category] for unknown names.
abstract final class CategoryIconMapper {
  static const Map<String, IconData> _map = {
    'food': AppIcons.food,
    'transport': AppIcons.transport,
    'housing': AppIcons.housing,
    'utilities': AppIcons.utilities,
    'phone': AppIcons.phone,
    'health': AppIcons.health,
    'groceries': AppIcons.groceries,
    'education': AppIcons.education,
    'shopping': AppIcons.shopping,
    'entertainment': AppIcons.entertainment,
    'clothing': AppIcons.clothing,
    'personal_care': AppIcons.personalCare,
    'gifts': AppIcons.gifts,
    'travel': AppIcons.travel,
    'subscriptions': AppIcons.subscriptions,
    'other_expense': AppIcons.otherExpense,
    'salary': AppIcons.salary,
    'freelance': AppIcons.freelance,
    'business': AppIcons.business,
    'investment': AppIcons.investment,
    'other_income': AppIcons.otherIncome,
    // Generic fallbacks
    'wallet': AppIcons.wallet,
    'goals': AppIcons.goals,
    'bill': AppIcons.bill,
    'recurring': AppIcons.recurring,
    'transfer': AppIcons.transfer,
  };

  /// Returns the [IconData] for the given [iconName], or [AppIcons.category] if unknown.
  static IconData fromName(String iconName) {
    return _map[iconName] ?? AppIcons.category;
  }
}
