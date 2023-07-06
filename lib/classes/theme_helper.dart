import 'package:flutter/material.dart';
import 'package:roomy_finder/utilities/data.dart';

class ThemeHelper {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.purple,
    useMaterial3: true,
    scaffoldBackgroundColor: Colors.white,
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      hintStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(5),
        borderSide: const BorderSide(width: 1, color: Colors.grey),
      ),
      // fillColor: const Color.fromARGB(255, 228, 225, 225),
      filled: true,
      fillColor: Colors.white,
      // prefixIconColor: Colors.grey,
      // constraints: const BoxConstraints(maxHeight: 65),
      // labelStyle: const TextStyle(color: Colors.grey),
      // hintStyle: const TextStyle(color: Colors.grey),
      helperMaxLines: 3,
      errorMaxLines: 3,
    ),
    fontFamily: "Avenir",
    fontFamilyFallback: const ["Avro", "Roboto"],
    appBarTheme: const AppBarTheme(
      backgroundColor: ROOMY_PURPLE,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
      iconTheme: IconThemeData(color: Colors.white),
      actionsIconTheme: IconThemeData(color: Colors.white),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      // backgroundColor: Colors.white,
      unselectedIconTheme: IconThemeData(color: ROOMY_PURPLE),
      selectedIconTheme: IconThemeData(color: ROOMY_PURPLE),
      showSelectedLabels: false,
      showUnselectedLabels: false,
      unselectedLabelStyle: TextStyle(fontSize: 5),
      selectedLabelStyle: TextStyle(fontSize: 5),
      type: BottomNavigationBarType.fixed,
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
    // cardColor: Colors.white,
  );

  static final darkTheme = ThemeData(
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
      backgroundColor: ROOMY_PURPLE,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      unselectedLabelStyle: TextStyle(fontSize: 15),
      selectedLabelStyle: TextStyle(fontSize: 15),
      selectedIconTheme: IconThemeData(
        color: Color.fromRGBO(255, 123, 77, 1),
        size: 30,
      ),
      unselectedIconTheme: IconThemeData(
        color: Color.fromRGBO(255, 123, 77, 1),
        size: 30,
      ),
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
      fillColor:
          MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.green;
        }
        return Colors.grey;
      }),
    ),
    cardColor: const Color.fromARGB(255, 15, 54, 87),
  );
}
