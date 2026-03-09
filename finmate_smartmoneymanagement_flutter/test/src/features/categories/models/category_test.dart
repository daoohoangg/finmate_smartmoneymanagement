import 'package:flutter_test/flutter_test.dart';
import 'package:finmate_smartmoneymanagement_flutter/src/features/categories/models/category.dart';

void main() {
  group('Category Model', () {
    test('fromJson creates correct instance from standard valid JSON', () {
      final json = {
        'id': 1,
        'name': 'Food',
        'type': 'EXPENSE',
        'group': 'NECESSARY',
        'primary': true,
        'icon': 'food_icon',
        'color': '#FFFFFF',
        'parentId': 2,
        'systemCategory': true,
      };

      final category = Category.fromJson(json);

      expect(category.id, 1);
      expect(category.name, 'Food');
      expect(category.type, CategoryType.expense);
      expect(category.group, CategoryGroup.necessary);
      expect(category.isPrimary, true);
      expect(category.icon, 'food_icon');
      expect(category.color, '#FFFFFF');
      expect(category.parentId, 2);
      expect(category.isSystemCategory, true);
    });

    test('fromJson handles alternative boolean keys and string numbers', () {
      final json = {
        'id': '1',
        'type': 'INCOME',
        'group': 'ACCUMULATION',
        'isPrimary': 'true', // Uses isPrimary instead of primary
        'isSystemCategory': 'false', // Uses isSystemCategory instead of systemCategory
      };

      final category = Category.fromJson(json);

      expect(category.id, 1);
      expect(category.type, CategoryType.income);
      expect(category.group, CategoryGroup.accumulation);
      expect(category.isPrimary, true);
      expect(category.isSystemCategory, false);
      expect(category.parentId, isNull);
    });
  });

  group('CategoryTypeX', () {
    test('apiValue and fromApi work correctly', () {
      expect(CategoryType.expense.apiValue, 'EXPENSE');
      expect(CategoryType.income.apiValue, 'INCOME');

      expect(CategoryTypeX.fromApi('EXPENSE'), CategoryType.expense);
      expect(CategoryTypeX.fromApi('INCOME'), CategoryType.income);
      expect(CategoryTypeX.fromApi('UNKNOWN'), CategoryType.expense); // Fallback
    });
  });

  group('CategoryGroupX', () {
    test('apiValue and fromApi work correctly', () {
      expect(CategoryGroup.necessary.apiValue, 'NECESSARY');
      expect(CategoryGroup.accumulation.apiValue, 'ACCUMULATION');
      expect(CategoryGroup.flexibility.apiValue, 'FLEXIBILITY');

      expect(CategoryGroupX.fromApi('NECESSARY'), CategoryGroup.necessary);
      expect(CategoryGroupX.fromApi('ACCUMULATION'), CategoryGroup.accumulation);
      expect(CategoryGroupX.fromApi('FLEXIBILITY'), CategoryGroup.flexibility);
      expect(CategoryGroupX.fromApi('UNKNOWN'), isNull); // Falls back to null usually or handles gracefully if not required
    });
  });
}
