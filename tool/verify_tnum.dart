import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Run with: flutter run -t tool/verify_tnum.dart -d <device>
///
/// Renders two strings of digits — once with tabular figures, once without.
/// If the rendered widths differ between same-digit columns (e.g., '1' vs '8'
/// take different space when proportional but identical when tabular),
/// the font ships `tnum` and we are clear to use it globally.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const _Probe());
}

class _Probe extends StatelessWidget {
  const _Probe();

  @override
  Widget build(BuildContext context) {
    const baseSize = 48.0;
    final tabular = GoogleFonts.plusJakartaSans(
      fontSize: baseSize,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final proportional = GoogleFonts.plusJakartaSans(
      fontSize: baseSize,
    );
    return MaterialApp(
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'tnum verification — Plus Jakarta Sans',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                const _Label('1111  vs  1111  (tabular / proportional)'),
                Row(children: [
                  Text('1111', style: tabular),
                  const SizedBox(width: 32),
                  Text('1111', style: proportional),
                ]),
                const SizedBox(height: 12),
                const _Label('8888  vs  8888  (tabular / proportional)'),
                Row(children: [
                  Text('8888', style: tabular),
                  const SizedBox(width: 32),
                  Text('8888', style: proportional),
                ]),
                const SizedBox(height: 12),
                const _Label('Stacked column — should align if tabular works'),
                Text('1111', style: tabular),
                Text('8888', style: tabular),
                Text('1818', style: tabular),
                const SizedBox(height: 24),
                const Text(
                  'PASS criterion: in the stacked column, every digit '
                  'occupies the same horizontal slot. Compare proportional '
                  'rows where 1s should be narrower than 8s — those should '
                  'visibly differ.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.black54,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
