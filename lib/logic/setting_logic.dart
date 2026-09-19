// lib/logic/setting_logic.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/theme/theme.dart';

// App တွင် သုံးစွဲမည့် Theme ရွေးချယ်မှုအမျိုးအစားများ
enum AppThemeOption { light, dark, modernHighlight, system }

class SettingLogic extends ChangeNotifier {
  static const String _themePreferenceKey = "selected_app_theme";
  AppThemeOption _selectedThemeOption = AppThemeOption.light;

  AppThemeOption get selectedThemeOption => _selectedThemeOption;

  SettingLogic() {
    _loadThemeFromPrefs(); // Class စတင်ချိန်တွင် Saved Theme ကို Load လုပ်မည်
  }

  // Storage မှ Theme ပြန်ယူသည့် Function
  Future<void> _loadThemeFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedThemeString = prefs.getString(_themePreferenceKey);

      if (savedThemeString != null) {
        _selectedThemeOption = AppThemeOption.values.firstWhere(
          (e) => e.name == savedThemeString,
          orElse: () => AppThemeOption.light,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Theme loading error: $e");
    }
  }

  // လက်ရှိ ရွေးချယ်ထားသော AppThemeOption ပေါ်မူတည်၍ ThemeData ပြန်ထုတ်ပေးခြင်း
  ThemeData get currentThemeData {
    switch (_selectedThemeOption) {
      case AppThemeOption.light:
        return AppThemes.defaultTheme;
      case AppThemeOption.dark:
        return AppThemes.darkTheme;
      case AppThemeOption.modernHighlight:
        return AppThemes.modernHighlightTheme;
      case AppThemeOption.system:
        return AppThemes.defaultTheme;
    }
  }

  // MaterialApp ၏ themeMode သို့ ပေးပို့ရန် Flutter ThemeMode ပြန်ထုတ်ပေးခြင်း
  ThemeMode get currentThemeMode {
    switch (_selectedThemeOption) {
      case AppThemeOption.light:
        return ThemeMode.light;
      case AppThemeOption.dark:
      case AppThemeOption.modernHighlight:
        return ThemeMode.dark;
      case AppThemeOption.system:
        return ThemeMode.system;
    }
  }

  // Theme ပြောင်းလဲသည့် Function (Storage ထဲသို့ သွားရောက် Save မည်)
  Future<void> changeTheme(AppThemeOption option) async {
    _selectedThemeOption = option;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themePreferenceKey, option.name);
    } catch (e) {
      debugPrint("Theme saving error: $e");
    }
  }

  // Log Out လုပ်ဆောင်ချက် Function
  void logout(BuildContext context) {
    // Drawer ကို အရင် ပိတ်မည်
    Navigator.pop(context);

    // Confirmation Dialog ပြသမည်
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Log Out"),
        content: const Text("အကောင့်မှ ထွက်မှာ သေချာပါသလား။"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("မလုပ်တော့ပါ"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Login screen သို့ ပြန်သွားမည့် Logic ကို ဒီမှာ ထည့်သွင်းနိုင်ပါတယ်
            },
            child: const Text("ထွက်မည်", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
