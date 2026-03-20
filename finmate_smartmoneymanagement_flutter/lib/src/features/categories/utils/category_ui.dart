import 'package:flutter/material.dart';

class CategoryUi {
  static const IconData _fallbackIcon = Icons.category_outlined;

  static final Map<String, IconData> _iconMap = {
    'restaurant_outlined': Icons.restaurant_outlined,
    'directions_car_filled': Icons.directions_car_filled,
    'shopping_bag_outlined': Icons.shopping_bag_outlined,
    'home_work_outlined': Icons.home_work_outlined,
    'favorite_border': Icons.favorite_border,
    'movie_outlined': Icons.movie_outlined,
    'shopping_cart_outlined': Icons.shopping_cart_outlined,
    'account_balance_wallet_outlined': Icons.account_balance_wallet_outlined,
    'account_balance_outlined': Icons.account_balance_outlined,
    'credit_card_outlined': Icons.credit_card_outlined,
    'payments_outlined': Icons.payments_outlined,
    'wallet': Icons.account_balance_wallet_outlined,
    'category_outlined': Icons.category_outlined,
    'receipt_long': Icons.receipt_long,
    'more_horiz': Icons.more_horiz,
    'savings_outlined': Icons.savings_outlined,
    'local_grocery_store_outlined': Icons.local_grocery_store_outlined,
  };

  static final Map<int, IconData> _codepointMap = {
    for (final icon in _iconMap.values) icon.codePoint: icon,
    _fallbackIcon.codePoint: _fallbackIcon,
  };

  static IconData iconFromString(String? value) {
    if (value == null || value.trim().isEmpty) return _fallbackIcon;
    var raw = value.trim();
    final normalized = raw.toLowerCase();
    if (normalized.startsWith('material:')) {
      raw = raw.substring('material:'.length);
    }
    final mapped = _iconMap[raw] ?? _iconMap[raw.toLowerCase()];
    if (mapped != null) return mapped;

    final parsedDecimal = int.tryParse(raw);
    if (parsedDecimal != null) {
      return _iconFromCodepoint(parsedDecimal);
    }

    final parsedHex = _tryParseHex(raw);
    if (parsedHex != null) {
      return _iconFromCodepoint(parsedHex);
    }

    return _fallbackIcon;
  }

  static Color colorFromString(
    String? value, {
    Color fallback = const Color(0xFF94A3B8),
  }) {
    if (value == null || value.trim().isEmpty) return fallback;
    final raw = value.trim();
    final parsedInt = _tryParseColorInt(raw);
    if (parsedInt == null) return fallback;
    return Color(parsedInt);
  }

  static String iconToString(IconData icon) {
    return icon.codePoint.toString();
  }

  static String colorToString(Color color) {
    final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    return '0x$hex';
  }

  static int? _tryParseHex(String raw) {
    final cleaned = raw.toLowerCase().startsWith('0x') ? raw.substring(2) : raw;
    if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(cleaned)) return null;
    return int.tryParse(cleaned, radix: 16);
  }

  static int? _tryParseColorInt(String raw) {
    var cleaned = raw;
    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.toLowerCase().startsWith('0x')) {
      cleaned = cleaned.substring(2);
    }

    if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(cleaned)) {
      cleaned = 'FF$cleaned';
    } else if (!RegExp(r'^[0-9a-fA-F]{8}$').hasMatch(cleaned)) {
      final decimal = int.tryParse(raw);
      if (decimal == null) return null;
      if (decimal <= 0xFFFFFF) {
        return decimal | 0xFF000000;
      }
      return decimal;
    }

    return int.tryParse(cleaned, radix: 16);
  }

  static IconData _iconFromCodepoint(int codepoint) {
    if (codepoint <= 0) return _fallbackIcon;
    final mapped = _codepointMap[codepoint];
    if (mapped != null) return mapped;
    return _fallbackIcon;
  }
}
