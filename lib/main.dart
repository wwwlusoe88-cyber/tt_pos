// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'global/theme/theme.dart';
import 'logic/product_logic.dart';
import 'logic/sale_logic.dart';
import 'logic/setting_logic.dart';
import 'logic/shopinfo_logic.dart';
import 'logic/receipt_logic.dart';
import 'logic/viplist_logic.dart';
import 'logic/dailyreport_logic.dart';
import 'service/printer_setting.dart';
import 'ui/home_screen.dart';
import 'ui/printer_setting_screen.dart'; // Correct Import: PrinterSettingScreen

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductLogic()),
        ChangeNotifierProvider(create: (_) => SaleLogic()),
        ChangeNotifierProvider(create: (_) => SettingLogic()),
        ChangeNotifierProvider(create: (_) => ShopInfoLogic()),
        ChangeNotifierProvider(create: (_) => ReceiptLogic()),
        ChangeNotifierProvider(create: (_) => VipListLogic()),
        ChangeNotifierProvider(create: (_) => DailyReportLogic()),
        ChangeNotifierProvider(create: (_) => PrinterSettingService()),
      ],
      child: Consumer<SettingLogic>(
        builder: (context, settingLogic, child) {
          return MaterialApp(
            title: 'TT POS App',
            debugShowCheckedModeBanner: false,
            
            // SettingLogic ၏ Theme ပြောင်းလဲမှုအတိုင်း အလိုအလျောက် ပြောင်းလဲမည်
            theme: settingLogic.currentThemeData,
            darkTheme: settingLogic.currentThemeData,
            themeMode: settingLogic.currentThemeMode,
            
            // App စစချင်း ပြမည့် Screen
            home: const HomeScreen(),

            // ReceiptScreen မှ 'Change' ခလုတ်နှိပ်လျှင် ခေါ်ဆိုနိုင်ရန် Route ကြေငြာချက်
            routes: {
              '/printer_setup': (context) => const PrinterSettingScreen(),
            },
          );
        },
      ),
    );
  }
}
