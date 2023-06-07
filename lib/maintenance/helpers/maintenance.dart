// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:roomy_finder/controllers/app_controller.dart';

import 'package:roomy_finder/maintenance/helpers/get_sub_category_icon.dart';
import 'package:roomy_finder/models/user.dart';

class Maintenance {
  String id;
  User landlord;
  List<MaintenanceEntry> tasks;
  String category;
  String status;
  DateTime date;
  Map<String, dynamic> address;
  final String paymentMethod;
  bool isPaid;
  final String? description;
  final List<String> images;
  final List<String> videos;
  DateTime? dateOffered;
  DateTime? dateCompleted;

  List<Map<String, dynamic>> offers;
  List<Map<String, dynamic>> submits;
  String? maintenantId;

  Maintenance({
    required this.id,
    required this.landlord,
    required this.tasks,
    required this.category,
    required this.status,
    required this.date,
    required this.address,
    required this.paymentMethod,
    required this.isPaid,
    this.description,
    required this.images,
    required this.videos,
    this.dateOffered,
    this.dateCompleted,
    required this.offers,
    required this.submits,
    this.maintenantId,
  });

  bool get isMine => landlord.isMe;
  bool get isMeMaintenant => maintenantId == AppController.me.id;
  bool get isPending => status == "Pending";
  bool get isOffered => status == "Offered";

  User? get maintenant {
    if (maintenantId == null) return null;
    var o = offers.firstWhereOrNull((e) => e["user"]["id"] == maintenantId);

    if (o == null) return null;

    return User.fromMap(o["user"]);
  }

  int? getQuantity(String taskName) {
    final task = tasks.firstWhereOrNull((e) => e.name == taskName);
    return task?.quantity;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'landlord': landlord.toMap(),
      'tasks': tasks.map((x) => x.toMap()).toList(),
      'category': category,
      'status': status,
      'date': date.toIso8601String(),
      'address': address,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'description': description,
      'images': images,
      'videos': videos,
      'dateOffered': dateOffered?.toIso8601String(),
      'dateCompleted': dateCompleted?.toIso8601String(),
      'offers': offers,
      'submits': submits,
      'maintenantId': maintenantId,
    };
  }

  factory Maintenance.fromMap(Map<String, dynamic> map) {
    return Maintenance(
      id: map['id'] as String,
      landlord: User.fromMap(map['landlord'] as Map<String, dynamic>),
      tasks: List<MaintenanceEntry>.from(
        (map['tasks'] as List).map<MaintenanceEntry>(
          (x) => MaintenanceEntry.fromMap(x as Map<String, dynamic>),
        ),
      ),
      category: map['category'] as String,
      status: map['status'] as String,
      date: DateTime.parse(map['date'] as String),
      address:
          Map<String, dynamic>.from((map['address'] as Map<String, dynamic>)),
      paymentMethod: map['paymentMethod'] as String,
      isPaid: map['isPaid'] as bool,
      description:
          map['description'] != null ? map['description'] as String : null,
      images: List<String>.from((map['images'] as List)),
      videos: List<String>.from((map['videos'] as List)),
      dateOffered: map['dateOffered'] != null
          ? DateTime.parse(map['dateOffered'] as String)
          : null,
      dateCompleted: map['dateCompleted'] != null
          ? DateTime.parse(map['dateCompleted'] as String)
          : null,
      offers: List<Map<String, dynamic>>.from(
        (map['offers'] as List).map<Map<String, dynamic>>(
          (x) => x,
        ),
      ),
      submits: List<Map<String, dynamic>>.from(
        (map['submits'] as List).map<Map<String, dynamic>>(
          (x) => x,
        ),
      ),
      maintenantId:
          map['maintenantId'] != null ? map['maintenantId'] as String : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Maintenance.fromJson(String source) =>
      Maintenance.fromMap(json.decode(source) as Map<String, dynamic>);
}

class PostMaintenanceRequest {
  final String category;
  final List<MaintenanceEntry> maintenances;
  String? description;
  final List<XFile> images;
  DateTime date;
  Map<String, String> address;
  String? paymentMethod;

  PostMaintenanceRequest({
    required this.category,
    required this.maintenances,
    this.description,
    required this.images,
    required this.date,
    required this.address,
    this.paymentMethod,
  });
}

class MaintenanceEntry {
  String subCategory;
  String name;
  int quantity;

  MaintenanceEntry({
    required this.subCategory,
    required this.name,
    required this.quantity,
  });

  Widget getIcon(String category, {Size size = const Size.square(30)}) {
    return Image.asset(
      getSubCategoryIconsAsset(category, subCategory) ??
          "assets/icons/info.png",
      height: size.height,
    );
  }

  @override
  bool operator ==(covariant MaintenanceEntry other) {
    if (identical(this, other)) return true;

    return other.subCategory == subCategory && other.name == name;
  }

  @override
  int get hashCode {
    return subCategory.hashCode ^ name.hashCode;
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'subCategory': subCategory,
      'name': name,
      'quantity': quantity,
    };
  }

  factory MaintenanceEntry.fromMap(Map<String, dynamic> map) {
    return MaintenanceEntry(
      subCategory: map['subCategory'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory MaintenanceEntry.fromJson(String source) =>
      MaintenanceEntry.fromMap(json.decode(source) as Map<String, dynamic>);
}
