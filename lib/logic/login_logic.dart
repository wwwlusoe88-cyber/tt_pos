import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/utility/utils.dart';
import '../ui/home_screen.dart';

class LoginLogic {
  // Login စစ်ဆေးမည့် လုပ်ဆောင်ချက်
  static void validateAndLogin({
    required BuildContext context,
    required String role,
    required String username,
    required String password,
    required bool rememberMe,
  }) async {
    // ကွက်လပ်များ လွတ်နေပါက သတိပေးရန်
    if (username.trim().isEmpty || password.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Username နှင့် Password ထည့်ပါ။", isError: true);
      return;
    }

    // Admin Account သို့မဟုတ် Test Account စစ်ဆေးခြင်း
    if ((username.trim() == "ayarwaddy" && password.trim() == "ayarwaddy") ||
        (username.trim() == "thurein" && password.trim() == "123")) {

      // Remember Me အခြေအနေကို Local Storage တွင် သိမ်းဆည်းရန်
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('remember_me', rememberMe);
      if (rememberMe) {
        await prefs.setString('saved_username', username.trim());
      } else {
        await prefs.remove('saved_username');
      }

      Utils.showTopToast(context, "Login အောင်မြင်ပါသည်!");

      // Login အောင်မြင်ပါက Home Screen သို့ သွားရန်
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      // မအောင်မြင်ပါက အနီရောင် Toast ဖြင့် သတိပေးရန်
      Utils.showTopToast(context, "Username သို့မဟုတ် Password မှားယွင်းနေပါသည်။", isError: true);
    }
  }
}
