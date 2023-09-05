import 'dart:io';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:roomy_finder/classes/file_helprer.dart';
import 'package:roomy_finder/classes/theme_helper.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/firebase_options.dart';
import 'package:roomy_finder/functions/dynamic_link_handler.dart';
import 'package:roomy_finder/localization/messages.dart';
import 'package:roomy_finder/maintenance/screens/home_maintenance.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/start/onboarding.dart';
import 'package:roomy_finder/screens/start/registration.dart';
import 'package:roomy_finder/screens/start/reset_password.dart';
import 'package:roomy_finder/screens/start/welcome.dart';
import 'package:roomy_finder/screens/utility_screens/update_app.dart';
import 'package:roomy_finder/utilities/isar.dart';

// import 'package:shared_preferences/shared_preferences.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final pref = await SharedPreferences.getInstance();
  // pref.clear();

  // Database
  await initIsar();
  // ISAR.writeTxnSync(() => ISAR.chatConversationV2s.clearSync());
  // ISAR.writeTxnSync(() => ISAR.chatMessageV2s.clearSync());
  // ISAR.writeTxnSync(() => ISAR.users.clearSync());

  // instantiating firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // AppCheck
  await FirebaseAppCheck.instance.activate(
    webRecaptchaSiteKey: 'recaptcha-v3-site-key',
    androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    appleProvider: kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
  );

  // Firebase auth
  FirebaseAuth.instance.setLanguageCode(Platform.localeName);

  // Firebase Log
  FirebaseAnalytics.instance.logAppOpen();

  // Firebase Cloud Messaging
  FirebaseMessaging.onMessage.listen((msg) {
    NotificationController.firebaseMessagingHandler(msg, true);
  });
  FirebaseMessaging.onMessageOpenedApp.listen((msg) {
    NotificationController.handleFCMMessageOpenedAppMessage(msg);
  });
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: false,
    sound: false,
    badge: false,
  );

  // Local notification
  await NotificationController.initializeLocalNotifications();
  await NotificationController.plugin.cancelAll();

  // Dynamic link

  // Get any initial links
  final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink != null) AppController.dynamicInitialLink = initialLink.link;

  FirebaseDynamicLinks.instance.onLink.listen((data) {
    dynamicLinkHandler(data.link);
  }).onError((error) {
    Get.log("FirebaseDynamicLinks Error");
    Get.log("$error");
  });

  // instantiating app contolller
  Get.put(AppController(), tag: "appController", permanent: true);

  // await AppController.instance.removeSaveUser();
  await AppController.instance.initRequired();

  FileHelper.loadAssets();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      defaultTransition: Transition.fadeIn,
      locale: Locale(AppController.locale.languageLocale),
      fallbackLocale: const Locale('en'),
      translations: Messages(),
      title: 'Roomy Finder',
      theme: ThemeHelper.lightTheme,
      darkTheme: ThemeHelper.darkTheme,
      themeMode: AppController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppController.initialRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      getPages: [
        GetPage(
          name: "/onboarding",
          page: () => const OnboardingScreen(),
        ),
        GetPage(
          name: "/welcome",
          page: () => const WelcomeScreen(),
        ),
        GetPage(
          name: "/login",
          page: () => const LoginScreen(),
        ),
        GetPage(
          name: "/registration",
          page: () => const RegistrationScreen(),
        ),
        GetPage(
          name: "/reset_password",
          page: () => const ResetPasswordScreen(),
        ),
        GetPage(
          name: "/home",
          page: () => const Home(),
        ),
        GetPage(
          name: "/my-property-ads",
          page: () => const MyPropertyAdsScreen(),
        ),
        GetPage(
          name: "/my-roommate-ads",
          page: () => const MyRoommateAdsScreen(),
        ),
        GetPage(
          name: "/update-app",
          page: () => const UpdateAppScreen(),
        ),
        GetPage(
          name: "/maintenance",
          page: () => const MaintenanceHome(),
        ),
      ],
    );
  }
}

// Declared as global, outside of any class
@pragma("vm:entry-point")
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationController.firebaseMessagingHandler(message, false);
}


// Test Comment