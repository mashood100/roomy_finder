// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: constant_identifier_names

import 'dart:convert';
import 'dart:io';

/// A supported country in the system eligle for online transaction
/// an support atleast one payment method used on the platform
class Country {
  /// The country's name @example **Cameroon**, **China**
  final String name;

  /// The contry's alpha_2 code
  final String code;

  /// The country's phone code @example `237`, `1`
  final String phone;

  /// The country's 3 digits currency code
  /// @example `XAF`, `USD`, `NGN`, `GHN`
  final String currencyCode;

  /// The country's emoji flag
  final String flag;

  /// The locale language codes seperated bu commas
  /// @example `fr,en`, `id`
  final String locale;

  /// The currency convertion rate respect to AEU
  final num aedCurrencyConvertRate;

  /// The country's localization code
  /// @example `en_US`, `fr_FR`, `fr_CM`, `en`, `fr`

  const Country({
    required this.name,
    required this.code,
    required this.phone,
    required this.currencyCode,
    required this.flag,
    required this.locale,
    required this.aedCurrencyConvertRate,
  });

  String get flagPhone => "$flag +$phone";

  static Country get currentCountry {
    final splitLocales = Platform.localeName.split('_');
    final String localeCode;

    if (splitLocales.isEmpty) {
      localeCode = '';
    } else if (splitLocales.length == 2) {
      localeCode = splitLocales[1];
    } else {
      localeCode = '';
    }

    return supporttedCountries.firstWhere(
      (e) => e.code == localeCode,
      orElse: () => UAE,
    );
  }

  String get localeName => name;
  bool get isUAE => code == "AE";
  bool get isSA => code == "SA";

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'phone': phone,
      'currencyCode': currencyCode,
      'flag': flag,
      'locale': locale,
      'aedCurrencyConvertRate': aedCurrencyConvertRate,
    };
  }

  factory Country.fromMap(Map<String, dynamic> map) {
    return Country(
      name: map['name'] as String,
      code: map['code'] as String,
      phone: map['phone'] as String,
      currencyCode: map['currencyCode'] as String,
      flag: map['flag'] as String,
      locale: map['locale'] as String,
      aedCurrencyConvertRate: map['aedCurrencyConvertRate'] as num,
    );
  }

  String toJson() => json.encode(toMap());

  factory Country.fromJson(String source) =>
      Country.fromMap(json.decode(source) as Map<String, dynamic>);

  Country copyWith({
    String? name,
    String? code,
    String? phone,
    String? currencyCode,
    String? flag,
    String? locale,
    num? aedCurrencyConvertRate,
  }) {
    return Country(
      name: name ?? this.name,
      code: code ?? this.code,
      phone: phone ?? this.phone,
      currencyCode: currencyCode ?? this.currencyCode,
      flag: flag ?? this.flag,
      locale: locale ?? this.locale,
      aedCurrencyConvertRate:
          aedCurrencyConvertRate ?? this.aedCurrencyConvertRate,
    );
  }

  @override
  String toString() {
    return 'Country(name: $name, code: $code, phone: $phone, '
        'currencyCode: $currencyCode, flag: $flag, locale: $locale)';
  }

  @override
  bool operator ==(covariant Country other) {
    return other.code == code;
  }

  @override
  int get hashCode {
    return code.hashCode;
  }

  static Country getCountryFromCode(String countryCode) {
    return supporttedCountries.firstWhere(
      (e) => e.code == countryCode,
      orElse: () => Country.NULL_COUNTRY,
    );
  }

  static const Country NULL_COUNTRY = Country(
    name: 'Null',
    code: "NULL",
    phone: '0000',
    currencyCode: "NULL",
    flag: "",
    locale: '',
    aedCurrencyConvertRate: 0,
  );

  static const UAE = Country(
    name: 'United Arab Emirates',
    code: "AE",
    phone: '966',
    currencyCode: "AED",
    flag: "🇦🇪",
    locale: 'ar',
    aedCurrencyConvertRate: 1,
  );
  static const SAUDI_ARABIA = Country(
    name: 'Saudi Arabia',
    code: "SA",
    phone: '971',
    currencyCode: "SAR",
    flag: "🇸🇦",
    locale: 'ar',
    aedCurrencyConvertRate: 1.0211028,
  );
}

// data
final supporttedCountries = _countriesMap.map((e) => Country.fromMap(e));

const _countriesMap = [
  {
    "name": "United Arab Emirates",
    "code": "AE",
    "phone": "971",
    "currencyCode": "AED",
    "currencySymbol": "إ.د",
    "flag": "🇦🇪",
    "locale": "ar",
    "aedCurrencyConvertRate": 1,
  },
  {
    "name": "Saudi Arabia",
    "code": "SA",
    "phone": "966",
    "currencyCode": "SAR",
    "currencySymbol": "﷼",
    "flag": "🇸🇦",
    "locale": "ar",
    "aedCurrencyConvertRate": 1.0211028,
  },
  {
    "name": "Qatar",
    "code": "QA",
    "phone": "974",
    "currencyCode": "QAR",
    "currencySymbol": "ق.ر",
    "flag": "🇶🇦",
    "locale": "ar",
    "aedCurrencyConvertRate": 0.99115044,
  },
  {
    "name": "Bahrain",
    "code": "BH",
    "phone": "973",
    "currencyCode": "BHD",
    "currencySymbol": ".د.ب",
    "flag": "🇧🇭",
    "locale": "ar",
    "aedCurrencyConvertRate": 0.10238257,
  },
  {
    "name": "Kuwait",
    "code": "KW",
    "phone": "965",
    "currencyCode": "KWD",
    "currencySymbol": "ك.د",
    "flag": "🇰🇼",
    "locale": "ar",
    "aedCurrencyConvertRate": 0.083579123,
  },
  {
    "name": "Oman",
    "code": "OM",
    "phone": "968",
    "currencyCode": "OMR",
    "currencySymbol": ".ع.ر",
    "flag": "🇴🇲",
    "locale": "ar",
    "aedCurrencyConvertRate": 0.10484834,
  },
  {
    "name": "United States",
    "code": "US",
    "phone": "1",
    "currencyCode": "USD",
    "currencySymbol": "\$",
    "flag": "🇺🇸",
    "locale": "en",
    "aedCurrencyConvertRate": 0.27229408,
  },
  {
    "name": "United Kingdom",
    "code": "GB",
    "phone": "44",
    "currencyCode": "GBP",
    "currencySymbol": "£",
    "flag": "🇬🇧",
    "locale": "en,ga,cy,gd,kw",
    "aedCurrencyConvertRate": 0.22630919,
  },
  {
    "name": "India",
    "code": "IN",
    "phone": "91",
    "currencyCode": "INR",
    "currencySymbol": "₹",
    "flag": "🇮🇳",
    "locale": "hi,en",
    "aedCurrencyConvertRate": 22.318706,
  },
  {
    "name": "Turkey",
    "code": "TR",
    "phone": "90",
    "currencyCode": "TRY",
    "currencySymbol": "₺",
    "flag": "🇹🇷",
    "locale": "tr,en",
    "aedCurrencyConvertRate": 5.1619963,
  },
];

final allCountriesNames = supporttedCountries.map((e) => e.name).toList();
