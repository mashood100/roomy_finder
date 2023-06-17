import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:jiffy/jiffy.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:roomy_finder/classes/api_service.dart';
import 'package:roomy_finder/classes/app_locale.dart';
import 'package:roomy_finder/classes/app_notification.dart';
import 'package:roomy_finder/data/constants.dart';
import 'package:roomy_finder/models/app_version.dart';
import 'package:roomy_finder/models/country.dart';
import 'package:roomy_finder/models/user.dart';

class AppController extends GetxController {
  static late ThemeMode themeMode;
  static late String initialRoute;
  static late String apiToken;
  static late bool isFirstStart;
  static Uri? dynamicInitialLink;
  static bool haveOpenInitialMessage = false;

  static AppController instance = Get.find<AppController>(tag: "appController");
  static User get me => instance.user.value;
  static AppLocale get locale => instance.appLocale.value;
  static num get convertionRate =>
      instance.country.value.aedCurrencyConvertRate;

  Rx<User> user = User.GUEST_USER.obs;
  late final Rx<bool> allowPushNotifications;
  late Rx<AppLocale> appLocale;

  String? userPassword;

  final country = Country.UAE.obs;

  static AppVersion? updateVersion;

  Future<void> initRequired() async {
    // User
    final savedUser = await getSaveUser();

    if (savedUser != null) {
      user = savedUser.obs;
      AppController.setupFCMTokenHandler();

      userPassword = await getUserPassword();

      if (savedUser.isMaintenant) {
        initialRoute = "/maintenance";
        FirebaseMessaging.instance.subscribeToTopic("maintenance-broadcast");
      } else {
        initialRoute = "/home";
      }
    } else {
      final isFirstLaunch = await getIsFirstLaunch();
      initialRoute = isFirstLaunch ? "/onboarding" : "/welcome";
    }

    // Api token
    final savedToken = await getApiToken();
    apiToken = savedToken ?? "";

    // App Locale
    final savedAppLocale = await getAppLocale();

    if (savedAppLocale != null) {
      appLocale = savedAppLocale.obs;
    } else {
      appLocale = AppLocale.enUS.obs;
    }

    await Jiffy.setLocale(appLocale.value.jiffyLocaleName);
    await Get.updateLocale(Locale(appLocale.value.languageLocale));

    // Theme mode
    themeMode = await getThemeMode();

    // PushNotifications
    allowPushNotifications = (await getAllowPushNotifications()).obs;

    // Badges
    _initializeBages();
  }

  // API key
  Future<String?> getApiToken() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final token = pref.getString("apiToken");
      if (token != null) apiToken = token;
      return token;
    } catch (_) {
      return null;
    }
  }

  // Is first launch
  Future<bool> getIsFirstLaunch() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final isFirstLaunch = pref.getBool("isFirstLaunch") ?? true;
      return isFirstLaunch;
    } catch (_) {
      return true;
    }
  }

  Future<void> setIsFirstLaunchToFalse(bool value) async {
    try {
      final pref = await SharedPreferences.getInstance();
      pref.setBool("isFirstLaunch", value);
    } catch (_) {}
  }

  Future<void> setApiToken(String token) async {
    apiToken = token;
    final pref = await SharedPreferences.getInstance();
    pref.setString("apiToken", token);
  }

  Future<void> removeApiToken() async {
    apiToken = '';
    final pref = await SharedPreferences.getInstance();
    pref.remove("apiToken");
  }

// App User
  Future<void> saveUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.setString("user", user.value.toJson());
  }

  Future<User?> getSaveUser() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final jsonUser = pref.getString("user");

      if (jsonUser == null) return null;
      final user = User.fromJson(jsonUser);
      AppNotication.currentUser = user;
      return user;
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> removeSaveUser() async {
    final pref = await SharedPreferences.getInstance();
    pref.remove("user");
  }

  // isFirstStart
  Future<void> setIsFirstStart(bool value) async {
    try {
      final pref = await SharedPreferences.getInstance();
      pref.setBool("isFirstStart", value);
      isFirstStart = value;
    } catch (e, trace) {
      log(e);
      log(trace);
    }
  }

  Future<bool> getIsFirstStart() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final value = pref.getBool("isFirstStart");

      return value ?? true;
    } catch (e, trace) {
      log(e);
      log(trace);
      return true;
    }
  }

  // PushNotifications
  Future<void> setAllowPushNotifications(bool value) async {
    try {
      final pref = await SharedPreferences.getInstance();
      pref.setBool("allowPushNotifications", value);
      allowPushNotifications(value);
    } catch (e, trace) {
      log(e);
      log(trace);
    }
  }

  Future<bool> getAllowPushNotifications() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final value = pref.getBool("allowPushNotifications");

      return value ?? true;
    } catch (e, trace) {
      log(e);
      log(trace);
      return true;
    }
  }

  // App Locale
  Future<void> setAppLocale(AppLocale appLocale) async {
    try {
      final pref = await SharedPreferences.getInstance();
      pref.setString("appLocale", appLocale.toJson());
      await Jiffy.setLocale(appLocale.jiffyLocaleName);
      this.appLocale(appLocale);
      await Get.updateLocale(Locale(appLocale.languageLocale));
    } catch (e, trace) {
      log(e);
      log(trace);
    }
  }

  Future<AppLocale?> getAppLocale() async {
    try {
      final pref = await SharedPreferences.getInstance();
      final value = pref.getString("appLocale");
      if (value != null) return AppLocale.fromJson(value);
      return null;
    } catch (e, trace) {
      log(e);
      log(trace);
      return null;
    }
  }

  // Theme mode
  static Future<void> setThemeMode(ThemeMode themeMode) async {
    AppController.themeMode = themeMode;
    Get.changeThemeMode(themeMode);
    final pref = await SharedPreferences.getInstance();
    pref.setString("themeMode", themeMode.name);
  }

  static Future<ThemeMode> getThemeMode() async {
    final pref = await SharedPreferences.getInstance();
    final mode = pref.getString("themeMode");

    switch (mode) {
      case "light":
        return ThemeMode.light;
      case "dark":
        return ThemeMode.dark;
      default:
        return ThemeMode.light;
    }
  }

  // password
  Future<void> saveUserPassword(String password) async {
    final pref = await SharedPreferences.getInstance();
    pref.setString("userPassword", password);
  }

  Future<void> removeUserPassword() async {
    final pref = await SharedPreferences.getInstance();
    pref.remove("userPassword");
  }

  Future<String?> getUserPassword() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getString("userPassword");
  }

  // Logout
  Future<void> logout() async {
    try {
      await removeSaveUser();
      await removeApiToken();
      await removeUserPassword();
      dynamicInitialLink = null;
      user(User.GUEST_USER);
    } catch (e, trace) {
      log(e);
      log(trace);
      FirebaseAuth.instance.signOut();
    }
  }

  // FCM
  static Future<void> saveTokenToDatabase(String token) async {
    try {
      await ApiService.getDio.put(
        "$API_URL/auth/update-fcm-token",
        data: {"fcmToken": token},
      );
    } catch (e) {
      log(e);
    }
  }

  static Future<void> setupFCMTokenHandler() async {
    // Get the token each time the application loads
    String? token = await FirebaseMessaging.instance.getToken();

    // Save the initial token to the database
    await saveTokenToDatabase(token!);

    // Any time the token refreshes, store this in the database too.
    FirebaseMessaging.instance.onTokenRefresh.listen(saveTokenToDatabase);
  }

  // ************ Notification badges ****************** //

  static const _basicBadges = {
    "bookings": 0,
    "notifications": 0,
    "messages": 0,
    "maintenances": 0,
  };

  RxMap<String, int> badges = _basicBadges.obs;

  void incrementBadge(String key, [int value = 1, bool increment = false]) {
    if (!badges.containsKey(key)) return;

    badges({...badges, key: badges[key]! + value});

    saveBadges(badges, increment);
  }

  void resetBadge(String key) {
    if (!badges.containsKey(key)) return;

    badges({...badges, key: 0});

    saveBadges(badges);
  }

  static Future<void> staticIncrementBadge(
    String key, [
    int value = 1,
  ]) async {
    final appDir = await getApplicationSupportDirectory();

    final file = File(path.join(appDir.path, "badges.json"));

    final Map<String, int> data;

    if (!file.existsSync()) {
      file.createSync();

      data = _basicBadges;
    } else {
      final oldBages = await getSaveBadges();

      data = {..._basicBadges, ...?oldBages};
    }

    saveBadges(data);
  }

  static Future<void> saveBadges(
    Map<String, int> badges, [
    bool? increment,
  ]) async {
    try {
      final appDir = await getApplicationSupportDirectory();

      final file = File(path.join(appDir.path, "badges.json"));

      if (!file.existsSync()) file.createSync();

      if (increment == true) {
        final oldBages = await getSaveBadges();
        if (oldBages != null) {
          badges = badges.map((key, value) {
            if (oldBages.containsKey(key)) value += oldBages[key]!;

            return MapEntry(key, value);
          });
        }
      }

      file.writeAsStringSync(json.encode({..._basicBadges, ...badges}));
    } catch (e) {
      log(e);
    }
  }

  static Future<Map<String, int>?> getSaveBadges() async {
    try {
      final appDir = await getApplicationSupportDirectory();

      final file = File(path.join(appDir.path, "badges.json"));

      if (!file.existsSync()) return null;

      final content = await file.readAsString();

      var map = Map<String, int>.from(json.decode(content));
      // print("Saved Badges : $map");
      return map;
    } catch (e) {
      log(e);

      return null;
    }
  }

  void _initializeBages() {
    getSaveBadges().then((value) {
      if (value != null) badges(value);
    });
  }
}

void log([data]) {
  Get.log("APP_CONTROLLER :: $data");
}
