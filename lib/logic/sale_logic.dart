// sale_logic.dart

import 'package:flutter/material.dart';
import '../database/local_database.dart';
import '../global/utility/utils.dart';
import 'product_logic.dart';
import 'viplist_logic.dart'; // VIP Member Class အသုံးပြုရန် Import လုပ်ပါ

class CartItem {
  final ProductModel product;
  int quantity;
  bool isDiscountApplied;

  CartItem({
    required this.product,
    this.quantity = 1,
    this.isDiscountApplied = false,
  });

  double get unitPrice => isDiscountApplied && product.discountPrice > 0
      ? product.discountPrice
      : product.salePrice;

  double get itemTotal => unitPrice * quantity;
}

class HeldOrder {
  final String id;
  final DateTime time;
  final List<CartItem> items;
  final double discount;
  final double taxRate;
  final VipMember? selectedVipMember;

  HeldOrder({
    required this.id,
    required this.time,
    required this.items,
    required this.discount,
    required this.taxRate,
    this.selectedVipMember,
  });

  double get subTotal => items.fold(0.0, (sum, item) => sum + item.itemTotal);
  double get taxableAmount => (subTotal - discount) < 0 ? 0 : (subTotal - discount);
  double get taxAmount => taxableAmount * (taxRate / 100);
  double get total => taxableAmount + taxAmount;
}

class SaleLogic extends ChangeNotifier {
  final String _currentOwnerId = "default_owner";
  final String _currentStoreId = "default_store";

  List<CartItem> _cartItems = [];
  
  // VIP Member Integration States
  VipMember? _selectedVipMember; 
  double _overallDiscount = 0.0;
  double _taxRate = 0.0; 
  String _selectedPaymentMethod = "Cash"; 
  double _receivedCash = 0.0;

  final List<HeldOrder> _heldOrders = [];

  double _todaySales = 0.0;
  double _todayProfit = 0.0;
  double _todayExpenses = 0.0;

  // Getters
  List<CartItem> get cartItems => _cartItems;
  VipMember? get selectedVipMember => _selectedVipMember;
  String get customerDisplayName => _selectedVipMember != null 
      ? "${_selectedVipMember!.name} (${_selectedVipMember!.tier})" 
      : "Normal Customer";

  double get overallDiscount => _overallDiscount;
  double get taxRate => _taxRate;
  String get selectedPaymentMethod => _selectedPaymentMethod;
  double get receivedCash => _receivedCash;
  List<HeldOrder> get heldOrders => _heldOrders;
  int get heldOrdersCount => _heldOrders.length;

  double get todaySales => _todaySales;
  double get todayProfit => _todayProfit;
  double get todayExpenses => _todayExpenses;

  // 1. VIP Member ရွေးချယ်ခြင်းနှင့် Auto-Discount တွက်ပေးခြင်း
  void selectVipMember(VipMember? member, VipListLogic vipLogic) {
    _selectedVipMember = member;
    
    if (member != null) {
      // VIP Tier အလိုက် Discount Percentage ယူပြီး Auto-Discount ထည့်ပေးမည်
      double discPercent = vipLogic.getDiscountPercentageForTier(member.tier);
      if (discPercent > 0) {
        _overallDiscount = (subTotal * (discPercent / 100));
      }
    } else {
      _overallDiscount = 0.0;
    }
    
    notifyListeners();
  }

  // 2. Cart ထဲ ပစ္စည်းထည့်ခြင်း / တိုးခြင်း
  void addToCart(ProductModel product, BuildContext context) {
    int existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex >= 0) {
      if (_cartItems[existingIndex].quantity + 1 > product.quantity) {
        Utils.showTopToast(context, "လက်ကျန် Stock အရေအတွက်ထက် ပိုရောင်း၍မရပါ", isError: true);
        return;
      }
      _cartItems[existingIndex].quantity++;
    } else {
      if (product.quantity < 1) {
        Utils.showTopToast(context, "ဤပစ္စည်းသည် Stock မရှိတော့ပါ", isError: true);
        return;
      }
      _cartItems.add(CartItem(product: product));
    }
    notifyListeners();
  }

  void updateQuantity(int index, int delta, BuildContext context) {
    if (delta > 0) {
      if (_cartItems[index].quantity + 1 > _cartItems[index].product.quantity) {
        Utils.showTopToast(context, "လက်ကျန် Stock ထက် ပိုမရပါ", isError: true);
        return;
      }
      _cartItems[index].quantity++;
    } else {
      _cartItems[index].quantity--;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
    }
    notifyListeners();
  }

  void toggleItemDiscount(int index) {
    if (_cartItems[index].product.discountPrice > 0) {
      _cartItems[index].isDiscountApplied = !_cartItems[index].isDiscountApplied;
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _selectedVipMember = null;
    _overallDiscount = 0.0;
    _taxRate = 0.0;
    _receivedCash = 0.0;
    notifyListeners();
  }

  void setOverallDiscount(double discount) {
    _overallDiscount = discount;
    notifyListeners();
  }

  void setTaxRate(double rate) {
    _taxRate = rate;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  void setReceivedCash(double amount) {
    _receivedCash = amount;
    notifyListeners();
  }

  double get subTotal => _cartItems.fold(0.0, (sum, item) => sum + item.itemTotal);

  double get taxableAmount {
    double base = subTotal - _overallDiscount;
    return base < 0 ? 0.0 : base;
  }

  double get taxAmount => taxableAmount * (_taxRate / 100);

  double get grandTotal => taxableAmount + taxAmount;

  double get changeAmount {
    if (_selectedPaymentMethod != 'Cash') return 0.0;
    return _receivedCash >= grandTotal ? _receivedCash - grandTotal : 0.0;
  }

  // Hold Order Logic
  void holdOrder(BuildContext context) {
    if (_cartItems.isEmpty) {
      Utils.showTopToast(context, "Hold လုပ်ရန် Cart ထဲတွင် ပစ္စည်းမရှိပါ", isError: true);
      return;
    }

    _heldOrders.add(
      HeldOrder(
        id: "#${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}",
        time: DateTime.now(),
        items: List.from(_cartItems),
        discount: _overallDiscount,
        taxRate: _taxRate,
        selectedVipMember: _selectedVipMember,
      ),
    );

    clearCart();
    Utils.showTopToast(context, "Order ကို ခေတ္တ သိမ်းဆည်းထားပြီးပါပြီ");
  }

  void restoreHeldOrder(int index) {
    HeldOrder order = _heldOrders[index];
    _cartItems = List.from(order.items);
    _overallDiscount = order.discount;
    _taxRate = order.taxRate;
    _selectedVipMember = order.selectedVipMember;
    _heldOrders.removeAt(index);
    notifyListeners();
  }

  void deleteHeldOrder(int index) {
    _heldOrders.removeAt(index);
    notifyListeners();
  }

  Future<void> fetchDashboardMetrics() async {
    try {
      final db = await LocalDatabase.instance.database;
      final String todayStr = DateTime.now().toIso8601String().split('T')[0];

      final salesResult = await db.rawQuery(
        "SELECT SUM(total_amount) as total FROM sales WHERE sale_date LIKE '$todayStr%'",
      );
      _todaySales = (salesResult.first['total'] as num?)?.toDouble() ?? 0.0;

      final profitResult = await db.rawQuery('''
        SELECT SUM((si.unit_price - p.cost_price) * si.quantity) as total_profit
        FROM sale_items si
        INNER JOIN sales s ON si.sale_id = s.id
        INNER JOIN products p ON si.product_id = p.id
        WHERE s.sale_date LIKE '$todayStr%'
      ''');
      _todayProfit = (profitResult.first['total_profit'] as num?)?.toDouble() ?? 0.0;

      final expenseResult = await db.rawQuery(
        "SELECT SUM(amount) as total FROM expenses WHERE date_time LIKE '$todayStr%' AND is_deleted = 0",
      );
      _todayExpenses = (expenseResult.first['total'] as num?)?.toDouble() ?? 0.0;

      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching dashboard metrics: $e");
    }
  }

  // Process Checkout ပြုလုပ်ချိန်တွင် VIP Member ၏ Total Spent & Points များကို အလိုအလျောက် တိုးပေးခြင်း
  Future<bool> processCheckout(BuildContext context, ProductLogic productLogic, VipListLogic vipLogic) async {
    if (_cartItems.isEmpty) {
      Utils.showTopToast(context, "ဝယ်ယူထားသော ပစ္စည်းမရှိပါ", isError: true);
      return false;
    }

    if (_selectedPaymentMethod == 'Cash' && _receivedCash < grandTotal) {
      Utils.showTopToast(context, "ပေးငွေ မလုံလောက်ပါ", isError: true);
      return false;
    }

    try {
      final db = await LocalDatabase.instance.database;
      final String nowIso = DateTime.now().toIso8601String();

      await db.transaction((txn) async {
        // 1. Save Sale Master
        int saleId = await txn.insert('sales', {
          'sale_date': nowIso,
          'total_amount': grandTotal,
          'staff_name': customerDisplayName,
          'owner_id': _currentOwnerId,
          'store_id': _currentStoreId,
          'updated_at': nowIso,
          'is_synced': 0,
        });

        // 2. Save Items & Deduct Stock
        for (var item in _cartItems) {
          await txn.insert('sale_items', {
            'sale_id': saleId,
            'product_id': int.tryParse(item.product.id) ?? 0,
            'quantity': item.quantity,
            'unit_price': item.unitPrice,
            'sub_total': item.itemTotal,
          });

          int remainingQty = item.product.quantity - item.quantity;
          await txn.update(
            'products',
            {
              'quantity': remainingQty < 0 ? 0 : remainingQty,
              'updated_at': nowIso,
              'is_synced': 0,
            },
            where: 'id = ?',
            whereArgs: [item.product.id],
          );
        }

        // 3. VIP Member ဖြစ်ပါက Total Spent နှင့် Points အလိုအလျောက် တိုးပေးခြင်း
        if (_selectedVipMember != null) {
          double newTotalSpent = _selectedVipMember!.totalSpent + grandTotal;
          // ကျပ် ၁၀,၀၀၀ ဝယ်ယူလျှင် ၁ Point ရရှိမည်ဟု တွက်ချက်ခြင်း (Standard Logic)
          int earnedPoints = (grandTotal / 10000).floor(); 
          int newPoints = _selectedVipMember!.points + earnedPoints;
          String autoTier = vipLogic.calculateTier(newTotalSpent);

          await txn.update(
            'vips',
            {
              'total_spent': newTotalSpent,
              'points': newPoints,
              'tier': autoTier,
              'last_purchase_date': nowIso.split('T')[0],
              'updated_at': nowIso,
            },
            where: 'id = ?',
            whereArgs: [_selectedVipMember!.id],
          );
        }
      });

      await productLogic.fetchProducts();
      await vipLogic.fetchVipMembers(); // Refresh VIP Data
      await fetchDashboardMetrics();
      clearCart();
      Utils.showTopToast(context, "အရောင်းစာရင်း သိမ်းဆည်းပြီးပါပြီ");
      return true;
    } catch (e) {
      Utils.showTopToast(context, "အရောင်းသိမ်းဆည်းရာတွင် အမှားဖြစ်ပေါ်ပါသည်: $e", isError: true);
      return false;
    }
  }
}
