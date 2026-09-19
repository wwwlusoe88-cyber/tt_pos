// lib/logic/dailyreport_logic.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/local_database.dart';

class SaleOrderItem {
  final String productName;
  final int quantity;
  final double unitPrice;

  SaleOrderItem({
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get totalPrice => quantity * unitPrice;
}

class SaleRecord {
  final int id;
  final String receiptNo;
  final DateTime dateTime;
  final String customerName;
  final List<SaleOrderItem> items;
  final double totalAmount;
  final String paymentMethod;

  SaleRecord({
    required this.id,
    required this.receiptNo,
    required this.dateTime,
    required this.customerName,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
  });

  String get itemsSummary => items.map((i) => "${i.productName} (x${i.quantity})").join(", ");
}

class ItemSoldSummary {
  final String productName;
  final int totalQty;
  final double totalAmount;

  ItemSoldSummary({
    required this.productName,
    required this.totalQty,
    required this.totalAmount,
  });
}

class PaymentSummary {
  final String method;
  final int count;
  final double totalAmount;

  PaymentSummary({
    required this.method,
    required this.count,
    required this.totalAmount,
  });
}

class DailyReportLogic extends ChangeNotifier {
  DateTime _selectedDate = DateTime.now();
  int _selectedTabIndex = 0; 
  bool _isLoading = false;

  List<SaleRecord> _sales = [];
  double _totalExpenses = 0.0;
  double _totalProfit = 0.0;

  DateTime get selectedDate => _selectedDate;
  int get selectedTabIndex => _selectedTabIndex;
  bool get isLoading => _isLoading;
  List<SaleRecord> get sales => _sales;
  double get totalExpenses => _totalExpenses;
  double get totalProfit => _totalProfit;

  DailyReportLogic() {
    fetchReportData();
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    fetchReportData();
  }

  void setSelectedTab(int index) {
    _selectedTabIndex = index;
    notifyListeners();
  }

  // Local Database မှ Data များ ဆွဲထုတ်ပေးခြင်း
  Future<void> fetchReportData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final db = await LocalDatabase.instance.database;
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      // 1. Sales နှင့် Items ယူခြင်း
      final salesData = await db.rawQuery('''
        SELECT * FROM sales 
        WHERE sale_date LIKE '$dateStr%' 
        ORDER BY id DESC
      ''');

      List<SaleRecord> loadedSales = [];
      double tempProfit = 0.0;

      for (var sale in salesData) {
        final saleId = sale['id'] as int;
        
        final itemsData = await db.rawQuery('''
          SELECT si.*, p.name as product_name, p.cost_price 
          FROM sale_items si
          LEFT JOIN products p ON si.product_id = p.id
          WHERE si.sale_id = ?
        ''', [saleId]);

        List<SaleOrderItem> items = [];
        for (var item in itemsData) {
          final qty = item['quantity'] as int;
          final unitPrice = (item['unit_price'] as num).toDouble();
          final costPrice = (item['cost_price'] as num?)?.toDouble() ?? 0.0;
          
          tempProfit += (unitPrice - costPrice) * qty;

          items.add(SaleOrderItem(
            productName: (item['product_name'] ?? 'Item') as String,
            quantity: qty,
            unitPrice: unitPrice,
          ));
        }

        loadedSales.add(SaleRecord(
          id: saleId,
          receiptNo: "#${saleId.toString().padLeft(5, '0')}",
          dateTime: DateTime.tryParse(sale['sale_date'].toString()) ?? _selectedDate,
          customerName: (sale['staff_name'] ?? 'General') as String,
          items: items,
          totalAmount: (sale['total_amount'] as num).toDouble(),
          paymentMethod: (sale['payment_method'] ?? 'Cash') as String,
        ));
      }

      _sales = loadedSales;
      _totalProfit = tempProfit;

      // 2. Expenses ယူခြင်း
      final expensesData = await db.rawQuery('''
        SELECT SUM(amount) as total FROM expenses 
        WHERE date_time LIKE '$dateStr%' AND is_deleted = 0
      ''');

      if (expensesData.isNotEmpty && expensesData.first['total'] != null) {
        _totalExpenses = (expensesData.first['total'] as num).toDouble();
      } else {
        _totalExpenses = 0.0;
      }
    } catch (e) {
      debugPrint("Error fetching report data: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculations
  double get totalSalesAmount {
    return _sales.fold(0, (sum, item) => sum + item.totalAmount);
  }

  // Items Sold Summary
  List<ItemSoldSummary> get itemsSoldSummary {
    Map<String, ItemSoldSummary> summaryMap = {};

    for (var sale in _sales) {
      for (var item in sale.items) {
        if (summaryMap.containsKey(item.productName)) {
          final existing = summaryMap[item.productName]!;
          summaryMap[item.productName] = ItemSoldSummary(
            productName: item.productName,
            totalQty: existing.totalQty + item.quantity,
            totalAmount: existing.totalAmount + item.totalPrice,
          );
        } else {
          summaryMap[item.productName] = ItemSoldSummary(
            productName: item.productName,
            totalQty: item.quantity,
            totalAmount: item.totalPrice,
          );
        }
      }
    }
    return summaryMap.values.toList();
  }

  // Payment Method Summary
  List<PaymentSummary> get paymentSummary {
    Map<String, PaymentSummary> summaryMap = {};

    for (var sale in _sales) {
      final method = sale.paymentMethod;
      if (summaryMap.containsKey(method)) {
        final existing = summaryMap[method]!;
        summaryMap[method] = PaymentSummary(
          method: method,
          count: existing.count + 1,
          totalAmount: existing.totalAmount + sale.totalAmount,
        );
      } else {
        summaryMap[method] = PaymentSummary(
          method: method,
          count: 1,
          totalAmount: sale.totalAmount,
        );
      }
    }
    return summaryMap.values.toList();
  }
}
