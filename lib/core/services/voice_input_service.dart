import 'dart:async';
import 'dart:io' show Platform;

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Voice input states.
enum VoiceState { idle, listening, processing, error }

/// Specific voice error reasons for targeted user guidance.
enum VoiceError { none, noService, noLocale, speechError }

/// Wraps the speech_to_text package for Masarify voice input.
///
/// Singleton — one instance per app lifecycle. [initialize] runs once;
/// subsequent calls are no-ops.
///
/// Usage:
/// 1. Call [initialize] once.
/// 2. Call [startListening] when the user taps the mic.
/// 3. Observe [transcriptStream] for live updates.
/// 4. Call [stopListening] when done.
class VoiceInputService {
  VoiceInputService._();

  /// Singleton instance.
  static final instance = VoiceInputService._();

  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;

  /// Tracks whether the user explicitly requested stop.
  bool _userRequestedStop = false;

  /// Accumulated transcript across auto-restart sessions.
  String _fullTranscript = '';

  /// Consecutive error count for graceful degradation.
  int _consecutiveErrors = 0;

  /// Guards against concurrent `_autoRestart()` calls.
  bool _autoRestarting = false;

  /// The resolved locale ID to use for listening.
  String? _resolvedLocale;

  /// Whether the resolved locale is Arabic.
  bool _isArabicLocale = false;

  /// Last error reason for targeted UI messages.
  VoiceError _lastError = VoiceError.none;

  /// Safety timer: forces terminal state if _onStatus never fires.
  Timer? _processingTimeout;

  final _stateController = StreamController<VoiceState>.broadcast();
  final _transcriptController = StreamController<String>.broadcast();

  /// Stream of voice states (idle → listening → processing → idle).
  Stream<VoiceState> get stateStream => _stateController.stream;

  /// Stream of live transcript updates.
  Stream<String> get transcriptStream => _transcriptController.stream;

  /// Whether STT is available on this device.
  bool get isAvailable => _available;

  /// Whether the resolved locale is Arabic.
  bool get isArabicLocale => _isArabicLocale;

  /// The resolved locale ID (e.g. 'ar-EG', 'en-US') for display.
  String? get resolvedLocale => _resolvedLocale;

  /// The last error reason (for targeted UI messages).
  VoiceError get lastError => _lastError;

  /// Initialize the speech-to-text engine.
  Future<bool> initialize() async {
    if (_initialized) return _available;

    try {
      _available = await _speech.initialize(
        onError: _onError,
        onStatus: _onStatus,
        debugLogging: kDebugMode,
        options: [SpeechToText.androidIntentLookup],
      );

      if (!_available) {
        _lastError = VoiceError.noService;
      } else {
        _resolvedLocale = await _findBestLocale();
        if (_resolvedLocale == null) {
          _lastError = VoiceError.noLocale;
          _available = false;
        } else {
          _lastError = VoiceError.none;
        }
      }

      _initialized = true;
    } catch (_) {
      _lastError = VoiceError.noService;
      _available = false;
      _initialized = true;
    }

    return _available;
  }

  /// Find the best available locale with Arabic preference and system fallback.
  Future<String?> _findBestLocale() async {
    final locales = await _speech.locales();
    final ids = locales.map((l) => l.localeId).toSet();

    // Prefer Egyptian Arabic
    if (ids.contains('ar-EG')) { _isArabicLocale = true; return 'ar-EG'; }
    if (ids.contains('ar_EG')) { _isArabicLocale = true; return 'ar_EG'; }

    // Any Arabic locale
    final anyAr = locales.firstWhereOrNull(
      (l) => l.localeId.startsWith('ar'),
    );
    if (anyAr != null) { _isArabicLocale = true; return anyAr.localeId; }

    // Fallback: device system locale
    final systemLocale = await _speech.systemLocale();
    if (systemLocale != null) {
      _isArabicLocale = false;
      return systemLocale.localeId;
    }

    return null; // Only fail if NO locales at all
  }

  /// Reset initialization state so the next [initialize] call retries.
  void resetInitialization() {
    _processingTimeout?.cancel();
    _autoRestarting = false;
    _userRequestedStop = true; // Stop any pending auto-restart Future.delayed
    _speech.cancel();
    _initialized = false;
    _available = false;
    _resolvedLocale = null;
    _isArabicLocale = false;
    _lastError = VoiceError.none;
    _fullTranscript = '';
    _consecutiveErrors = 0;
  }

  /// Start listening for voice input in Arabic.
  Future<void> startListening() async {
    if (!_available || _resolvedLocale == null) return;

    _processingTimeout?.cancel();
    _userRequestedStop = false;
    _autoRestarting = false;
    _fullTranscript = '';
    _consecutiveErrors = 0;
    _stateController.add(VoiceState.listening);
    _transcriptController.add('');

    await _startSession();
  }

  /// Internal: start a single listen session (used for initial + auto-restart).
  Future<void> _startSession() async {
    await _speech.listen(
      onResult: _onResult,
      localeId: _resolvedLocale,
      listenOptions: SpeechListenOptions(
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Stop listening and finalize the transcript.
  Future<void> stopListening() async {
    _userRequestedStop = true;
    _stateController.add(VoiceState.processing);
    await _speech.stop();

    // Safety: if _onStatus never fires, force terminal state after 2s.
    _processingTimeout?.cancel();
    _processingTimeout = Timer(const Duration(seconds: 2), _emitTerminalState);
  }

  /// Cancel listening without processing.
  Future<void> cancel() async {
    _userRequestedStop = true;
    _processingTimeout?.cancel();
    await _speech.cancel();
    _stateController.add(VoiceState.idle);
    _transcriptController.add('');
  }

  void _onResult(SpeechRecognitionResult result) {
    // Filter out low-confidence results.
    // confidence == -1 means the platform doesn't report confidence.
    // WS-2 fix: lower threshold for Arabic STT (returns 0.3-0.6 typically).
    final minConfidence = _isArabicLocale ? 0.25 : 0.5;
    if (result.confidence != -1 && result.confidence < minConfidence) return;

    _consecutiveErrors = 0;

    // Build full transcript: accumulated + current segment
    final currentText = result.recognizedWords;
    final displayText =
        _fullTranscript.isEmpty ? currentText : '$_fullTranscript $currentText';
    _transcriptController.add(displayText.trim());

    if (result.finalResult) {
      // Accumulate final result for auto-restart scenarios
      _fullTranscript = displayText.trim();
      // Don't emit state here — let _onStatus / _emitTerminalState handle it.
      // This prevents a late finalResult from re-emitting processing after
      // the stop flow has already resolved to a terminal state.
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _processingTimeout?.cancel();
      if (_userRequestedStop) {
        _emitTerminalState();
      } else if (Platform.isAndroid) {
        // Android 5-second silence timeout — auto-restart
        _autoRestart();
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (_userRequestedStop) return; // stop flow owns state
    _consecutiveErrors++;

    // Only transition to error state after repeated failures
    // or on terminal errors
    if (error.errorMsg == 'error_speech_timeout' ||
        error.errorMsg == 'error_no_match') {
      if (_consecutiveErrors >= 3) {
        _lastError = VoiceError.speechError;
        _stateController.add(VoiceState.error);
      } else if (!_userRequestedStop && Platform.isAndroid) {
        // Silence timeout — try auto-restart
        _autoRestart();
      }
    } else {
      // For other errors, report immediately
      _lastError = VoiceError.speechError;
      _stateController.add(VoiceState.error);
    }
  }

  /// Emit the correct terminal state after stop resolves.
  void _emitTerminalState() {
    if (_fullTranscript.trim().isNotEmpty) {
      _stateController.add(VoiceState.processing);
    } else {
      _stateController.add(VoiceState.idle);
    }
  }

  /// Auto-restart listening after Android's 5-second silence timeout.
  Future<void> _autoRestart() async {
    if (_userRequestedStop || _autoRestarting) return;
    _autoRestarting = true;

    // WS-2 fix: increased from 200ms to 500ms to avoid error_recognizer_busy.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (_userRequestedStop) {
      _autoRestarting = false;
      return;
    }

    _stateController.add(VoiceState.listening);
    await _startSession();
    _autoRestarting = false;
  }

  // No dispose() — this is a singleton with broadcast streams.
  // Closing StreamControllers would permanently break all future listeners.
}
