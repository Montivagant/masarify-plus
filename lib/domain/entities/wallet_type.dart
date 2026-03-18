/// Domain-level wallet type constants — pure Dart, zero Flutter/Drift imports.
abstract final class WalletType {
  static const physicalCash = 'physical_cash';
  static const bank = 'bank';
  static const mobileWallet = 'mobile_wallet';
  static const creditCard = 'credit_card';
  static const prepaidCard = 'prepaid_card';
  static const investment = 'investment';

  /// All valid wallet types.
  static const all = {
    physicalCash,
    bank,
    mobileWallet,
    creditCard,
    prepaidCard,
    investment,
  };

  /// Types selectable by users (physical_cash is system-only).
  static const userSelectable = {
    bank,
    mobileWallet,
    creditCard,
    prepaidCard,
    investment,
  };
}
