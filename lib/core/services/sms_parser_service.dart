import '../../data/database/daos/parsed_event_group_dao.dart';
import '../../data/database/daos/sms_parser_log_dao.dart';
import '../../domain/entities/category_entity.dart';
import 'ai/ai_transaction_parser.dart';
import 'connectivity_service.dart';

/// SMS inbox parser — currently disabled (kSmsEnabled = false).
///
/// Previously read SMS inbox via the telephony package, parsed financial
/// messages, deduplicated via SHA-256 hash, and stored pending candidates
/// for review. Preserved for future Pro tier re-enablement.
///
/// When re-enabling, restore the telephony package dependency, the
/// notification parser import, and the inbox scanning + AI enrichment logic.
class SmsParserService {
  SmsParserService(
    this._dao, {
    this.aiParser,
    this.categories,
    this.eventGroupDao,
    ConnectivityService? connectivityService,
  }) : _connectivityService = connectivityService ?? ConnectivityService();

  final SmsParserLogDao _dao;
  final AiTransactionParser? aiParser;
  final List<CategoryEntity>? categories;
  final ParsedEventGroupDao? eventGroupDao;
  final ConnectivityService _connectivityService;

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
