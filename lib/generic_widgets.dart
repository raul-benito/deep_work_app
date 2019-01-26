import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

final ThemeData kIOSTheme = new ThemeData();

final ThemeData kDefaultTheme = new ThemeData();

bool isIOS() {
  //return true;
  return defaultTargetPlatform == TargetPlatform.iOS;
}

double getDefaultElevation() {
  return isIOS() ? 0.0 : 4.0;
}

ThemeData getTheme() {
  return isIOS() ? kIOSTheme : kDefaultTheme;
}
