import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DebugMode {
  DebugMode._();

  static bool get isInDebugMode {
    bool inDebugMode = true;
    assert(inDebugMode = true);
    return inDebugMode;
  }
}

class AppUtils {
  AppUtils._();

  static void showToast(String text, {Color color = Colors.red}) {
    Fluttertoast.showToast(
      msg: text,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: color,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }
}
