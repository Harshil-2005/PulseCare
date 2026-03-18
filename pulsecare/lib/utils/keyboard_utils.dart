import 'package:flutter/services.dart';

class KeyboardUtils {
  static void hideKeyboardKeepFocus() {
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }
}
