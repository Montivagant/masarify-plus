import '../../data/database/daos/sms_parser_log_dao.dart';

/// SMS inbox parser — currently disabled (kSmsEnabled = false).
///
/// Previously read SMS inbox via the telephony package, parsed financial
/// messages, deduplicated via SHA-256 hash, and stored pending candidates
/// for review. Preserved for future Pro tier re-enablement.
///
/// When re-enabling, restore the telephony package dependency, the
/// notification parser import, and the inbox scanning + AI enrichment logic.
class SmsParserService {
  SmsParserService(SmsParserLogDao dao);

  /// Scan SMS inbox for financial messages.
  /// Currently disabled (kSmsEnabled = false) — returns 0.
  /// Preserved for future Pro tier re-enablement.
  Future<int> scanInbox() async {
    // SMS parsing disabled in AI-first pivot.
    // When re-enabling, restore the telephony package dependency
    // and the inbox scanning call.
    return 0;
  }
}
