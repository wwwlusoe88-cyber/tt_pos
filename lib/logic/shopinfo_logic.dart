import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../global/utility/utils.dart';

class ShopInfoLogic extends ChangeNotifier {
  // Keys for SharedPreferences
  static const String keyShopName = 'shop_name';
  static const String keyPhone = 'shop_phone';
  static const String keyAddress = 'shop_address';
  static const String keyTaxId = 'shop_tax_id';
  static const String keyHeaderNote = 'shop_header_note';
  static const String keyFooterNote = 'shop_footer_note';
  static const String keyLogoPath = 'shop_logo_path';
  static const String keyLogoShape = 'shop_logo_shape'; // 'rounded' or 'circle'

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController taxIdController = TextEditingController();
  final TextEditingController headerNoteController = TextEditingController();
  final TextEditingController footerNoteController = TextEditingController();

  String _logoPath = '';
  String _logoShape = 'rounded'; // Default rounded square
  bool _isLoading = true;

  String get logoPath => _logoPath;
  String get logoShape => _logoShape;
  bool get isLoading => _isLoading;

  ShopInfoLogic() {
    loadShopInfo();
  }

  // Load Shop Info from SharedPreferences
  Future<void> loadShopInfo() async {
    _isLoading = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    nameController.text = prefs.getString(keyShopName) ?? '';
    phoneController.text = prefs.getString(keyPhone) ?? '';
    addressController.text = prefs.getString(keyAddress) ?? '';
    taxIdController.text = prefs.getString(keyTaxId) ?? '';
    headerNoteController.text = prefs.getString(keyHeaderNote) ?? '';
    footerNoteController.text = prefs.getString(keyFooterNote) ?? '';
    _logoPath = prefs.getString(keyLogoPath) ?? '';
    _logoShape = prefs.getString(keyLogoShape) ?? 'rounded';

    _isLoading = false;
    notifyListeners();
  }

  void setLogoShape(String shape) {
    _logoShape = shape;
    notifyListeners();
  }

  // Pick Logo Image
  Future<void> pickLogoImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(source: source, imageQuality: 85);
      if (pickedFile != null) {
        _logoPath = pickedFile.path;
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Error picking logo: $e");
    }
  }

  // Save Shop Info
  Future<bool> saveShopInfo(BuildContext context) async {
    if (nameController.text.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Shop Name ထည့်သွင်းပါ။", isError: true);
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyShopName, nameController.text.trim());
    await prefs.setString(keyPhone, phoneController.text.trim());
    await prefs.setString(keyAddress, addressController.text.trim());
    await prefs.setString(keyTaxId, taxIdController.text.trim());
    await prefs.setString(keyHeaderNote, headerNoteController.text.trim());
    await prefs.setString(keyFooterNote, footerNoteController.text.trim());
    await prefs.setString(keyLogoPath, _logoPath);
    await prefs.setString(keyLogoShape, _logoShape);

    Utils.showTopToast(context, "ဆိုင်အချက်အလက်များ သိမ်းဆည်းပြီးပါပြီ။");
    notifyListeners();
    return true;
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    taxIdController.dispose();
    headerNoteController.dispose();
    footerNoteController.dispose();
    super.dispose();
  }
}
