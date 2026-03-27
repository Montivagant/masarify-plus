// Pure Dart adapter — zero Flutter/Drift imports.
//
// Converts a TransferEntity into two synthetic TransactionEntity entries
// (sender and receiver) so transfers can appear in unified transaction lists.
//
// Synthetic IDs are negative to avoid collision with real transaction IDs:
//   fromEntry.id = -(transfer.id * 2)
//   toEntry.id   = -(transfer.id * 2 + 1)

import '../entities/transaction_entity.dart';
import '../entities/transfer_entity.dart';

/// Tag constants used to mark synthetic transfer entries.
const String kTransferSenderTag = 'role:sender';
const String kTransferReceiverTag = 'role:receiver';

/// Returns true if [tags] indicate a sender (outgoing) transfer entry.
bool isTransferSender(String tags) => tags.contains(kTransferSenderTag);

/// Returns true if [tags] indicate a receiver (incoming) transfer entry.
bool isTransferReceiver(String tags) => tags.contains(kTransferReceiverTag);

/// Extracts the counterpart wallet ID from a synthetic transfer entry's tags.
/// Returns null if the tag is missing or malformed.
int? counterpartWalletId(String tags) {
  final match = RegExp(r'counterpart:(\d+)').firstMatch(tags);
  return match != null ? int.tryParse(match.group(1)!) : null;
}

/// Converts a single [TransferEntity] into two synthetic [TransactionEntity]
/// entries: one for the sender (from-wallet) and one for the receiver (to-wallet).
///
/// The [walletNames] map provides display names for the route label
/// (e.g., "CIB → NBE"). Pass an empty map to use generic labels.
({TransactionEntity fromEntry, TransactionEntity toEntry}) transferToActivities(
  TransferEntity transfer, {
  Map<int, String> walletNames = const {},
}) {
  assert(transfer.fromWalletId > 0, 'fromWalletId must be positive');
  assert(transfer.toWalletId > 0, 'toWalletId must be positive');
  assert(
    transfer.fromWalletId != transfer.toWalletId,
    'from and to must differ',
  );

  final fromName = walletNames[transfer.fromWalletId] ?? '';
  final toName = walletNames[transfer.toWalletId] ?? '';
  final routeLabel =
      fromName.isNotEmpty && toName.isNotEmpty ? '$fromName → $toName' : '';

  final fromEntry = TransactionEntity(
    id: -(transfer.id * 2),
    walletId: transfer.fromWalletId,
    categoryId: 0,
    amount: transfer.amount + transfer.fee,
    type: 'transfer',
    currencyCode: 'EGP',
    title: routeLabel,
    transactionDate: transfer.transferDate,
    tags: '$kTransferSenderTag,counterpart:${transfer.toWalletId}',
    source: 'transfer',
    isRecurring: false,
    createdAt: transfer.createdAt,
    updatedAt: transfer.createdAt,
    note: transfer.note,
  );

  final toEntry = TransactionEntity(
    id: -(transfer.id * 2 + 1),
    walletId: transfer.toWalletId,
    categoryId: 0,
    amount: transfer.amount,
    type: 'transfer',
    currencyCode: 'EGP',
    title: routeLabel,
    transactionDate: transfer.transferDate,
    tags: '$kTransferReceiverTag,counterpart:${transfer.fromWalletId}',
    source: 'transfer',
    isRecurring: false,
    createdAt: transfer.createdAt,
    updatedAt: transfer.createdAt,
    note: transfer.note,
  );

  return (fromEntry: fromEntry, toEntry: toEntry);
}

/// Converts a list of [TransferEntity] into synthetic [TransactionEntity]
/// entries, optionally filtering to only include entries relevant to
/// [filterWalletId].
List<TransactionEntity> transfersToActivities(
  List<TransferEntity> transfers, {
  int? filterWalletId,
  Map<int, String> walletNames = const {},
}) {
  final entries = <TransactionEntity>[];
  for (final transfer in transfers) {
    final pair = transferToActivities(transfer, walletNames: walletNames);
    if (filterWalletId == null) {
      entries.add(pair.fromEntry);
      entries.add(pair.toEntry);
    } else {
      if (pair.fromEntry.walletId == filterWalletId) {
        entries.add(pair.fromEntry);
      }
      if (pair.toEntry.walletId == filterWalletId) {
        entries.add(pair.toEntry);
      }
    }
  }
  return entries;
}
