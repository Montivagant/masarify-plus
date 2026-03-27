import 'package:flutter_riverpod/flutter_riverpod.dart';

/// null = all accounts, int = specific wallet ID.
///
/// Replaces the previous index-based `selectedAccountIndexProvider` with
/// direct wallet-ID selection. Account chips and the balance header set
/// this directly instead of using carousel page indices.
final selectedAccountIdProvider = StateProvider<int?>((ref) => null);
