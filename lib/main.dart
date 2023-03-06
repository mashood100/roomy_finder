import 'dart:io';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:month_year_picker/month_year_picker.dart';
import 'package:roomy_finder/controllers/app_controller.dart';
import 'package:roomy_finder/controllers/notification_controller.dart';
import 'package:roomy_finder/firebase_options.dart';
import 'package:roomy_finder/functions/dynamic_link_handler.dart';
import 'package:roomy_finder/localization/messages.dart';
import 'package:roomy_finder/screens/ads/my_property_ads.dart';
import 'package:roomy_finder/screens/ads/my_roommate_ads.dart';
import 'package:roomy_finder/screens/home/home.dart';
import 'package:roomy_finder/screens/start/login.dart';
import 'package:roomy_finder/screens/start/reset_password.dart';
import 'package:roomy_finder/screens/start/welcome.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final pref = await SharedPreferences.getInstance();
  // pref.clear();

  // instantiating firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Firebase auth
  FirebaseAuth.instance.setLanguageCode(Platform.localeName);

  // Firebase Log
  FirebaseAnalytics.instance.logAppOpen();

  // Firebase Cloud Messaging
  FirebaseMessaging.instance.getToken();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  FirebaseMessaging.onMessage.listen((msg) {
    NotificationController.firebaseMessagingHandler(msg);
    if (msg.data["event"] == "new-message") {
      AppController.instance.haveNewMessage(true);
    } else {
      AppController.instance.haveNewNotification(true);
    }
  });

  // Dynamic link

  // Get any initial links
  final initialLink = await FirebaseDynamicLinks.instance.getInitialLink();

  if (initialLink != null) AppController.initialLink = initialLink.link;

  FirebaseDynamicLinks.instance.onLink.listen((data) {
    dynamicLinkHandler(data.link);
  }).onError((error) {
    Get.log("FirebaseDynamicLinks Error");
    Get.log("$error");
  });

  // Awesome notifications initialized
  AwesomeNotifications().initialize(
    // null,
    'resource://drawable/launcher_icon',
    [
      NotificationChannel(
        channelGroupKey: 'notification_channel_group',
        channelKey: 'notification_channel',
        channelName: 'basic_notifications',
        channelDescription: 'Room Finder default notification channel',
        defaultColor: Colors.purple,
        importance: NotificationImportance.High,
        channelShowBadge: true,
        ledColor: Colors.purple,
      ),
    ],
    channelGroups: [
      NotificationChannelGroup(
        channelGroupKey: 'notification_channel_group',
        channelGroupName: 'Notification Group',
      ),
    ],
    debug: true,
  );
  AwesomeNotifications().resetGlobalBadge();

  // instantiating app contolller
  Get.put(AppController(), tag: "appController", permanent: true);

  // await AppController.instance.removeSaveUser();
  await AppController.instance.initRequired();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final lightTheme = ThemeData(
      brightness: Brightness.light,
      primarySwatch: Colors.purple,
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(width: 1, color: Colors.grey),
        ),
        // fillColor: const Color.fromARGB(255, 228, 225, 225),
        filled: true,
        fillColor: Colors.grey.shade100,
        // prefixIconColor: Colors.grey,
        // constraints: const BoxConstraints(maxHeight: 65),
        // labelStyle: const TextStyle(color: Colors.grey),
        // hintStyle: const TextStyle(color: Colors.grey),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromRGBO(255, 123, 77, 1),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        // backgroundColor: Color.fromRGBO(255, 123, 77, 1),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(color: Colors.purple),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        // backgroundColor: Color.fromARGB(255, 1, 31, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10),
          ),
        ),
      ),
      dialogTheme: DialogTheme(
        actionsPadding: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      tabBarTheme: const TabBarTheme(
        labelColor: Colors.black,
      ),
    );

    final darkTheme = ThemeData(
      brightness: Brightness.dark,
      primarySwatch: Colors.purple,
      useMaterial3: true,
      scaffoldBackgroundColor: const Color.fromARGB(255, 19, 51, 77),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromRGBO(255, 123, 77, 1),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
        // centerTitle: true,
      ),
      // cardTheme: const CardTheme(color: Color.fromARGB(255, 1, 39, 70)),
      // iconTheme: const IconThemeData(color: Color.fromARGB(255, 0, 109, 4)),
      fontFamily: 'Roboto',
      inputDecorationTheme: InputDecorationTheme(
        isDense: true,
        hintStyle: const TextStyle(color: Colors.grey),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(width: 1),
        ),
        fillColor: Colors.grey.shade500,
        filled: false,
        // prefixIconColor: Colors.grey,
        // constraints: const BoxConstraints(maxHeight: 65),
        // labelStyle: const TextStyle(color: Colors.grey),
        // hintStyle: const TextStyle(color: Colors.grey),
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        // backgroundColor: Color.fromRGBO(255, 123, 77, 1),
        elevation: 3,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        selectedIconTheme: IconThemeData(color: Colors.purple),
        selectedLabelStyle: TextStyle(fontSize: 12),
      ),

      dividerTheme: const DividerThemeData(color: Colors.grey),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color.fromARGB(255, 1, 31, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(10),
          ),
        ),
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 2,
        trackShape: RectangularSliderTrackShape(),
      ),
      dialogTheme: DialogTheme(
        actionsPadding: const EdgeInsets.symmetric(vertical: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return Colors.green;
          }
          return Colors.grey;
        }),
      ),
      cardColor: const Color.fromARGB(255, 15, 54, 87),
    );

    return GetMaterialApp(
      defaultTransition: Transition.cupertino,
      locale: Locale(AppController.locale.languageLocale),
      fallbackLocale: const Locale('en'),
      translations: Messages(),
      title: 'Roomy Finder',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: AppController.themeMode,
      debugShowCheckedModeBanner: false,
      initialRoute: AppController.initialRoute,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      localizationsDelegates: const [
        MonthYearPickerLocalizations.delegate,
      ],
      getPages: [
        GetPage(
          name: "/welcome",
          page: () => const WelcomeScreen(),
        ),
        GetPage(
          name: "/login",
          page: () => const LoginScreen(),
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
      ],
    );
  }
}

// Declared as global, outside of any class
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  NotificationController.firebaseMessagingHandler(message);
}
