import 'dart:convert';

import 'package:roomy_finder/maintenance/helpers/maintenance.dart';
import 'package:roomy_finder/models/user.dart';

class MaintenanceOffer {
  final String id;
  final User maintainer;
  final Maintenance request;
  final List<MaintenanceOfferEntry> maintenances;
  final String status;
  final String? description;
  final List<String> images;
  final List<String> videos;
  final DateTime createdAt;
  final List<MaintenanceSubmit> submits;

  MaintenanceOffer({
    required this.id,
    required this.maintainer,
    required this.request,
    required this.maintenances,
    required this.status,
    this.description,
    required this.images,
    required this.videos,
    required this.createdAt,
    required this.submits,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'maintainer': maintainer.toMap(),
      'request': request.toMap(),
      'maintenances': maintenances.map((x) => x.toMap()).toList(),
      'status': status,
      'description': description,
      'images': images,
      'videos': videos,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'submits': submits.map((x) => x.toMap()).toList(),
    };
  }

  factory MaintenanceOffer.fromMap(Map<String, dynamic> map) {
    return MaintenanceOffer(
      id: map['id'] as String,
      maintainer: User.fromMap(map['maintainer'] as Map<String, dynamic>),
      request: Maintenance.fromMap(map['request'] as Map<String, dynamic>),
      maintenances: List<MaintenanceOfferEntry>.from(
        (map['maintenances'] as List).map<MaintenanceOfferEntry>(
          (x) => MaintenanceOfferEntry.fromMap(x as Map<String, dynamic>),
        ),
      ),
      status: map['status'] as String,
      description:
          map['description'] != null ? map['description'] as String : null,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int),
      submits: List<MaintenanceSubmit>.from(
        (map['submits'] as List).map<MaintenanceSubmit>(
          (x) => MaintenanceSubmit.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory MaintenanceOffer.fromJson(String source) =>
      MaintenanceOffer.fromMap(json.decode(source) as Map<String, dynamic>);
}

class MaintenanceOfferEntry {
  String name;
  int quantity;
  num budget;
  bool materialIncluded;

  MaintenanceOfferEntry({
    required this.name,
    required this.quantity,
    required this.budget,
    required this.materialIncluded,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'quantity': quantity,
      'budget': budget,
      'materialIncluded': materialIncluded,
    };
  }

  factory MaintenanceOfferEntry.fromMap(Map<String, dynamic> map) {
    return MaintenanceOfferEntry(
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      budget: map['budget'] as num,
      materialIncluded: map['materialIncluded'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory MaintenanceOfferEntry.fromJson(String source) =>
      MaintenanceOfferEntry.fromMap(
          json.decode(source) as Map<String, dynamic>);
}

class MaintenanceSubmit {
  final String id;
  final DateTime createdAt;
  final bool approvedByLandlord;

  final String? maintainerNote;
  final List<String> maintainerImages;
  final List<String> maintainerVideos;

  final String? landlordNote;
  final List<String> landlordImages;
  final List<String> landlordVideos;

  MaintenanceSubmit({
    required this.id,
    required this.createdAt,
    required this.approvedByLandlord,
    this.maintainerNote,
    required this.maintainerImages,
    required this.maintainerVideos,
    this.landlordNote,
    required this.landlordImages,
    required this.landlordVideos,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'approvedByLandlord': approvedByLandlord,
      'maintainerNote': maintainerNote,
      'maintainerImages': maintainerImages,
      'maintainerVideos': maintainerVideos,
      'landlordNote': landlordNote,
      'landlordImages': landlordImages,
      'landlordVideos': landlordVideos,
    };
  }

  factory MaintenanceSubmit.fromMap(Map<String, dynamic> map) {
    return MaintenanceSubmit(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      approvedByLandlord: map['approvedByLandlord'] as bool,
      maintainerNote: map['maintainerNote'] != null
          ? map['maintainerNote'] as String
          : null,
      maintainerImages: List<String>.from((map['maintainerImages'] as List)),
      maintainerVideos: List<String>.from((map['maintainerVideos'] as List)),
      landlordNote:
          map['landlordNote'] != null ? map['landlordNote'] as String : null,
      landlordImages: List<String>.from((map['landlordImages'] as List)),
      landlordVideos: List<String>.from((map['landlordVideos'] as List)),
    );
  }

  String toJson() => json.encode(toMap());

  factory MaintenanceSubmit.fromJson(String source) =>
      MaintenanceSubmit.fromMap(json.decode(source) as Map<String, dynamic>);
}
