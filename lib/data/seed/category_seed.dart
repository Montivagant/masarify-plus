import 'package:drift/drift.dart';

import '../../data/database/app_database.dart';

/// All 22 default categories to seed on first launch.
/// Called by CategoryRepository when the categories table is empty.
abstract final class CategorySeed {
  static List<CategoriesCompanion> get all => [
        ..._expenseCategories,
        ..._incomeCategories,
      ];

  static final List<CategoriesCompanion> _expenseCategories = [
    _cat(
      name: 'Food & Dining', nameAr: 'أكل ومشروبات',
      icon: 'restaurant', color: '#FF6B6B',
      type: 'expense', group: 'needs', order: 1,
    ),
    _cat(
      name: 'Transport', nameAr: 'مواصلات',
      icon: 'directions_car', color: '#4ECDC4',
      type: 'expense', group: 'needs', order: 2,
    ),
    _cat(
      name: 'Housing & Rent', nameAr: 'سكن وإيجار',
      icon: 'home', color: '#45B7D1',
      type: 'expense', group: 'needs', order: 3,
    ),
    _cat(
      name: 'Utilities', nameAr: 'فواتير (كهرباء/مياه/غاز)',
      icon: 'bolt', color: '#96CEB4',
      type: 'expense', group: 'needs', order: 4,
    ),
    _cat(
      name: 'Phone & Internet', nameAr: 'موبايل وإنترنت',
      icon: 'phone_android', color: '#6C5CE7',
      type: 'expense', group: 'needs', order: 5,
    ),
    _cat(
      name: 'Healthcare', nameAr: 'صحة وأدوية',
      icon: 'local_hospital', color: '#E17055',
      type: 'expense', group: 'needs', order: 6,
    ),
    _cat(
      name: 'Groceries', nameAr: 'بقالة وسوبرماركت',
      icon: 'shopping_cart', color: '#00B894',
      type: 'expense', group: 'needs', order: 7,
    ),
    _cat(
      name: 'Education', nameAr: 'تعليم',
      icon: 'school', color: '#0984E3',
      type: 'expense', group: 'needs', order: 8,
    ),
    _cat(
      name: 'Shopping', nameAr: 'تسوق',
      icon: 'shopping_bag', color: '#E84393',
      type: 'expense', group: 'wants', order: 9,
    ),
    _cat(
      name: 'Entertainment', nameAr: 'ترفيه',
      icon: 'movie', color: '#FD79A8',
      type: 'expense', group: 'wants', order: 10,
    ),
    _cat(
      name: 'Clothing', nameAr: 'ملابس',
      icon: 'checkroom', color: '#A29BFE',
      type: 'expense', group: 'wants', order: 11,
    ),
    _cat(
      name: 'Personal Care', nameAr: 'عناية شخصية',
      icon: 'spa', color: '#FFEAA7',
      type: 'expense', group: 'wants', order: 12,
    ),
    _cat(
      name: 'Gifts & Donations', nameAr: 'هدايا وتبرعات',
      icon: 'card_giftcard', color: '#FAB1A0',
      type: 'expense', group: 'wants', order: 13,
    ),
    _cat(
      name: 'Travel', nameAr: 'سفر',
      icon: 'flight', color: '#55A3F0',
      type: 'expense', group: 'wants', order: 14,
    ),
    _cat(
      name: 'Subscriptions', nameAr: 'اشتراكات',
      icon: 'subscriptions', color: '#636E72',
      type: 'expense', group: 'wants', order: 15,
    ),
    _cat(
      name: 'Other Expense', nameAr: 'مصروفات أخرى',
      icon: 'more_horiz', color: '#B2BEC3',
      type: 'expense', group: null, order: 16,
    ),
  ];

  static final List<CategoriesCompanion> _incomeCategories = [
    _cat(
      name: 'Salary', nameAr: 'مرتب',
      icon: 'payments', color: '#00B894',
      type: 'income', group: null, order: 17,
    ),
    _cat(
      name: 'Freelance', nameAr: 'عمل حر',
      icon: 'work', color: '#00CEC9',
      type: 'income', group: null, order: 18,
    ),
    _cat(
      name: 'Business', nameAr: 'مشروع',
      icon: 'store', color: '#0984E3',
      type: 'income', group: null, order: 19,
    ),
    _cat(
      name: 'Gifts Received', nameAr: 'هدايا مستلمة',
      icon: 'redeem', color: '#E17055',
      type: 'income', group: null, order: 20,
    ),
    _cat(
      name: 'Investment Returns', nameAr: 'عوائد استثمار',
      icon: 'trending_up', color: '#6C5CE7',
      type: 'income', group: null, order: 21,
    ),
    _cat(
      name: 'Other Income', nameAr: 'دخل آخر',
      icon: 'more_horiz', color: '#B2BEC3',
      type: 'income', group: null, order: 22,
    ),
  ];

  static CategoriesCompanion _cat({
    required String name,
    required String nameAr,
    required String icon,
    required String color,
    required String type,
    required String? group,
    required int order,
  }) =>
      CategoriesCompanion.insert(
        name: name,
        nameAr: nameAr,
        iconName: icon,
        colorHex: color,
        type: type,
        groupType: Value(group),
        displayOrder: Value(order),
      );
}
