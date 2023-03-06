import 'package:flutter/material.dart';

abstract class HomeScreenSupportable implements Widget {
  AppBar? get appBar;
  BottomNavigationBarItem get navigationBarItem;
  Widget? get floatingActionButton;
}
