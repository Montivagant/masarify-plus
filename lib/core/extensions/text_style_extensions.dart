import 'package:flutter/material.dart';

extension TextStyleWeight on TextStyle? {
  TextStyle? get semiBold => this?.copyWith(fontWeight: FontWeight.w600);
  TextStyle? get bold => this?.copyWith(fontWeight: FontWeight.w700);
}
