// lib/logic/receipt_logic.dart

import 'package:flutter/material.dart';

class ReceiptLogic extends ChangeNotifier {
  // Subscription State (Default: false - Free User)
  bool _isPremiumUser = false;

  // Customization Options
  bool _showShopLogo = true;
  bool _showShopAddress = true;
  bool _showShopPhone = true;
  bool _showCustomerInfo = true;
  bool _showTax = true;
  bool _showDiscount = true;
  String _customFooterText = "ကျေးဇူးတင်ပါသည်! နောက်လည်း လာအားပေးပါဦး။";

  // Getters
  bool get isPremiumUser => _isPremiumUser;
  bool get showShopLogo => _showShopLogo;
  bool get showShopAddress => _showShopAddress;
  bool get showShopPhone => _showShopPhone;
  bool get showCustomerInfo => _showCustomerInfo;
  bool get showTax => _showTax;
  bool get showDiscount => _showDiscount;
  String get customFooterText => _customFooterText;

  // Watermark ပြရန် လိုမလို (Free User ဖြစ်ပါက True)
  bool get showWatermark => !_isPremiumUser;

  // Upgrade / Set Plan (Subscription Logic)
  void setPremiumUser(bool value) {
    _isPremiumUser = value;
    notifyListeners();
  }

  // Setters / Toggle Methods for Quick Settings
  void setShowShopLogo(bool value) {
    _showShopLogo = value;
    notifyListeners();
  }

  void setShowShopAddress(bool value) {
    _showShopAddress = value;
    notifyListeners();
  }

  void setShowShopPhone(bool value) {
    _showShopPhone = value;
    notifyListeners();
  }

  void setShowCustomerInfo(bool value) {
    _showCustomerInfo = value;
    notifyListeners();
  }

  void setShowTax(bool value) {
    _showTax = value;
    notifyListeners();
  }

  void setShowDiscount(bool value) {
    _showDiscount = value;
    notifyListeners();
  }

  void setCustomFooterText(String text) {
    _customFooterText = text;
    notifyListeners();
  }
}
