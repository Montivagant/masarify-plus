/// Pure Dart domain entity — zero Flutter/Drift imports.
class SmsParserLogEntity {
  const SmsParserLogEntity({
    required this.id,
    required this.senderAddress,
    required this.bodyHash,
    required this.body,
    required this.parsedStatus,
    required this.source,
    required this.receivedAt,
    required this.processedAt,
    this.transactionId,
    this.aiEnrichmentJson,
    this.semanticFingerprint,
    this.transferId,
  });

  final int id;
  final String senderAddress;

  /// SHA-256 of SMS body — dedup key.
  final String bodyHash;

  final String body;

  /// 'pending' | 'approved' | 'skipped' | 'failed' | 'duplicate'
  final String parsedStatus;

  final int? transactionId;

  /// 'sms' | 'notification'
  final String source;

  final DateTime receivedAt;
  final DateTime processedAt;

  /// AI enrichment JSON: {category_icon, merchant, note, confidence}
  final String? aiEnrichmentJson;

  /// Semantic fingerprint for cross-source deduplication.
  final String? semanticFingerprint;

  /// Link to transfer (for ATM withdrawal -> bank-to-cash).
  final int? transferId;

  SmsParserLogEntity copyWith({
    int? id,
    String? senderAddress,
    String? bodyHash,
    String? body,
    String? parsedStatus,
    int? transactionId,
    String? source,
    DateTime? receivedAt,
    DateTime? processedAt,
    String? aiEnrichmentJson,
    String? semanticFingerprint,
    int? transferId,
  }) =>
      SmsParserLogEntity(
        id: id ?? this.id,
        senderAddress: senderAddress ?? this.senderAddress,
        bodyHash: bodyHash ?? this.bodyHash,
        body: body ?? this.body,
        parsedStatus: parsedStatus ?? this.parsedStatus,
        transactionId: transactionId ?? this.transactionId,
        source: source ?? this.source,
        receivedAt: receivedAt ?? this.receivedAt,
        processedAt: processedAt ?? this.processedAt,
        aiEnrichmentJson: aiEnrichmentJson ?? this.aiEnrichmentJson,
        semanticFingerprint: semanticFingerprint ?? this.semanticFingerprint,
        transferId: transferId ?? this.transferId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SmsParserLogEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
