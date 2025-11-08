import 'package:Tijaraa/utils/constant.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:Tijaraa/utils/extensions/extensions.dart';
extension NumberFormatter on double {
  String get currencyFormat {
    final formatted = this.decimalFormat;

    return Constant.currencyPositionIsLeft
        ? '${Constant.currencySymbol} $formatted'
        : '$formatted ${Constant.currencySymbol}';
  }

  String get decimalFormat {
    final supportsLocale = NumberFormat.localeExists(Constant.currentLocale);
    final numberFormat = NumberFormat.decimalPatternDigits(
      locale: supportsLocale ? Constant.currentLocale : Intl.defaultLocale,
      decimalDigits: 2,
    );
    return numberFormat.format(this);
  }
}
extension StringCurrencyFormatter on String? {
  // Converts the string price to a double and formats it.
  String formatCurrency(BuildContext context) {
    if (this == null || this!.isEmpty) {
      return ''; // Return empty string or appropriate placeholder
    }
    try {
      final double value = double.parse(this!);
      return value.currencyFormat; // Call the logic from your NumberFormatter
    } catch (e) {
      // Handle non-numeric strings if necessary
      return this!;
    }
  }
}