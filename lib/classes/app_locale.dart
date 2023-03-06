// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AppLocale {
  final String languageName;
  final String jiffyLocaleName;
  final String languageLocale;

  AppLocale({
    required this.languageName,
    required this.jiffyLocaleName,
    required this.languageLocale,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'languageName': languageName,
      'jiffyLocaleName': jiffyLocaleName,
      'languageLocale': languageLocale,
    };
  }

  factory AppLocale.fromMap(Map<String, dynamic> map) {
    return AppLocale(
      languageName: map['languageName'] as String,
      jiffyLocaleName: map['jiffyLocaleName'] as String,
      languageLocale: map['languageLocale'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory AppLocale.fromJson(String source) =>
      AppLocale.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppLocale(languageName: $languageName '
        ' jiffyLocaleName: $jiffyLocaleName, languageLocale:'
        ' $languageLocale)';
  }

  @override
  bool operator ==(covariant AppLocale other) {
    if (identical(this, other)) return true;

    return other.languageLocale == languageLocale;
  }

  @override
  int get hashCode {
    return languageLocale.hashCode;
  }

  static List<AppLocale> get supportedLocales => [enUS];

  AppLocale copyWith({
    String? languageName,
    String? jiffyLocaleName,
    String? languageLocale,
    String? currencyLocale,
  }) {
    return AppLocale(
      languageName: languageName ?? this.languageName,
      jiffyLocaleName: jiffyLocaleName ?? this.jiffyLocaleName,
      languageLocale: languageLocale ?? this.languageLocale,
    );
  }

  /// English
  static AppLocale enUS = AppLocale(
    languageName: "English",
    languageLocale: "en_US",
    jiffyLocaleName: "en",
  );
}
