import 'package:flutter/material.dart';
import '../logic/stockin_logic.dart';

class StockInScreen extends StatefulWidget {
  const StockInScreen({Key? key}) : super(key: key);

  @override
  State<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends State<StockInScreen> {
  late final StockInLogic _stockInLogic;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _stockInLogic = StockInLogic();
    _stockInLogic.addListener(_onLogicChanged);
  }

  void _onLogicChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _stockInLogic.removeListener(_onLogicChanged);
    _stockInLogic.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    int totalCount = _stockInLogic.stockIns.length;
    String stockInLabel = "$totalCount Purchase Orders";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.arrow_back, color: theme.iconTheme.color ?? colorScheme.onSurface, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Stock In ( Purchase )",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ) ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Add New Purchase Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => StockInLogic.showStockInDialog(context, _stockInLogic),
                  icon: Icon(Icons.add, size: 18, color: colorScheme.onPrimary),
                  label: Text(
                    "New Purchase",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _stockInLogic.filterStockIns(value),
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: "Search PO number, supplier, or product",
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Counter Label
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    stockInLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 5. Stock In Cards List View
              _stockInLogic.stockIns.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          "Purchase ဇယားများ မရှိသေးပါ။",
                          style: TextStyle(color: theme.hintColor, fontSize: 15),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _stockInLogic.stockIns.length,
                      itemBuilder: (context, index) {
                        final item = _stockInLogic.stockIns[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
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
                                  Row(
                                    children: [
                                      Icon(Icons.receipt_long, size: 18, color: colorScheme.primary),
                                      const SizedBox(width: 6),
                                      Text(
                                        item.voucherNo,
                                        style: textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          StockInLogic.showStockInDialog(
                                            context,
                                            _stockInLogic,
                                            stockInToEdit: item,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.dividerColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.dividerColor),
                                          ),
                                          child: Icon(Icons.edit_outlined, size: 16, color: theme.hintColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _stockInLogic.deleteStockIn(context, item.id),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                                          ),
                                          child: Icon(Icons.delete_outline, size: 16, color: colorScheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.business, size: 13, color: Colors.green),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.supplier,
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today, size: 12, color: theme.hintColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        item.date,
                                        style: TextStyle(fontSize: 11.5, color: theme.hintColor, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(height: 1, color: theme.dividerColor),
                              const SizedBox(height: 8),
                              Column(
                                children: item.items.map((prod) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                                    child: Row(
                                      children: [
                                        Icon(Icons.inventory_2_outlined, size: 14, color: theme.hintColor),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            prod.productName,
                                            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          "${prod.quantity} x ${prod.costPrice.toStringAsFixed(0)} MMK",
                                          style: textTheme.bodySmall?.copyWith(color: theme.hintColor),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text(
                                    "Total: ",
                                    style: textTheme.bodyMedium?.copyWith(color: theme.hintColor, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    "${item.totalAmount.toStringAsFixed(0)} MMK",
                                    style: TextStyle(fontSize: 14, color: colorScheme.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
