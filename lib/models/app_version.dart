import 'dart:convert';

class AppVersion {
  final String version;
  final String url;
  final String platform;
  final String releaseType;
  final DateTime releaseDate;

  const AppVersion({
    required this.version,
    required this.url,
    required this.platform,
    required this.releaseType,
    required this.releaseDate,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'version': version,
      'url': url,
      'platform': platform,
      'releaseType': releaseType,
      'releaseDate': releaseDate.toIso8601String(),
    };
  }

  factory AppVersion.fromMap(Map<String, dynamic> map) {
    return AppVersion(
      version: map['version'] as String,
      url: map['url'] as String,
      platform: map['platform'] as String,
      releaseType: map['releaseType'] as String,
      releaseDate: DateTime.parse(map['releaseDate'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory AppVersion.fromJson(String source) =>
      AppVersion.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AppVersions(version: $version, url: $url, platform: '
        '$platform, releaseType: $releaseType, releaseDate: $releaseDate)';
  }

  @override
  bool operator ==(covariant AppVersion other) {
    if (identical(this, other)) return true;

    return other.version == version &&
        other.url == url &&
        other.platform == platform &&
        other.releaseType == releaseType &&
        other.releaseDate == releaseDate;
  }

  bool operator >(covariant AppVersion other) =>
      other.version.compareTo(other.version) == 1;

  @override
  int get hashCode {
    return version.hashCode ^
        url.hashCode ^
        platform.hashCode ^
        releaseType.hashCode ^
        releaseDate.hashCode;
  }
}
