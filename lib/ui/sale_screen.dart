import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/sale_logic.dart';
import '../logic/product_logic.dart';
import '../logic/viplist_logic.dart';
import '../ui/receipt_screen.dart';
import '../service/camera_barcode.dart';
import '../global/utility/utils.dart'; // Toast Alert ပြသရန် အသုံးပြုထားပါသည်

class SaleScreen extends StatefulWidget {
  const SaleScreen({super.key});

  @override
  State<SaleScreen> createState() => _SaleScreenState();
}

class _SaleScreenState extends State<SaleScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _cashController = TextEditingController();

  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductLogic>(context, listen: false).fetchProducts();
      Provider.of<VipListLogic>(context, listen: false).fetchVipMembers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _cashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final productLogic = Provider.of<ProductLogic>(context);
    final saleLogic = Provider.of<SaleLogic>(context);
    final vipLogic = Provider.of<VipListLogic>(context);

    // Search filter
    final filteredProducts = productLogic.products.where((p) {
      final query = _searchQuery.toLowerCase();
      final nameMatches = p.name.toLowerCase().contains(query);
      final codeMatches = p.productCode.toLowerCase().contains(query);
      final barcodeMatches = p.barcode.toLowerCase().contains(query);
      return nameMatches || codeMatches || barcodeMatches;
    }).toList();

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
                        "Sale",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ) ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.pause_circle_outline, color: colorScheme.primary, size: 28),
                        onPressed: () => _showHoldOrdersDialog(context, saleLogic),
                      ),
                      if (saleLogic.heldOrdersCount > 0)
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                            child: Text(
                              '${saleLogic.heldOrdersCount}',
                              style: TextStyle(color: colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 2. Search Bar (Camera Barcode Scanner Integrated)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
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
                child: Row(
                  children: [
                    Icon(Icons.search, color: theme.hintColor, size: 22),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: textTheme.bodyMedium,
                        decoration: InputDecoration(
                          hintText: "Search product name or barcode...",
                          hintStyle: TextStyle(color: theme.hintColor, fontSize: 13),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.camera_alt, color: colorScheme.primary, size: 22),
                      onPressed: () {
                        CameraBarcodeScanner.showScanner(
                          context,
                          isContinuous: true,
                          onScanCompleted: (scannedCode) {
                            // 1. စကန်ဖတ်ရရှိလာသော Barcode/Code ဖြင့် Product ကို ရှာဖွေမည်
                            final matchedProduct = productLogic.products.firstWhere(
                              (p) => p.barcode == scannedCode || p.productCode == scannedCode,
                              orElse: () => ProductModel.empty(),
                            );

                            // 2. ကုန်ပစ္စည်းရှိပါက Cart ထဲ တိုက်ရိုက်ထည့်မည်
                            if (matchedProduct.id.isNotEmpty) {
                              saleLogic.addToCart(matchedProduct, context);
                            } else {
                              Utils.showTopToast(
                                context,
                                "ကုန်ပစ္စည်း ရှာမတွေ့ပါ: $scannedCode",
                                isError: true,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. Product List Header
              Text(
                "Product List",
                style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              // 4. Product Cards Grid
              SizedBox(
                height: 125,
                child: filteredProducts.isEmpty
                    ? Center(child: Text("No products found", style: TextStyle(color: theme.hintColor)))
                    : GridView.builder(
                        scrollDirection: Axis.horizontal,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.58,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return _buildHorizontalProductCard(product, saleLogic);
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // 5. Selected Items Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Selected Items",
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => saleLogic.holdOrder(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.withOpacity(0.4)),
                          ),
                          child: const Text("Hold Order", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      InkWell(
                        onTap: () {
                          saleLogic.clearCart();
                          _discountController.clear();
                          _taxController.clear();
                          _cashController.clear();
                        },
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 18, color: colorScheme.error),
                            const SizedBox(width: 2),
                            Text("Clear", style: TextStyle(color: colorScheme.error, fontWeight: FontWeight.bold, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // 6. Cart Table Layout (Fixed Structure)
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                      decoration: BoxDecoration(
                        color: theme.dividerColor.withOpacity(0.08),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text("No.", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text("Name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text("Price", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Center(child: Text("Qty", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor))),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text("Total", textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: theme.hintColor)),
                          ),
                        ],
                      ),
                    ),
                    saleLogic.cartItems.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Center(child: Text("Cart ထဲတွင် ပစ္စည်းမရှိပါ", style: TextStyle(color: theme.hintColor, fontSize: 12))),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: saleLogic.cartItems.length,
                            separatorBuilder: (context, index) => Divider(height: 1, color: theme.dividerColor),
                            itemBuilder: (context, index) {
                              final item = saleLogic.cartItems[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: Text("${index + 1}", style: textTheme.bodySmall?.copyWith(fontSize: 11)),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        item.product.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                item.unitPrice.toStringAsFixed(0),
                                                style: textTheme.bodySmall?.copyWith(fontSize: 11),
                                              ),
                                            ),
                                          ),
                                          if (item.product.discountPrice > 0)
                                            GestureDetector(
                                              onTap: () => saleLogic.toggleItemDiscount(index),
                                              child: Container(
                                                margin: const EdgeInsets.only(left: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: item.isDiscountApplied ? Colors.green : theme.dividerColor,
                                                  borderRadius: BorderRadius.circular(3),
                                                ),
                                                child: Text(
                                                  "Dis",
                                                  style: TextStyle(
                                                    color: item.isDiscountApplied ? Colors.white : theme.textTheme.bodySmall?.color,
                                                    fontSize: 8,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          InkWell(
                                            onTap: () => saleLogic.updateQuantity(index, -1, context),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(3)),
                                              child: const Text("-", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text("${item.quantity}", style: textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.bold)),
                                          ),
                                          InkWell(
                                            onTap: () => saleLogic.updateQuantity(index, 1, context),
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(border: Border.all(color: theme.dividerColor), borderRadius: BorderRadius.circular(3)),
                                              child: const Text("+", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          "${item.itemTotal.toStringAsFixed(0)} Ks",
                                          textAlign: TextAlign.right,
                                          style: textTheme.bodySmall?.copyWith(fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 7. VIP / Customer Selector (Dynamic Integration)
              InkWell(
                onTap: () => _showSelectVipDialog(context, saleLogic, vipLogic),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            saleLogic.selectedVipMember == null ? Icons.person_outline : Icons.workspace_premium,
                            color: saleLogic.selectedVipMember == null ? theme.hintColor : colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            saleLogic.customerDisplayName,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: saleLogic.selectedVipMember == null ? theme.hintColor : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (saleLogic.selectedVipMember != null)
                            GestureDetector(
                              onTap: () {
                                saleLogic.selectVipMember(null, vipLogic);
                                _discountController.clear();
                              },
                              child: const Padding(
                                padding: EdgeInsets.only(right: 8.0),
                                child: Icon(Icons.cancel, size: 18, color: Colors.grey),
                              ),
                            ),
                          Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 8. Discount & Tax Input Fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Discount (Ks)", style: textTheme.bodyMedium?.copyWith(fontSize: 13)),
                  SizedBox(
                    width: 90,
                    height: 34,
                    child: TextField(
                      controller: _discountController..text = saleLogic.overallDiscount > 0 ? saleLogic.overallDiscount.toStringAsFixed(0) : "",
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0",
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (val) {
                        double disc = double.tryParse(val) ?? 0.0;
                        saleLogic.setOverallDiscount(disc);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text("Tax (%)", style: textTheme.bodyMedium?.copyWith(fontSize: 13)),
                      if (saleLogic.taxAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            "(${saleLogic.taxAmount.toStringAsFixed(0)} Ks)",
                            style: TextStyle(fontSize: 11, color: theme.hintColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    width: 90,
                    height: 34,
                    child: TextField(
                      controller: _taxController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: "0",
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onChanged: (val) {
                        double tax = double.tryParse(val) ?? 0.0;
                        saleLogic.setTaxRate(tax);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Grand Total", style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                  Text("${saleLogic.grandTotal.toStringAsFixed(0)} Ks", style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary)),
                ],
              ),
              const SizedBox(height: 14),

              // 9. Payment Method
              Text("Payment Method", style: textTheme.bodyMedium?.copyWith(fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                children: ["Cash", "KPay", "WavePay", "AYApay"].map((method) {
                  bool isSelected = saleLogic.selectedPaymentMethod == method;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => saleLogic.setPaymentMethod(method),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? colorScheme.primary : theme.cardColor,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isSelected ? colorScheme.primary : theme.dividerColor),
                        ),
                        child: Center(
                          child: Text(
                            method,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? colorScheme.onPrimary : textTheme.bodyMedium?.color,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),

              // 10. Cash Shortcuts & Cash Field
              if (saleLogic.selectedPaymentMethod == 'Cash') ...[
                Row(
                  children: [
                    _buildQuickCashBtn("Exact", saleLogic.grandTotal, saleLogic, theme),
                    _buildQuickCashBtn("1,000", 1000, saleLogic, theme),
                    _buildQuickCashBtn("5,000", 5000, saleLogic, theme),
                    _buildQuickCashBtn("10,000", 10000, saleLogic, theme),
                    _buildQuickCashBtn("20,000", 20000, saleLogic, theme),
                  ],
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Row(
                    children: [
                      Text("Cash", style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _cashController,
                          keyboardType: TextInputType.number,
                          style: textTheme.bodyLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0",
                          ),
                          onChanged: (val) {
                            double cash = double.tryParse(val) ?? 0.0;
                            saleLogic.setReceivedCash(cash);
                          },
                        ),
                      ),
                      Text("Ks", style: textTheme.bodyMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Change (ပြန်အမ်းငွေ)", style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                      Text(
                        "${saleLogic.changeAmount.toStringAsFixed(0)} Ks",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // 11. Checkout Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: saleLogic.cartItems.isEmpty
                      ? null
                      : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReceiptScreen()),
                          );
                        },
                  child: const Text("ငွေရှင်းမည်", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // VIP Member Selector Pop-up Dialog (Refactored to Premium POS Look & Feel)
  void _showSelectVipDialog(BuildContext context, SaleLogic saleLogic, VipListLogic vipLogic) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    String filterQuery = "";

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final membersList = vipLogic.vipMembers.where((m) {
              final q = filterQuery.toLowerCase();
              return m.name.toLowerCase().contains(q) || m.phone.contains(q);
            }).toList();

            return Dialog(
              backgroundColor: theme.cardColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Centered Header Design
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.workspace_premium, size: 20, color: primaryColor),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "VIP Member ရွေးချယ်ရန်",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Compact Search Bar
                    Container(
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                      ),
                      child: TextField(
                        style: const TextStyle(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: "အမည် သို့မဟုတ် ဖုန်းနံပါတ် ရှာပါ...",
                          hintStyle: TextStyle(color: theme.hintColor, fontSize: 12),
                          prefixIcon: Icon(Icons.search, size: 18, color: theme.hintColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            filterQuery = val;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Compact Customer List
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.45,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: membersList.length + 1,
                        separatorBuilder: (context, index) => const SizedBox(height: 6),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            bool isSelected = saleLogic.selectedVipMember == null;
                            return InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () {
                                saleLogic.selectVipMember(null, vipLogic);
                                Navigator.pop(context);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? primaryColor.withOpacity(0.08) : theme.cardColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? primaryColor : theme.dividerColor.withOpacity(0.3),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: Colors.grey.shade200,
                                      child: const Icon(Icons.person, size: 16, color: Colors.grey),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        "Normal Customer",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_circle, size: 16, color: primaryColor),
                                  ],
                                ),
                              ),
                            );
                          }

                          final member = membersList[index - 1];
                          final discPercent = vipLogic.getDiscountPercentageForTier(member.tier);
                          bool isSelected = saleLogic.selectedVipMember?.id == member.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () {
                              saleLogic.selectVipMember(member, vipLogic);
                              Navigator.pop(context);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryColor.withOpacity(0.08) : theme.cardColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected ? primaryColor : theme.dividerColor.withOpacity(0.3),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: primaryColor.withOpacity(0.12),
                                    child: Text(
                                      member.name.isNotEmpty ? member.name[0].toUpperCase() : "V",
                                      style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                member.name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: isSelected ? primaryColor : theme.textTheme.bodyMedium?.color,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: primaryColor.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                member.tier,
                                                style: TextStyle(
                                                  color: primaryColor,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "${member.phone}  •  ${discPercent.toInt()}% Off",
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme.hintColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(Icons.check_circle, size: 16, color: primaryColor),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
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

  Widget _buildQuickCashBtn(String label, double amount, SaleLogic saleLogic, ThemeData theme) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          saleLogic.setReceivedCash(amount);
          String textVal = amount.toStringAsFixed(0);
          _cashController.text = textVal;
          _cashController.selection = TextSelection.fromPosition(TextPosition(offset: textVal.length));
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Center(
            child: Text(label, style: theme.textTheme.bodySmall?.copyWith(fontSize: 10, fontWeight: FontWeight.w500)),
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalProductCard(ProductModel product, SaleLogic saleLogic) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.dividerColor),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => saleLogic.addToCart(product, context),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    product.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "${product.salePrice.toStringAsFixed(0)} Ks",
                    style: TextStyle(color: colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            if (product.discountPrice > 0)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomLeft: Radius.circular(6),
                    ),
                  ),
                  child: Text(
                    "Dis",
                    style: TextStyle(color: colorScheme.onError, fontSize: 8, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showHoldOrdersDialog(BuildContext context, SaleLogic saleLogic) {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Held Orders", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: Icon(Icons.close, size: 20, color: theme.iconTheme.color),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: saleLogic.heldOrders.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: Text("Hold လုပ်ထားသော Order မရှိပါ", style: TextStyle(color: theme.hintColor))),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: saleLogic.heldOrders.length,
                    itemBuilder: (context, index) {
                      final order = saleLogic.heldOrders[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: theme.scaffoldBackgroundColor,
                        child: ListTile(
                          title: Text("${order.id} (${order.selectedVipMember?.name ?? 'Normal'})", style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: Text("Items: ${order.items.length} | Total: ${order.total.toStringAsFixed(0)} Ks", style: theme.textTheme.bodySmall?.copyWith(fontSize: 11)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.restore, color: theme.colorScheme.primary, size: 20),
                                onPressed: () {
                                  saleLogic.restoreHeldOrder(index);
                                  _discountController.text = saleLogic.overallDiscount > 0 ? saleLogic.overallDiscount.toStringAsFixed(0) : "";
                                  _taxController.text = saleLogic.taxRate > 0 ? saleLogic.taxRate.toStringAsFixed(0) : "";
                                  Navigator.pop(context);
                                },
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: theme.colorScheme.error, size: 20),
                                onPressed: () {
                                  saleLogic.deleteHeldOrder(index);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        );
      },
    );
  }
}
