import 'package:flutter/material.dart';
import '../global/utility/utils.dart';
import '../database/local_database.dart';

// Stock In Item Single Data Class
class StockInItem {
  String productName;
  int quantity;
  double costPrice;
  double salePrice;
  double itemTotal;

  StockInItem({
    required this.productName,
    required this.quantity,
    required this.costPrice,
    this.salePrice = 0.0,
    required this.itemTotal,
  });

  Map<String, dynamic> toMap() {
    return {
      'product_name': productName,
      'quantity': quantity,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'item_total': itemTotal,
    };
  }

  factory StockInItem.fromMap(Map<String, dynamic> map) {
    return StockInItem(
      productName: map['product_name'] ?? '',
      quantity: map['quantity'] ?? 0,
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      salePrice: (map['sale_price'] as num?)?.toDouble() ?? 0.0,
      itemTotal: (map['item_total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

// Dialog အတွက် Controllers များနှင့် FocusNodes များကို ထိန်းချုပ်ရန် Wrapper Class
class StockInFormRow {
  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController costController;
  final TextEditingController saleController;

  final FocusNode nameFocusNode;
  final FocusNode qtyFocusNode;
  final FocusNode costFocusNode;
  final FocusNode saleFocusNode;

  final StockInItem item;

  StockInFormRow({
    required this.item,
  })  : nameController = TextEditingController(text: item.productName),
        qtyController = TextEditingController(text: item.quantity == 0 ? '' : item.quantity.toString()),
        costController = TextEditingController(text: item.costPrice == 0.0 ? '' : item.costPrice.toStringAsFixed(0)),
        saleController = TextEditingController(text: item.salePrice == 0.0 ? '' : item.salePrice.toStringAsFixed(0)),
        nameFocusNode = FocusNode(),
        qtyFocusNode = FocusNode(),
        costFocusNode = FocusNode(),
        saleFocusNode = FocusNode();

  void dispose() {
    nameController.dispose();
    qtyController.dispose();
    costController.dispose();
    saleController.dispose();

    nameFocusNode.dispose();
    qtyFocusNode.dispose();
    costFocusNode.dispose();
    saleFocusNode.dispose();
  }
}

// Main Stock In Purchase Record Model
class StockInModel {
  final String id;
  final String voucherNo;
  final String supplier;
  final String date;
  final double totalAmount;
  final String note;
  final String ownerId;
  final List<StockInItem> items;

  StockInModel({
    required this.id,
    required this.voucherNo,
    required this.supplier,
    required this.date,
    required this.totalAmount,
    required this.note,
    required this.ownerId,
    required this.items,
  });

  factory StockInModel.fromMap(Map<String, dynamic> map, List<StockInItem> itemsList) {
    return StockInModel(
      id: map['id'].toString(),
      voucherNo: map['voucher_no'] ?? '-',
      supplier: map['supplier'] ?? '-',
      date: map['date'] ?? '',
      totalAmount: (map['total_amount'] as num?)?.toDouble() ?? 0.0,
      note: map['note'] ?? '-',
      ownerId: map['owner_id'] ?? '',
      items: itemsList,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'voucher_no': voucherNo,
      'supplier': supplier,
      'date': date,
      'total_amount': totalAmount,
      'note': note,
      'owner_id': ownerId,
    };
    if (id.isNotEmpty) {
      map['id'] = int.tryParse(id) ?? id;
    }
    return map;
  }
}

class StockInLogic extends ChangeNotifier {
  List<StockInModel> _allStockIns = [];
  List<StockInModel> _filteredStockIns = [];
  String _searchQuery = '';

  static const String _currentOwnerId = "default_owner";

  StockInLogic() {
    fetchStockIns();
  }

  List<StockInModel> get stockIns => _filteredStockIns;

  // DB မှ Purchase Records များနှင့် Detail Items များကို ဆွဲယူခြင်း
  Future<void> fetchStockIns() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'stock_ins',
      where: 'owner_id = ?',
      whereArgs: [_currentOwnerId],
      orderBy: 'id DESC',
    );

    List<StockInModel> loadedList = [];
    for (var map in maps) {
      final String stockInId = map['id'].toString();
      int? numericStockInId = int.tryParse(stockInId);

      final List<Map<String, dynamic>> itemMaps = await db.query(
        'stock_in_details',
        where: 'stock_in_id = ?',
        whereArgs: [numericStockInId ?? stockInId],
      );
      List<StockInItem> items = itemMaps.map((i) => StockInItem.fromMap(i)).toList();
      loadedList.add(StockInModel.fromMap(map, items));
    }

    _allStockIns = loadedList;
    filterStockIns(_searchQuery);
  }

  void filterStockIns(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredStockIns = _allStockIns;
    } else {
      _filteredStockIns = _allStockIns.where((s) {
        bool matchesVoucherOrSupplier = s.voucherNo.toLowerCase().contains(query.toLowerCase()) ||
            s.supplier.toLowerCase().contains(query.toLowerCase());
        bool matchesProduct = s.items.any((item) => item.productName.toLowerCase().contains(query.toLowerCase()));
        return matchesVoucherOrSupplier || matchesProduct;
      }).toList();
    }
    notifyListeners();
  }

  // Stock In သိမ်းဆည်းခြင်း
  Future<bool> saveStockIn(
    BuildContext context, {
    String? id,
    required String supplier,
    required String note,
    required List<StockInItem> items,
  }) async {
    double grandTotal = items.fold(0.0, (sum, i) => sum + i.itemTotal);
    String formattedDate = "${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}";
    String voucherNo = "PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

    final db = await LocalDatabase.instance.database;

    int stockInId;
    if (id == null || id.isEmpty) {
      stockInId = await db.insert('stock_ins', {
        'voucher_no': voucherNo,
        'supplier': supplier,
        'date': formattedDate,
        'total_amount': grandTotal,
        'note': note.isEmpty ? '-' : note,
        'owner_id': _currentOwnerId,
      });

      if (context.mounted) {
        Utils.showTopToast(context, "Purchase အသစ် ထည့်သွင်းပြီး Product Stock များ တိုးပြီးပါပြီ။");
      }
    } else {
      stockInId = int.tryParse(id) ?? 0;
      await db.update(
        'stock_ins',
        {
          'supplier': supplier,
          'date': formattedDate,
          'total_amount': grandTotal,
          'note': note.isEmpty ? '-' : note,
        },
        where: 'id = ?',
        whereArgs: [stockInId],
      );
      await db.delete('stock_in_details', where: 'stock_in_id = ?', whereArgs: [stockInId]);

      if (context.mounted) {
        Utils.showTopToast(context, "Purchase အချက်အလက် ပြင်ဆင်ပြီးပါပြီ။");
      }
    }

    for (var item in items) {
      final trimmedName = item.productName.trim();
      final List<Map<String, dynamic>> existingProducts = await db.query(
        'products',
        where: 'LOWER(TRIM(name)) = LOWER(TRIM(?)) AND owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
        whereArgs: [trimmedName, _currentOwnerId],
      );

      await db.insert('stock_in_details', {
        'stock_in_id': stockInId,
        'product_name': trimmedName,
        'quantity': item.quantity,
        'cost_price': item.costPrice,
        'sale_price': item.salePrice,
        'item_total': item.itemTotal,
      });

      double profit = item.salePrice - item.costPrice;

      if (existingProducts.isNotEmpty) {
        final existing = existingProducts.first;
        int existingQty = existing['quantity'] ?? 0;
        int updatedQty = existingQty + item.quantity;

        await db.update(
          'products',
          {
            'quantity': updatedQty,
            'cost_price': item.costPrice,
            'sale_price': item.salePrice,
            'profit': profit,
            'supplier': supplier,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          },
          where: 'id = ?',
          whereArgs: [existing['id']],
        );
      } else {
        await db.insert('products', {
          'name': trimmedName,
          'product_code': 'P-${DateTime.now().millisecondsSinceEpoch}',
          'cost_price': item.costPrice,
          'sale_price': item.salePrice,
          'quantity': item.quantity,
          'profit': profit,
          'discount_price': 0.0,
          'barcode': '-',
          'supplier': supplier,
          'owner_id': _currentOwnerId,
          'updated_at': DateTime.now().toIso8601String(),
          'is_synced': 0,
          'is_deleted': 0,
        });
      }
    }

    await fetchStockIns();
    return true;
  }

  Future<void> deleteStockIn(BuildContext context, String id) async {
    Utils.showConfirmDialog(
      context: context,
      title: "သတိပေးချက်",
      content: "ဤ Purchase Record ကို ဖျက်ရန် သေချာပါသလား?",
      confirmText: "ဖျက်မည်",
      onConfirm: () async {
        final db = await LocalDatabase.instance.database;
        int? numericId = int.tryParse(id);

        await db.delete('stock_ins', where: 'id = ?', whereArgs: [numericId ?? id]);
        await db.delete('stock_in_details', where: 'stock_in_id = ?', whereArgs: [numericId ?? id]);

        await fetchStockIns();
        if (context.mounted) {
          Utils.showTopToast(context, "Purchase ကို ဖျက်ပြီးပါပြီ။");
        }
      },
    );
  }

  static Future<List<Map<String, dynamic>>> _fetchProducts() async {
    try {
      final db = await LocalDatabase.instance.database;
      return await db.query(
        'products',
        where: 'owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
        whereArgs: [_currentOwnerId],
      );
    } catch (e) {
      return [];
    }
  }

  static Future<List<String>> _fetchSupplierNames() async {
    try {
      final db = await LocalDatabase.instance.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'suppliers',
        where: 'owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
        whereArgs: [_currentOwnerId],
      );
      return maps.map((m) => m['name'].toString()).toList();
    } catch (e) {
      return [];
    }
  }

  // Multi-item Dialog Form Call
  static void showStockInDialog(BuildContext parentContext, StockInLogic logic, {StockInModel? stockInToEdit}) async {
    final bool isEditing = stockInToEdit != null;

    String selectedSupplier = isEditing ? stockInToEdit.supplier : '-- Select Supplier --';
    List<String> supplierList = await _fetchSupplierNames();
    if (!supplierList.contains('-- Select Supplier --')) {
      supplierList.insert(0, '-- Select Supplier --');
    }
    if (!supplierList.contains(selectedSupplier) && selectedSupplier != '-') {
      supplierList.add(selectedSupplier);
    }

    List<Map<String, dynamic>> availableProducts = await _fetchProducts();

    if (!parentContext.mounted) return;

    showDialog(
      context: parentContext,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _StockInDialogContent(
          logic: logic,
          parentContext: parentContext,
          isEditing: isEditing,
          stockInToEdit: stockInToEdit,
          supplierList: supplierList,
          selectedSupplier: selectedSupplier,
          availableProducts: availableProducts,
        );
      },
    );
  }

  static Widget _buildLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.bold,
        color: theme.textTheme.bodyLarge?.color ?? theme.colorScheme.onSurface,
      ),
    );
  }

  static Widget _buildSmallField(
    BuildContext context,
    String label,
    String placeholder,
    TextEditingController controller,
    FocusNode focusNode,
    Function(String) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        onChanged: onChanged,
        style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface),
        decoration: InputDecoration(
          labelText: label,
          hintText: placeholder,
          labelStyle: TextStyle(fontSize: 11, color: theme.hintColor),
          hintStyle: TextStyle(fontSize: 11, color: theme.hintColor.withOpacity(0.6)),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }

  static Widget _buildField(BuildContext context, TextEditingController controller, String hint) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 40,
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color ?? colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: theme.hintColor.withOpacity(0.6), fontSize: 13),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colorScheme.primary),
          ),
        ),
      ),
    );
  }
}

// Dialog Controller Lifecycle
class _StockInDialogContent extends StatefulWidget {
  final StockInLogic logic;
  final BuildContext parentContext;
  final bool isEditing;
  final StockInModel? stockInToEdit;
  final List<String> supplierList;
  final String selectedSupplier;
  final List<Map<String, dynamic>> availableProducts;

  const _StockInDialogContent({
    required this.logic,
    required this.parentContext,
    required this.isEditing,
    this.stockInToEdit,
    required this.supplierList,
    required this.selectedSupplier,
    required this.availableProducts,
  });

  @override
  State<_StockInDialogContent> createState() => _StockInDialogContentState();
}

class _StockInDialogContentState extends State<_StockInDialogContent> {
  late TextEditingController noteController;
  late String currentSupplier;
  List<StockInFormRow> formRows = [];

  @override
  void initState() {
    super.initState();
    noteController = TextEditingController(text: widget.isEditing ? widget.stockInToEdit!.note : '');
    currentSupplier = widget.selectedSupplier;

    if (widget.isEditing) {
      for (var e in widget.stockInToEdit!.items) {
        formRows.add(StockInFormRow(
          item: StockInItem(
            productName: e.productName,
            quantity: e.quantity,
            costPrice: e.costPrice,
            salePrice: e.salePrice,
            itemTotal: e.itemTotal,
          ),
        ));
      }
    } else {
      formRows.add(StockInFormRow(
        item: StockInItem(
          productName: '',
          quantity: 0,
          costPrice: 0.0,
          salePrice: 0.0,
          itemTotal: 0.0,
        ),
      ));
    }
  }

  @override
  void dispose() {
    for (var row in formRows) {
      row.dispose();
    }
    noteController.dispose();
    super.dispose();
  }

  void _updatePriceIfProductMatches(StockInFormRow row, String name) {
    row.item.productName = name;
    final matchedIndex = widget.availableProducts.indexWhere(
      (p) => p['name'].toString().trim().toLowerCase() == name.trim().toLowerCase(),
    );

    if (matchedIndex != -1) {
      final matched = widget.availableProducts[matchedIndex];
      double cost = (matched['cost_price'] as num?)?.toDouble() ?? 0.0;
      double sale = (matched['sale_price'] as num?)?.toDouble() ?? 0.0;

      row.item.costPrice = cost;
      row.item.salePrice = sale;

      row.costController.text = cost == 0.0 ? '' : cost.toStringAsFixed(0);
      row.saleController.text = sale == 0.0 ? '' : sale.toStringAsFixed(0);
      row.item.itemTotal = row.item.quantity * row.item.costPrice;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    double grandTotal = formRows.fold(0.0, (sum, row) => sum + row.item.itemTotal);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.dialogBackgroundColor,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.isEditing ? "Edit Purchase (Stock In)" : "New Purchase (Stock In)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textTheme.titleLarge?.color ?? colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: Icon(Icons.close, color: theme.hintColor, size: 20),
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
              Divider(color: theme.dividerColor),
              const SizedBox(height: 6),

              // Dynamic Scrollable Body Area
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Supplier Select
                      StockInLogic._buildLabel(context, "Supplier *"),
                      const SizedBox(height: 4),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            dropdownColor: theme.cardColor,
                            value: widget.supplierList.contains(currentSupplier) ? currentSupplier : '-- Select Supplier --',
                            isExpanded: true,
                            items: widget.supplierList.map((String sup) {
                              return DropdownMenuItem<String>(
                                value: sup,
                                child: Text(
                                  sup,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: sup.contains('Select')
                                        ? theme.hintColor
                                        : (textTheme.bodyMedium?.color ?? colorScheme.onSurface),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  currentSupplier = newValue;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Dynamic Item List Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          StockInLogic._buildLabel(context, "Products List"),
                          InkWell(
                            onTap: () {
                              setState(() {
                                formRows.add(StockInFormRow(
                                  item: StockInItem(
                                    productName: '',
                                    quantity: 0,
                                    costPrice: 0.0,
                                    salePrice: 0.0,
                                    itemTotal: 0.0,
                                  ),
                                ));
                              });
                            },
                            child: Row(
                              children: [
                                Icon(Icons.add_circle, color: colorScheme.primary, size: 18),
                                const SizedBox(width: 4),
                                Text(
                                  "Add Item",
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Items List Form
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: formRows.length,
                        itemBuilder: (context, index) {
                          var row = formRows[index];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: SizedBox(
                                        height: 38,
                                        child: RawAutocomplete<String>(
                                          focusNode: row.nameFocusNode,
                                          textEditingController: row.nameController,
                                          optionsBuilder: (TextEditingValue textEditingValue) {
                                            if (textEditingValue.text.isEmpty) {
                                              return const Iterable<String>.empty();
                                            }
                                            return widget.availableProducts
                                                .map((p) => p['name'].toString())
                                                .where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                                          },
                                          onSelected: (String selection) {
                                            setState(() {
                                              _updatePriceIfProductMatches(row, selection);
                                            });
                                          },
                                          fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                                            return TextField(
                                              controller: controller,
                                              focusNode: focusNode,
                                              keyboardType: TextInputType.text,
                                              onChanged: (val) {
                                                setState(() {
                                                  _updatePriceIfProductMatches(row, val);
                                                });
                                              },
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                color: textTheme.bodyMedium?.color ?? colorScheme.onSurface,
                                              ),
                                              decoration: InputDecoration(
                                                hintText: "Product Name",
                                                hintStyle: TextStyle(fontSize: 12, color: theme.hintColor),
                                                isDense: true,
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide: BorderSide(color: theme.dividerColor),
                                                ),
                                                enabledBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide: BorderSide(color: theme.dividerColor),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                  borderSide: BorderSide(color: colorScheme.primary),
                                                ),
                                                suffixIcon: widget.availableProducts.isNotEmpty
                                                    ? PopupMenuButton<Map<String, dynamic>>(
                                                        icon: Icon(Icons.arrow_drop_down, color: theme.hintColor),
                                                        color: theme.cardColor,
                                                        onSelected: (matched) {
                                                          setState(() {
                                                            String selectedName = matched['name'].toString();
                                                            row.nameController.text = selectedName;
                                                            _updatePriceIfProductMatches(row, selectedName);
                                                          });
                                                        },
                                                        itemBuilder: (BuildContext context) {
                                                          return widget.availableProducts.map((p) {
                                                            return PopupMenuItem<Map<String, dynamic>>(
                                                              value: p,
                                                              child: Text(
                                                                p['name'].toString(),
                                                                style: TextStyle(
                                                                  fontSize: 12.5,
                                                                  color: textTheme.bodyMedium?.color ?? colorScheme.onSurface,
                                                                ),
                                                              ),
                                                            );
                                                          }).toList();
                                                        },
                                                      )
                                                    : null,
                                              ),
                                            );
                                          },
                                          optionsViewBuilder: (context, onSelected, options) {
                                            return Align(
                                              alignment: Alignment.topLeft,
                                              child: Material(
                                                elevation: 4.0,
                                                color: theme.cardColor,
                                                borderRadius: BorderRadius.circular(6),
                                                child: Container(
                                                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 260),
                                                  decoration: BoxDecoration(
                                                    color: theme.cardColor,
                                                    borderRadius: BorderRadius.circular(6),
                                                    border: Border.all(color: theme.dividerColor),
                                                  ),
                                                  child: ListView.builder(
                                                    padding: EdgeInsets.zero,
                                                    shrinkWrap: true,
                                                    itemCount: options.length,
                                                    itemBuilder: (BuildContext context, int index) {
                                                      final String option = options.elementAt(index);
                                                      return InkWell(
                                                        onTap: () => onSelected(option),
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                          decoration: BoxDecoration(
                                                            border: Border(bottom: BorderSide(color: theme.dividerColor)),
                                                          ),
                                                          child: Text(
                                                            option,
                                                            style: TextStyle(
                                                              fontSize: 12.5,
                                                              color: textTheme.bodyMedium?.color ?? colorScheme.onSurface,
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                    if (formRows.length > 1)
                                      IconButton(
                                        icon: Icon(Icons.remove_circle_outline, color: colorScheme.error, size: 20),
                                        onPressed: () {
                                          setState(() {
                                            var removedRow = formRows.removeAt(index);
                                            removedRow.dispose();
                                          });
                                        },
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: StockInLogic._buildSmallField(context, "Qty", "0", row.qtyController, row.qtyFocusNode, (val) {
                                        setState(() {
                                          row.item.quantity = int.tryParse(val) ?? 0;
                                          row.item.itemTotal = row.item.quantity * row.item.costPrice;
                                        });
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: StockInLogic._buildSmallField(context, "Cost Price", "0", row.costController, row.costFocusNode, (val) {
                                        setState(() {
                                          row.item.costPrice = double.tryParse(val) ?? 0.0;
                                          row.item.itemTotal = row.item.quantity * row.item.costPrice;
                                        });
                                      }),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: StockInLogic._buildSmallField(context, "Sale Price", "0", row.saleController, row.saleFocusNode, (val) {
                                        setState(() {
                                          row.item.salePrice = double.tryParse(val) ?? 0.0;
                                        });
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    "Subtotal: ${row.item.itemTotal.toStringAsFixed(0)} MMK",
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: colorScheme.primary),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Grand Total Amount:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: textTheme.bodyLarge?.color ?? colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            "${grandTotal.toStringAsFixed(0)} MMK",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      StockInLogic._buildLabel(context, "Note / Invoice No."),
                      const SizedBox(height: 4),
                      StockInLogic._buildField(context, noteController, "Invoice number or remarks..."),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              // Footer Action Buttons
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.dividerColor.withOpacity(0.2),
                        foregroundColor: textTheme.bodyLarge?.color ?? colorScheme.onSurface,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text("Cancel", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        FocusScope.of(context).unfocus();

                        // Validation Check
                        if (currentSupplier.isEmpty || currentSupplier.contains('Select Supplier') || currentSupplier.contains('ရွေးပါ')) {
                          Utils.showTopToast(context, "ကျေးဇူးပြု၍ Supplier ရွေးချယ်ပါ။", isError: true);
                          return;
                        }

                        List<StockInItem> finalItems = formRows.map((r) => r.item).toList();
                        if (finalItems.isEmpty) {
                          Utils.showTopToast(context, "အနည်းဆုံး Product တစ်ခု ထည့်သွင်းပါ။", isError: true);
                          return;
                        }

                        for (var item in finalItems) {
                          if (item.productName.trim().isEmpty) {
                            Utils.showTopToast(context, "ကျေးဇူးပြု၍ Product Name ဖြည့်စွက်ပါ။", isError: true);
                            return;
                          }
                          if (item.quantity <= 0) {
                            Utils.showTopToast(context, "Quantity သည် 0 ထက် ကြီးရပါမည်။", isError: true);
                            return;
                          }
                          if (item.costPrice < 0 || item.salePrice < 0) {
                            Utils.showTopToast(context, "ဈေးနှုန်းများ မှန်ကန်စွာ ဖြည့်သွင်းပါ။", isError: true);
                            return;
                          }
                        }

                        Navigator.of(context).pop();

                        await widget.logic.saveStockIn(
                          widget.parentContext,
                          id: widget.isEditing ? widget.stockInToEdit!.id : null,
                          supplier: currentSupplier,
                          note: noteController.text,
                          items: finalItems,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: Text(widget.isEditing ? "Update" : "Save & Stock In", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
