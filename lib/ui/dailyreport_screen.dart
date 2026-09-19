// lib/ui/dailyreport_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../logic/dailyreport_logic.dart';
import '../global/utility/utils.dart';

class DailyReportScreen extends StatelessWidget {
  const DailyReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final reportLogic = Provider.of<DailyReportLogic>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => await reportLogic.fetchReportData(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 20),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                          colorScheme.tertiary ?? Colors.blueAccent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                      child: const Text(
                        "Daily Report",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 38), // Center Alignment
                  ],
                ),
                const SizedBox(height: 16),

                // 2. Calendar Selector Section (Updated to Custom Compact Picker)
                InkWell(
                  onTap: () => _showCompactDatePicker(context, reportLogic),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: colorScheme.primary),
                            const SizedBox(width: 10),
                            Text(
                              DateFormat('dd MMM yyyy (EEEE)').format(reportLogic.selectedDate),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. Mini Dashboard Cards
                Row(
                  children: [
                    _buildSummaryCard("Sales", "${Utils.formatAmount(reportLogic.totalSalesAmount)} Ks", Colors.blue, theme, isDark),
                    const SizedBox(width: 8),
                    _buildSummaryCard("Profit", "${Utils.formatAmount(reportLogic.totalProfit)} Ks", Colors.green, theme, isDark),
                    const SizedBox(width: 8),
                    _buildSummaryCard("Expenses", "${Utils.formatAmount(reportLogic.totalExpenses)} Ks", Colors.purple, theme, isDark),
                  ],
                ),
                const SizedBox(height: 16),

                // 4. Report Navigation Tabs
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton("Sale History", 0, reportLogic, theme),
                      _buildTabButton("Items Sold", 1, reportLogic, theme),
                      _buildTabButton("Payment Method", 2, reportLogic, theme),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // 5. Dynamic Data Table Section
                reportLogic.isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: theme.dividerColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _buildTableContent(reportLogic, theme),
                      ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Compact Calendar Dialog Implementation
  void _showCompactDatePicker(BuildContext context, DailyReportLogic logic) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    DateTime tempSelectedDate = logic.selectedDate;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Design
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.calendar_month, size: 20, color: primaryColor),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "ရက်စွဲ ရွေးချယ်ရန်",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleMedium?.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Compact Calendar View
                Theme(
                  data: theme.copyWith(
                    colorScheme: theme.colorScheme.copyWith(
                      primary: primaryColor,
                      onPrimary: theme.colorScheme.onPrimary,
                      surface: theme.cardColor,
                      onSurface: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  child: SizedBox(
                    height: 280,
                    width: 300,
                    child: CalendarDatePicker(
                      initialDate: tempSelectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      onDateChanged: (newDate) {
                        tempSelectedDate = newDate;
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text("မလုပ်တော့ပါ", style: TextStyle(color: theme.hintColor, fontSize: 13)),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        logic.setSelectedDate(tempSelectedDate);
                        Navigator.pop(context);
                      },
                      child: const Text("အတည်ပြုမည်", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color, ThemeData theme, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.15 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, DailyReportLogic logic, ThemeData theme) {
    bool isSelected = logic.selectedTabIndex == index;
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: () => logic.setSelectedTab(index),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? colorScheme.primary : theme.dividerColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ),
    );
  }

  Widget _buildTableContent(DailyReportLogic logic, ThemeData theme) {
    switch (logic.selectedTabIndex) {
      case 0:
        return _buildSaleHistoryTable(logic, theme);
      case 1:
        return _buildItemsSoldTable(logic, theme);
      case 2:
        return _buildPaymentMethodTable(logic, theme);
      default:
        return Container();
    }
  }

  // Sale History Table View
  Widget _buildSaleHistoryTable(DailyReportLogic logic, ThemeData theme) {
    final sales = logic.sales;

    if (sales.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Text(
            "ရွေးချယ်ထားသော ရက်စွဲတွင် ရောင်းရသော စာရင်းမရှိပါ",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dividerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text("Time/Receipt", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 4, child: Text("Items", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 2, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 2, child: Text("Pay", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: sales.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final sale = sales[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DateFormat('hh:mm a').format(sale.dateTime), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface)),
                        Text(sale.receiptNo, style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withOpacity(0.5))),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      sale.itemsSummary.isEmpty ? "No Items" : sale.itemsSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      "${Utils.formatAmount(sale.totalAmount)} Ks",
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sale.paymentMethod,
                          style: TextStyle(fontSize: 10, color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Items Sold Summary Table View
  Widget _buildItemsSoldTable(DailyReportLogic logic, ThemeData theme) {
    final items = logic.itemsSoldSummary;

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Text(
            "ရောင်းရသော ပစ္စည်းစာရင်း မရှိပါ",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dividerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(flex: 5, child: Text("Product Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 2, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 3, child: Text("Total Ks", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final item = items[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Expanded(flex: 5, child: Text(item.productName, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
                  Expanded(flex: 2, child: Text("${item.totalQty}", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))),
                  Expanded(flex: 3, child: Text("${Utils.formatAmount(item.totalAmount)} Ks", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // Payment Method Table View
  Widget _buildPaymentMethodTable(DailyReportLogic logic, ThemeData theme) {
    final payments = logic.paymentSummary;

    if (payments.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(30.0),
        child: Center(
          child: Text(
            "ငွေချေမှု စာရင်းမရှိပါ",
            style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6), fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          decoration: BoxDecoration(
            color: theme.dividerColor.withOpacity(0.08),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Expanded(flex: 4, child: Text("Payment Method", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 3, child: Text("Txn Count", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
              Expanded(flex: 3, child: Text("Total Amount", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.colorScheme.onSurface.withOpacity(0.7)))),
            ],
          ),
        ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: payments.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, index) {
            final payment = payments[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(payment.method, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface))),
                  Expanded(flex: 3, child: Text("${payment.count} Bills", textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface))),
                  Expanded(flex: 3, child: Text("${Utils.formatAmount(payment.totalAmount)} Ks", textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: theme.colorScheme.onSurface))),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
