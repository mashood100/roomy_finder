import 'package:roomy_finder/models/property_ad.dart';
import 'package:roomy_finder/models/roommate_ad.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FovoritePropertyAdHelper {
  static const _propertiesAdKey = "favorite_property_ads.json";

  static Future<bool> addToFavorites(PropertyAd ad) async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = await getAllFavorites();

      if (!data.contains(ad)) data.insert(0, ad);

      pref.setStringList(
          _propertiesAdKey, data.map((e) => e.toJson()).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromFavorites(String id) async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = await getAllFavorites();

      data.removeWhere((e) => e.id == id);

      pref.setStringList(
          _propertiesAdKey, data.map((e) => e.toJson()).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isInFovarite(String id) async {
    try {
      var data = await getAllFavorites();

      if (data.any((e) => e.id == id)) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<PropertyAd>> getAllFavorites() async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = (pref.getStringList(_propertiesAdKey) ?? [])
          .map((e) {
            try {
              return PropertyAd.fromJson(e);
            } catch (e) {
              return null;
            }
          })
          .whereType<PropertyAd>()
          .toList();

      return data;
    } catch (e) {
      return [];
    }
  }
}

class FovoriteRoommateAdHelper {
  static const _key = "favorite_roommate_ads.json";

  static Future<bool> addToFavorites(RoommateAd ad) async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = await getAllFavorites();

      if (!data.contains(ad)) data.insert(0, ad);

      pref.setStringList(_key, data.map((e) => e.toJson()).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> removeFromFavorites(String id) async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = await getAllFavorites();

      data.removeWhere((e) => e.id == id);

      pref.setStringList(_key, data.map((e) => e.toJson()).toList());
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> isInFovarite(String id) async {
    try {
      var data = await getAllFavorites();

      if (data.any((e) => e.id == id)) return true;

      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<List<RoommateAd>> getAllFavorites() async {
    try {
      final pref = await SharedPreferences.getInstance();

      var data = (pref.getStringList(_key) ?? [])
          .map((e) {
            try {
              return RoommateAd.fromJson(e);
            } catch (e) {
              return null;
            }
          })
          .whereType<RoommateAd>()
          .toList();

      return data;
    } catch (e) {
      return [];
    }
  }
}
