import 'package:flutter/material.dart';

import '../../domain/entities/category_entity.dart';
import '../constants/app_icons.dart';
import 'category_icon_mapper.dart';
import 'color_utils.dart';

/// Resolved category display data for transaction lists.
typedef ResolvedCategory = ({IconData icon, Color color, String name});

/// Resolves a category ID to display data (icon, color, name).
/// Used by Dashboard, TransactionList, and WalletDetail screens.
ResolvedCategory resolveCategory({
  required int categoryId,
  required List<CategoryEntity> categories,
  required Color fallbackColor,
  required String languageCode,
}) {
  final cat = categories.where((c) => c.id == categoryId).firstOrNull;
  if (cat == null) {
    return (icon: AppIcons.category, color: fallbackColor, name: '?');
  }
  return (
    icon: CategoryIconMapper.fromName(cat.iconName),
    color: ColorUtils.fromHex(cat.colorHex),
    name: cat.displayName(languageCode),
  );
}
