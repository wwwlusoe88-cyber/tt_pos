// home_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../logic/home_logic.dart';
import '../logic/product_logic.dart';
import '../logic/sale_logic.dart';
import '../global/utility/utils.dart';
import '../ui/debt_screen.dart';
import '../ui/setting_screen.dart';
import '../ui/receipt_screen.dart';
import '../ui/expenses_screen.dart';
import '../ui/viplist_screen.dart'; 
import '../ui/dailyreport_screen.dart'; // Daily Report Screen အတွက် import ချိတ်ဆက်ခြင်း
import 'tt_pos_logo.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream<DateTime>.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    );

    // HomeScreen စဖွင့်သည်နှင့် Dashboard Data များကို လှမ်းယူခြင်း
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductLogic>(context, listen: false).fetchProducts();
      Provider.of<SaleLogic>(context, listen: false).fetchDashboardMetrics();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Currency Formatting (ဥပမာ - 1,000,000 Ks)
    final currencyFormatter = NumberFormat("#,##0", "en_US");

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      endDrawer: const SettingScreen(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar (Logo, Store Selector, Settings)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const TTPosLogo(size: 38),
                  GestureDetector(
                    onTap: () => HomeLogic.showStoreSelector(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(isDark ? 50 : 12),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.store, size: 16, color: colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            "S - 1",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Builder(
                    builder: (context) {
                      return Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(isDark ? 50 : 12),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(
                            Icons.settings,
                            color: colorScheme.onSurface,
                            size: 20,
                          ),
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dashboard Section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(isDark ? 50 : 10),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Dashboard",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        StreamBuilder<DateTime>(
                          stream: _timeStream,
                          builder: (context, snapshot) {
                            final now = snapshot.data ?? DateTime.now();
                            final currentDate = DateFormat('dd MMM yyyy').format(now);
                            final currentTime = DateFormat('hh:mm:ss a').format(now);

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  currentDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface.withAlpha(180),
                                  ),
                                ),
                                Text(
                                  currentTime,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 3x2 Grid Dashboard Items (Dynamic Data with Providers)
                    Consumer2<SaleLogic, ProductLogic>(
                      builder: (context, saleLogic, productLogic, child) {
                        // Product Calculation
                        final totalProduct = productLogic.products.length;
                        final lowStock = productLogic.products.where((p) => p.quantity > 0 && p.quantity <= 5).length;
                        final outOfStock = productLogic.products.where((p) => p.quantity <= 0).length;

                        // Financial Calculations
                        final todaySales = "${currencyFormatter.format(saleLogic.todaySales)} Ks";
                        final todayProfit = "${currencyFormatter.format(saleLogic.todayProfit)} Ks";
                        final todayExpenses = "${currencyFormatter.format(saleLogic.todayExpenses)} Ks";

                        return GridView.count(
                          crossAxisCount: 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.98,
                          children: [
                            _buildGridDashboardItem(context, "Today's Sales", todaySales, Icons.point_of_sale, colorScheme.primary),
                            _buildGridDashboardItem(context, "Today Profit", todayProfit, Icons.trending_up, Colors.green),
                            _buildGridDashboardItem(context, "Today Expenses", todayExpenses, Icons.account_balance_wallet_outlined, Colors.purple),
                            _buildGridDashboardItem(context, "Total Product", "$totalProduct", Icons.inventory_2_outlined, colorScheme.primary),
                            _buildGridDashboardItem(context, "Low Stock", "$lowStock", Icons.warning_amber_rounded, Colors.orange),
                            _buildGridDashboardItem(context, "Out Of Stock", "$outOfStock", Icons.remove_shopping_cart_outlined, Colors.red),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Menu Grid Items
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 8,
                childAspectRatio: 1.85,
                children: [
                  _buildMenuCard(context, "Product", Icons.inventory, Colors.brown),
                  _buildMenuCard(context, "Sale", Icons.shopping_cart, Colors.redAccent),
                  _buildMenuCard(context, "Expenses", Icons.account_balance_wallet, Colors.green),
                  _buildMenuCard(context, "Daily Report", Icons.receipt_long, Colors.blueGrey),
                  _buildMenuCard(context, "Receipt", Icons.print, Colors.indigo),
                  _buildMenuCard(context, "VIP List", Icons.workspace_premium, Colors.amber),
                ],
              ),
              const SizedBox(height: 10),

              // Debt List Button
              SizedBox(
                width: double.infinity,
                height: 62,
                child: _buildDebtListButton(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridDashboardItem(BuildContext context, String title, String value, IconData icon, Color themeColor) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface.withAlpha(180),
          ),
        ),
        const SizedBox(height: 2),
        Expanded(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? theme.scaffoldBackgroundColor : const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: theme.dividerColor.withAlpha(80)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: themeColor),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: themeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color iconColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        if (title == "Receipt") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReceiptScreen()),
          );
        } else if (title == "Expenses") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ExpensesScreen()),
          );

          if (context.mounted) {
            Provider.of<SaleLogic>(context, listen: false).fetchDashboardMetrics();
          }
        } else if (title == "VIP List") {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const VipListScreen()),
          );
        } else if (title == "Daily Report") {
          // Daily Report Screen သို့ သွားရန် Navigation ချိတ်ဆက်ခြင်း
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DailyReportScreen()),
          );
        } else {
          HomeLogic.handleMenuClick(context, title);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtListButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DebtScreen()),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 50 : 10),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book, size: 24, color: Colors.orangeAccent),
            const SizedBox(width: 10),
            Text(
              "Debt List",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
