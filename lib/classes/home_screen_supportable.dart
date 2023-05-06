import 'package:flutter/material.dart';

abstract class HomeScreenSupportable implements Widget {
  AppBar? get appBar;
  BottomNavigationBarItem navigationBarItem(bool isCurrent);
  Widget? get floatingActionButton;
  void onIndexSelected(int index) {}
}
