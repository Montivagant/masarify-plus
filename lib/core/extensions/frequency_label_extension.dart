import '../../l10n/app_localizations.dart';

extension FrequencyLabelExtension on AppLocalizations {
  String frequencyLabel(String freq) => switch (freq) {
        'once' => recurring_frequency_once,
        'daily' => recurring_frequency_daily,
        'weekly' => recurring_frequency_weekly,
        'monthly' => recurring_frequency_monthly,
        'yearly' => recurring_frequency_yearly,
        'custom' => recurring_frequency_custom,
        _ => freq,
      };
}
