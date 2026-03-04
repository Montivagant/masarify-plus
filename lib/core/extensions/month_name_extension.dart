import '../../l10n/app_localizations.dart';

extension MonthNameExtension on AppLocalizations {
  String monthName(int month) => switch (month) {
        1 => month_1,
        2 => month_2,
        3 => month_3,
        4 => month_4,
        5 => month_5,
        6 => month_6,
        7 => month_7,
        8 => month_8,
        9 => month_9,
        10 => month_10,
        11 => month_11,
        12 => month_12,
        _ => '',
      };
}
