import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first
class PlaceAutoCompletePredicate {
  final String? placeId;
  final String mainText;
  final String? secondaryText;
  final String description;
  final List<String>? types;
  PlaceAutoCompletePredicate({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    required this.description,
    required this.types,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'placeId': placeId,
      'mainText': mainText,
      'secondaryText': secondaryText,
      'description': description,
      'types': types,
    };
  }

  factory PlaceAutoCompletePredicate.fromMap(Map<String, dynamic> map) {
    return PlaceAutoCompletePredicate(
      placeId: map['placeId'] != null ? map['placeId'] as String : null,
      mainText: map['mainText'] as String,
      secondaryText:
          map['secondaryText'] != null ? map['secondaryText'] as String : null,
      description: map['description'] as String,
      types: map['types'] != null
          ? List<String>.from((map['types'] as List))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory PlaceAutoCompletePredicate.fromJson(String source) =>
      PlaceAutoCompletePredicate.fromMap(
          json.decode(source) as Map<String, dynamic>);
}
