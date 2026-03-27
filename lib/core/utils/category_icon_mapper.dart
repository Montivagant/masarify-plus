import 'package:flutter/material.dart';

import '../constants/app_icons.dart';

/// Maps a [CategoryEntity.iconName] string to its [IconData] constant.
///
/// The iconName is stored as a plain string in the DB (e.g. "food", "transport").
/// This mapper converts it to the correct [AppIcons.*] constant.
/// Falls back to [AppIcons.category] for unknown names.
abstract final class CategoryIconMapper {
  static const Map<String, IconData> _map = {
    // Semantic names (used in code references)
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
    // DB-stored icon names from category_seed.dart (Material-style aliases)
    'restaurant': AppIcons.food,
    'directions_car': AppIcons.transport,
    'home': AppIcons.housing,
    'bolt': AppIcons.utilities,
    'phone_android': AppIcons.phone,
    'local_hospital': AppIcons.health,
    'shopping_cart': AppIcons.groceries,
    'school': AppIcons.education,
    'shopping_bag': AppIcons.shopping,
    'movie': AppIcons.entertainment,
    'checkroom': AppIcons.clothing,
    'spa': AppIcons.personalCare,
    'card_giftcard': AppIcons.gifts,
    'flight': AppIcons.travel,
    'more_horiz': AppIcons.otherExpense,
    'payments': AppIcons.salary,
    'work': AppIcons.freelance,
    'store': AppIcons.business,
    'redeem': AppIcons.gifts,
    'trending_up': AppIcons.investment,
    // New expense categories (v12) — icon names match seed
    'credit_score': AppIcons.installments,
    'shield': AppIcons.insurance,
    'local_gas_station': AppIcons.fuel,
    'build': AppIcons.maintenance,
    'child_care': AppIcons.kidsFamily,
    'pets': AppIcons.pets,
    'coffee': AppIcons.coffee,
    'weekend': AppIcons.homeSupplies,
    'volunteer_activism': AppIcons.charity,
    'account_balance': AppIcons.bankFees,
    'local_shipping': AppIcons.delivery,
    'savings': AppIcons.savingsTransfer,
    // Voice/transfer type icons
    'bank': AppIcons.bankFees,
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
