import 'package:flutter/material.dart';
import '../global/utility/utils.dart';
import '../ui/product_screen.dart'; // ProductScreen ကို import ချိတ်ရန်
import '../ui/sale_screen.dart';    // SaleScreen သို့ သွားနိုင်ရန် import ချိတ်ဆက်ခြင်း

class HomeLogic {
  // Menu များကို နှိပ်လိုက်သည့်အခါ လုပ်ဆောင်မည့် Logic များ
  static void handleMenuClick(BuildContext context, String menuName) {
    if (menuName == "Product") {
      // Product ခလုတ်နှိပ်လျှင် ProductScreen သို့ သွားရန်
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProductScreen()),
      );
    } else if (menuName == "Sale") {
      // Sale ခလုတ်နှိပ်လျှင် SaleScreen သို့ သွားရန်
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const SaleScreen()),
      );
    } else {
      Utils.showTopToast(context, "$menuName စာမျက်နှာသို့ သွားနေပါပြီ...");
    }
  }

  // ဆိုင်ခွဲ (Store / Branch) ပြောင်းရန် Dialog
  static void showStoreSelector(BuildContext context) {
    Utils.showConfirmDialog(
      context: context,
      title: "ဆိုင်ခွဲပြောင်းရန်",
      content: "လက်ရှိ S - 1 ဆိုင်ခွဲမှ အခြားဆိုင်ခွဲသို့ ပြောင်းလိုပါသလား?",
      confirmText: "ပြောင်းမည်",
      cancelText: "မပြောင်းပါ",
      confirmColor: Colors.blueAccent,
      onConfirm: () {
        Utils.showTopToast(context, "ဆိုင်ခွဲ အောင်မြင်စွာ ပြောင်းလဲပြီးပါပြီ။");
      },
    );
  }
}
