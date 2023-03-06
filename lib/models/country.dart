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

  /// The country's localization code
  /// @example `en_US`, `fr_FR`, `fr_CM`, `en`, `fr`

  const Country({
    required this.name,
    required this.code,
    required this.phone,
    required this.currencyCode,
    required this.flag,
    required this.locale,
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

    return countries.firstWhere(
      (e) => e.code == localeCode,
      orElse: () => defaultCountry,
    );
  }

  String get localeName => name;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'code': code,
      'phone': phone,
      'currencyCode': currencyCode,
      'flag': flag,
      'locale': locale,
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
  }) {
    return Country(
      name: name ?? this.name,
      code: code ?? this.code,
      phone: phone ?? this.phone,
      currencyCode: currencyCode ?? this.currencyCode,
      flag: flag ?? this.flag,
      locale: locale ?? this.locale,
    );
  }

  @override
  String toString() {
    return 'Country(name: $name, code: $code, phone: $phone, '
        'currencyCode: $currencyCode, flag: $flag, locale: $locale)';
  }

  @override
  bool operator ==(covariant Country other) {
    if (identical(this, other)) return true;

    return other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  static Country getCountryFromCode(String countryCode) {
    return countries.firstWhere(
      (e) => e.code == countryCode,
      orElse: () => Country.NULL_COUNTRY,
    );
  }

  // ignore: constant_identifier_names
  static const Country NULL_COUNTRY = Country(
    name: 'Null',
    code: "NULL",
    phone: '0000',
    currencyCode: "NULL",
    flag: "",
    locale: '',
  );
}

const defaultCountry = Country(
  name: 'United Arab Emirates',
  code: "AE",
  phone: '971',
  currencyCode: "AED",
  flag: "🇦🇪",
  locale: 'ar',
);

// data
final countries = _countriesMap.map((e) => Country.fromMap(e));

const _countriesMap = [
  {
    "name": "United Arab Emirates",
    "code": "AE",
    "phone": "971",
    "currencyCode": "AED",
    "currencySymbol": "إ.د",
    "flag": "🇦🇪",
    "locale": "ar",
  },
  {
    "name": "Saudi Arabia",
    "code": "SA",
    "phone": "966",
    "currencyCode": "SAR",
    "currencySymbol": "﷼",
    "flag": "🇸🇦",
    "locale": "ar",
  },
  {
    "name": "Qatar",
    "code": "QA",
    "phone": "974",
    "currencyCode": "QAR",
    "currencySymbol": "ق.ر",
    "flag": "🇶🇦",
    "locale": "ar",
  },
  {
    "name": "Bahrain",
    "code": "BH",
    "phone": "973",
    "currencyCode": "BHD",
    "currencySymbol": ".د.ب",
    "flag": "🇧🇭",
    "locale": "ar",
  },
  {
    "name": "Kuwait",
    "code": "KW",
    "phone": "965",
    "currencyCode": "KWD",
    "currencySymbol": "ك.د",
    "flag": "🇰🇼",
    "locale": "ar",
  },
  {
    "name": "Oman",
    "code": "OM",
    "phone": "968",
    "currencyCode": "OMR",
    "currencySymbol": ".ع.ر",
    "flag": "🇴🇲",
    "locale": "ar",
  },
  {
    "name": "United States",
    "code": "US",
    "phone": "1",
    "currencyCode": "USD",
    "currencySymbol": "\$",
    "flag": "🇺🇸",
    "locale": "en",
  },
  {
    "name": "United Kingdom",
    "code": "GB",
    "phone": "44",
    "currencyCode": "GBP",
    "currencySymbol": "£",
    "flag": "🇬🇧",
    "locale": "en,ga,cy,gd,kw",
  },
  {
    "name": "India",
    "code": "IN",
    "phone": "91",
    "currencyCode": "INR",
    "currencySymbol": "₹",
    "flag": "🇮🇳",
    "locale": "hi,en",
  },
  {
    "name": "Turkey",
    "code": "TR",
    "phone": "90",
    "currencyCode": "TRY",
    "currencySymbol": "₺",
    "flag": "🇹🇷",
    "locale": "tr,en",
  },
];

const listOfCountries = [
  "United Arab Emirates",
  "Saudi Arabia",
  "Qatar",
  "Bahrain",
  "Oman",
  "Kuwait",
  "USA",
  "UK",
  "India",
  "turkey"
];
