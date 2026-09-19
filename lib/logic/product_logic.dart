import 'package:flutter/material.dart';
import '../global/utility/utils.dart';
import '../ui/supplier_screen.dart';
import '../ui/stockin_screen.dart';
import '../database/local_database.dart';
import '../service/camera_barcode.dart';

class ProductModel {
  final String id;
  final String name;
  final String productCode;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final double profit;
  final double discountPrice;
  final String barcode;
  final String supplier;
  final int? supplierId;
  final String ownerId;

  // Sync & Soft Delete Metadata
  final String updatedAt;
  final int isSynced;
  final int isDeleted;

  ProductModel({
    required this.id,
    required this.name,
    required this.productCode,
    required this.costPrice,
    required this.salePrice,
    required this.quantity,
    required this.profit,
    required this.discountPrice,
    required this.barcode,
    required this.supplier,
    this.supplierId,
    required this.ownerId,
    required this.updatedAt,
    this.isSynced = 0,
    this.isDeleted = 0,
  });

  // sale_screen.dart တွင် orElse ဖြင့် အသုံးပြုရန် empty factory constructor ထည့်သွင်းထားသည်
  factory ProductModel.empty() {
    return ProductModel(
      id: '',
      name: '',
      productCode: '',
      costPrice: 0.0,
      salePrice: 0.0,
      quantity: 0,
      profit: 0.0,
      discountPrice: 0.0,
      barcode: '',
      supplier: '',
      ownerId: '',
      updatedAt: '',
      isSynced: 0,
      isDeleted: 0,
    );
  }

  factory ProductModel.fromMap(Map<String, dynamic> map) {
    return ProductModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      productCode: map['product_code'] ?? '',
      costPrice: map['cost_price'] is int ? (map['cost_price'] as int).toDouble() : (map['cost_price'] ?? 0.0),
      salePrice: map['sale_price'] is int ? (map['sale_price'] as int).toDouble() : (map['sale_price'] ?? 0.0),
      quantity: map['quantity'] ?? 0,
      profit: map['profit'] is int ? (map['profit'] as int).toDouble() : (map['profit'] ?? 0.0),
      discountPrice: map['discount_price'] is int ? (map['discount_price'] as int).toDouble() : (map['discount_price'] ?? 0.0),
      barcode: map['barcode'] ?? '-',
      supplier: map['supplier'] ?? '-',
      supplierId: map['supplier_id'],
      ownerId: map['owner_id'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      isSynced: map['is_synced'] ?? 0,
      isDeleted: map['is_deleted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'product_code': productCode,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'quantity': quantity,
      'profit': profit,
      'discount_price': discountPrice,
      'barcode': barcode,
      'supplier': supplier,
      'supplier_id': supplierId,
      'owner_id': ownerId,
      'updated_at': updatedAt,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
    };
    if (id.isNotEmpty) {
      map['id'] = int.tryParse(id) ?? id;
    }
    return map;
  }
}

class ProductLogic extends ChangeNotifier {
  bool isVipUser = true;

  List<ProductModel> _allProducts = [];
  List<ProductModel> _filteredProducts = [];
  String _searchQuery = '';

  final String _currentOwnerId = "default_owner";

  ProductLogic() {
    fetchProducts();
  }

  List<ProductModel> get products => _filteredProducts;

  Future<void> fetchProducts() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'products',
      where: 'owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      whereArgs: [_currentOwnerId],
      orderBy: 'id DESC',
    );

    _allProducts = maps.map((map) => ProductModel.fromMap(map)).toList();
    filterProducts(_searchQuery);
  }

  void filterProducts(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredProducts = _allProducts;
    } else {
      _filteredProducts = _allProducts
          .where((p) => p.name.toLowerCase().contains(query.toLowerCase()) ||
              p.barcode.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> saveProduct(BuildContext context, {
    String? id,
    required String name,
    required String productCode,
    required String costPriceStr,
    required String salePriceStr,
    required String quantityStr,
    required double discountPrice,
    required String barcode,
    required String supplier,
  }) async {
    if (name.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Product Name ထည့်သွင်းပါ။", isError: true);
      return false;
    }
    if (costPriceStr.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Buy Price ထည့်သွင်းပါ။", isError: true);
      return false;
    }
    if (salePriceStr.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Sell Price ထည့်သွင်းပါ။", isError: true);
      return false;
    }
    if (quantityStr.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Quantity ထည့်သွင်းပါ။", isError: true);
      return false;
    }

    double costPrice = double.tryParse(costPriceStr) ?? 0.0;
    double salePrice = double.tryParse(salePriceStr) ?? 0.0;
    int quantity = int.tryParse(quantityStr) ?? 0;

    final db = await LocalDatabase.instance.database;
    double profit = salePrice - costPrice;

    String trimmedName = name.trim();
    String nowIsoString = DateTime.now().toIso8601String();

    if (id == null || id.isEmpty) {
      final List<Map<String, dynamic>> existingMaps = await db.query(
        'products',
        where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
        whereArgs: [trimmedName, _currentOwnerId],
      );

      if (existingMaps.isNotEmpty) {
        final existingProduct = ProductModel.fromMap(existingMaps.first);
        int newQuantity = existingProduct.quantity + quantity;
        int? numericId = int.tryParse(existingProduct.id);

        await db.update(
          'products',
          {
            'quantity': newQuantity,
            'cost_price': costPrice,
            'sale_price': salePrice,
            'profit': profit,
            'discount_price': discountPrice,
            'supplier': (supplier.isEmpty || supplier.contains('ရွေးပါ')) ? '-' : supplier,
            'updated_at': nowIsoString,
            'is_synced': 0,
            'is_deleted': 0,
          },
          where: 'id = ?',
          whereArgs: [numericId ?? existingProduct.id],
        );

        if (context.mounted) {
          Utils.showTopToast(context, "နဂိုရှိပြီးသား ပစ္စည်းသို့ အရေအတွက် ထပ်ပေါင်းပြီးပါပြီ။");
        }
        await fetchProducts();
        return true;
      }
    }

    String generatedCode = productCode.trim().isEmpty
        ? 'P-${DateTime.now().millisecondsSinceEpoch}'
        : productCode.trim();

    final productData = ProductModel(
      id: id ?? '',
      name: trimmedName,
      productCode: generatedCode,
      costPrice: costPrice,
      salePrice: salePrice,
      quantity: quantity,
      profit: profit,
      discountPrice: discountPrice,
      barcode: barcode.isEmpty ? '-' : barcode,
      supplier: (supplier.isEmpty || supplier.contains('ရွေးပါ')) ? '-' : supplier,
      ownerId: _currentOwnerId,
      updatedAt: nowIsoString,
      isSynced: 0,
      isDeleted: 0,
    );

    if (id == null || id.isEmpty) {
      if (!isVipUser && _allProducts.length >= 15) {
        Utils.showTopToast(context, "Free User ဖြစ်သဖြင့် Product ၁၅ ခုသာ ထည့်သွင်းခွင့်ရှိပါသည်။ VIP Upgrade လုပ်ပါ။", isError: true);
        return false;
      }
      await db.insert('products', productData.toMap());
      if (context.mounted) {
        Utils.showTopToast(context, "Product အသစ် ထည့်သွင်းပြီးပါပြီ။");
      }
    } else {
      int? numericId = int.tryParse(id);
      await db.update(
        'products',
        productData.toMap(),
        where: 'id = ?',
        whereArgs: [numericId ?? id],
      );
      if (context.mounted) {
        Utils.showTopToast(context, "Product အချက်အလက် ပြင်ဆင်ပြီးပါပြီ။");
      }
    }

    await fetchProducts();
    return true;
  }

  Future<void> deleteProduct(BuildContext context, String id) async {
    Utils.showConfirmDialog(
      context: context,
      title: "သတိပေးချက်",
      content: "ဤ Product ကို ဖျက်ရန် သေချာပါသလား?",
      confirmText: "ဖျက်မည်",
      onConfirm: () async {
        final db = await LocalDatabase.instance.database;
        int? numericId = int.tryParse(id);
        
        await db.update(
          'products',
          {
            'is_deleted': 1,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          },
          where: 'id = ?',
          whereArgs: [numericId ?? id],
        );

        await fetchProducts();
        if (context.mounted) {
          Utils.showTopToast(context, "Product ကို ဖျက်ပြီးပါပြီ။");
        }
      },
    );
  }

  static void handleSupplierClick(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SupplierScreen()),
    );
  }

  static Future<void> handleStockInClick(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StockInScreen()),
    );
  }

  static void handleAddProductClick(BuildContext context, ProductLogic logic) {
    showProductDialog(context, logic);
  }

  static Future<List<String>> _fetchSupplierNames() async {
    try {
      final db = await LocalDatabase.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'suppliers',
        where: 'is_deleted = 0 OR is_deleted IS NULL',
      );
      return maps.map((m) => m['name'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  static void showProductDialog(BuildContext context, ProductLogic logic, {ProductModel? productToEdit}) async {
    final bool isEditing = productToEdit != null;

    final TextEditingController nameController = TextEditingController(text: isEditing ? productToEdit.name : '');
    final TextEditingController costPriceController = TextEditingController(text: isEditing ? productToEdit.costPrice.toStringAsFixed(0) : '');
    final TextEditingController salePriceController = TextEditingController(text: isEditing ? productToEdit.salePrice.toStringAsFixed(0) : '');
    final TextEditingController qtyController = TextEditingController(text: isEditing ? productToEdit.quantity.toString() : '');
    
    final TextEditingController discountController = TextEditingController(text: isEditing ? productToEdit.discountPrice.toStringAsFixed(0) : '');
    final TextEditingController barcodeController = TextEditingController(text: isEditing ? productToEdit.barcode : '');

    final TextEditingController profitController = TextEditingController(
      text: isEditing ? productToEdit.profit.toStringAsFixed(0) : '0',
    );

    String selectedSupplier = isEditing ? productToEdit.supplier : '-- Supplier ရွေးပါ --';
    List<String> supplierList = await _fetchSupplierNames();
    if (!supplierList.contains('-- Supplier ရွေးပါ --')) {
      supplierList.insert(0, '-- Supplier ရွေးပါ --');
    }
    if (!supplierList.contains(selectedSupplier) && selectedSupplier != '-') {
      supplierList.add(selectedSupplier);
    }

    void calculateProfit() {
      double buy = double.tryParse(costPriceController.text) ?? 0.0;
      double sell = double.tryParse(salePriceController.text) ?? 0.0;
      double profit = sell - buy;
      profitController.text = profit.toStringAsFixed(0);
    }

    costPriceController.addListener(calculateProfit);
    salePriceController.addListener(calculateProfit);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              backgroundColor: theme.cardColor,
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "Edit Product" : "Add Product",
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.6), size: 20),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCompactRow(dialogContext, "Product Name", _buildField(dialogContext, nameController, "Enter product name")),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Supplier", Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: theme.cardColor,
                          value: supplierList.contains(selectedSupplier) ? selectedSupplier : '-- Supplier ရွေးပါ --',
                          isExpanded: true,
                          items: supplierList.map((String sup) {
                            return DropdownMenuItem<String>(
                              value: sup,
                              child: Text(
                                sup, 
                                style: TextStyle(
                                  fontSize: 13, 
                                  color: sup.contains('ရွေးပါ') ? colorScheme.onSurface.withOpacity(0.4) : colorScheme.onSurface,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setStateSB(() {
                                selectedSupplier = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Buy Price", _buildField(dialogContext, costPriceController, "0", keyboardType: TextInputType.number)),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Sell Price", _buildField(dialogContext, salePriceController, "0", keyboardType: TextInputType.number)),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Profit", Container(
                      height: 40,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: TextField(
                        controller: profitController,
                        readOnly: true,
                        textAlignVertical: TextAlignVertical.center,
                        style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface.withOpacity(0.6), fontSize: 13),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        ),
                      ),
                    )),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Quantity", _buildField(dialogContext, qtyController, "0", keyboardType: TextInputType.number)),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Discount Price", _buildField(dialogContext, discountController, "0", keyboardType: TextInputType.number)),
                    const SizedBox(height: 8),
                    _buildCompactRow(dialogContext, "Barcode", TextField(
                      controller: barcodeController,
                      keyboardType: TextInputType.text,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                      decoration: InputDecoration(
                        hintText: "Scan or enter barcode",
                        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
                        suffixIcon: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: Icon(Icons.camera_alt, color: colorScheme.primary, size: 18),
                          onPressed: () {
                            CameraBarcodeScanner.showScanner(
                              dialogContext,
                              onScanCompleted: (scannedCode) {
                                setStateSB(() {
                                  barcodeController.text = scannedCode;
                                });
                              },
                            );
                          },
                        ),
                      ),
                    )),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, size: 16, color: Colors.white),
                            label: const Text("Cancel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[600],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              bool success = await logic.saveProduct(
                                context,
                                id: isEditing ? productToEdit.id : null,
                                name: nameController.text,
                                productCode: isEditing ? productToEdit.productCode : '',
                                costPriceStr: costPriceController.text,
                                salePriceStr: salePriceController.text,
                                quantityStr: qtyController.text,
                                discountPrice: double.tryParse(discountController.text) ?? 0.0,
                                barcode: barcodeController.text,
                                supplier: selectedSupplier,
                              );
                              if (success && dialogContext.mounted) {
                                Navigator.pop(dialogContext);
                              }
                            },
                            icon: const Icon(Icons.save, size: 16, color: Colors.white),
                            label: Text(isEditing ? "Update" : "Save", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[700],
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildCompactRow(BuildContext context, String label, Widget fieldWidget) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: fieldWidget,
        ),
      ],
    );
  }

  static Widget _buildField(BuildContext context, TextEditingController controller, String hint, {TextInputType keyboardType = TextInputType.text}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: theme.dividerColor)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: colorScheme.primary)),
        ),
      ),
    );
  }
}
