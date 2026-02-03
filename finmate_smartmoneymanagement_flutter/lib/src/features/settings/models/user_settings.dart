class UserSettings {
  UserSettings({
    required this.darkMode,
    required this.language,
    required this.defaultCurrency,
    required this.notificationEnabled,
    required this.budgetAlertThreshold,
    required this.roundingScale,
    required this.roundingMode,
  });

  final bool darkMode;
  final String language;
  final String defaultCurrency;
  final bool notificationEnabled;
  final int budgetAlertThreshold;
  final int roundingScale;
  final String roundingMode;

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      darkMode: json['darkMode'] == true,
      language: json['language']?.toString() ?? 'EN',
      defaultCurrency: json['defaultCurrency']?.toString() ?? 'VND',
      notificationEnabled: json['notificationEnabled'] == true,
      budgetAlertThreshold: json['budgetAlertThreshold'] is int
          ? json['budgetAlertThreshold'] as int
          : int.tryParse(json['budgetAlertThreshold']?.toString() ?? '80') ?? 80,
      roundingScale: json['roundingScale'] is int
          ? json['roundingScale'] as int
          : int.tryParse(json['roundingScale']?.toString() ?? '2') ?? 2,
      roundingMode: json['roundingMode']?.toString() ?? 'HALF_UP',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'darkMode': darkMode,
      'language': language,
      'defaultCurrency': defaultCurrency,
      'notificationEnabled': notificationEnabled,
      'budgetAlertThreshold': budgetAlertThreshold,
      'roundingScale': roundingScale,
      'roundingMode': roundingMode,
    };
  }
}
