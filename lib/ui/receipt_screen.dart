// lib/ui/receipt_screen.dart

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/sale_logic.dart';
import '../logic/product_logic.dart';
import '../logic/receipt_logic.dart';
import '../logic/shopinfo_logic.dart';
import '../logic/viplist_logic.dart';
import '../service/printer_setting.dart';
import '../global/utility/utils.dart';
import 'pdf_preview_screen.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isProcessing = false;
  bool _showQuickSettings = true; // Quick Settings Panel ခေါက်/ဖြန့် ရန်

  // ESC/POS Thermal Printing Byte Data များ ထုတ်လုပ်ပေးသည့် Helper Logic
  List<int> _generateThermalReceiptBytes({
    required String shopName,
    required String address,
    required String phone,
    required String invoiceNo,
    required String dateStr,
    required String customerName,
    required String paymentMethod,
    required List<dynamic> cartItems,
    required double subTotal,
    required double discount,
    required double tax,
    required double grandTotal,
    required double receivedCash,
    required double change,
    required PaperSizeOption paperSize,
    required String footerText,
  }) {
    List<int> bytes = [];

    // 1. Initialize Printer (ESC @)
    bytes.addAll([0x1B, 0x40]);

    // 2. Alignment Center (ESC a 1)
    bytes.addAll([0x1B, 0x61, 0x01]);

    // Store Name (Bold / Double Height & Width)
    bytes.addAll([0x1B, 0x21, 0x30]);
    bytes.addAll(shopName.codeUnits);
    bytes.add(0x0A); // Line feed

    // Reset Format
    bytes.addAll([0x1B, 0x21, 0x00]);

    if (address.isNotEmpty) {
      bytes.addAll(address.codeUnits);
      bytes.add(0x0A);
    }
    if (phone.isNotEmpty) {
      bytes.addAll("Ph: $phone".codeUnits);
      bytes.add(0x0A);
    }

    // Divider Line
    final int lineLength = (paperSize == PaperSizeOption.mm80) ? 48 : 32;
    final String divider = "-" * lineLength;
    bytes.addAll(divider.codeUnits);
    bytes.add(0x0A);

    // Alignment Left (ESC a 0)
    bytes.addAll([0x1B, 0x61, 0x00]);
    bytes.addAll("Receipt: $invoiceNo\n".codeUnits);
    bytes.addAll("Date: $dateStr\n".codeUnits);
    if (customerName.isNotEmpty) {
      bytes.addAll("Customer: $customerName\n".codeUnits);
    }
    bytes.addAll("Payment: $paymentMethod\n".codeUnits);

    bytes.addAll(divider.codeUnits);
    bytes.add(0x0A);

    // Items
    for (var item in cartItems) {
      String name = item.product.name;
      String qtyPrice = "${item.quantity} x ${item.unitPrice.toStringAsFixed(0)}";
      String total = "${item.itemTotal.toStringAsFixed(0)} Ks";

      bytes.addAll("$name\n".codeUnits);
      
      // Spaces formatting
      int spaceCount = lineLength - qtyPrice.length - total.length;
      if (spaceCount < 1) spaceCount = 1;
      String line = qtyPrice + (" " * spaceCount) + total;
      bytes.addAll("$line\n".codeUnits);
    }

    bytes.addAll(divider.codeUnits);
    bytes.add(0x0A);

    // Totals
    _addTotalRow(bytes, "Sub Total:", "${subTotal.toStringAsFixed(0)} Ks", lineLength);
    if (discount > 0) {
      _addTotalRow(bytes, "Discount:", "-${discount.toStringAsFixed(0)} Ks", lineLength);
    }
    if (tax > 0) {
      _addTotalRow(bytes, "Tax:", "+${tax.toStringAsFixed(0)} Ks", lineLength);
    }

    bytes.addAll(divider.codeUnits);
    bytes.add(0x0A);

    // Grand Total (Bold)
    bytes.addAll([0x1B, 0x45, 0x01]); // Bold ON
    _addTotalRow(bytes, "Grand Total:", "${grandTotal.toStringAsFixed(0)} Ks", lineLength);
    bytes.addAll([0x1B, 0x45, 0x00]); // Bold OFF

    if (paymentMethod == 'Cash') {
      _addTotalRow(bytes, "Received Cash:", "${receivedCash.toStringAsFixed(0)} Ks", lineLength);
      _addTotalRow(bytes, "Change:", "${change.toStringAsFixed(0)} Ks", lineLength);
    }

    bytes.addAll(divider.codeUnits);
    bytes.add(0x0A);

    // Alignment Center
    bytes.addAll([0x1B, 0x61, 0x01]);
    bytes.addAll("$footerText\n\n".codeUnits);

    // Paper Cut (GS V 66 0)
    bytes.addAll([0x1D, 0x56, 0x42, 0x00]);

    return bytes;
  }

  void _addTotalRow(List<int> bytes, String title, String val, int lineLength) {
    int spaceCount = lineLength - title.length - val.length;
    if (spaceCount < 1) spaceCount = 1;
    String row = title + (" " * spaceCount) + val;
    bytes.addAll("$row\n".codeUnits);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final saleLogic = Provider.of<SaleLogic>(context);
    final productLogic = Provider.of<ProductLogic>(context, listen: false);
    final vipLogic = Provider.of<VipListLogic>(context, listen: false);
    final receiptLogic = Provider.of<ReceiptLogic>(context);
    final shopInfoLogic = Provider.of<ShopInfoLogic>(context);
    final printerService = Provider.of<PrinterSettingService>(context);

    final cartItems = saleLogic.cartItems;
    final String receiptNo = "#INV${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}";
    final DateTime now = DateTime.now();
    final String dateStr = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute.toString().padLeft(2, '0')}";

    final bool isPremium = receiptLogic.isPremiumUser;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            children: [
              // 1. Custom Header
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
                      "Receipt Preview",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
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
                      icon: Icon(
                        isPremium ? Icons.workspace_premium : Icons.workspace_premium_outlined,
                        color: isPremium ? Colors.amber : theme.hintColor,
                        size: 20,
                      ),
                      tooltip: isPremium ? "Premium Active" : "Free Plan",
                      onPressed: () {
                        receiptLogic.setPremiumUser(!isPremium);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(receiptLogic.isPremiumUser ? "Premium Plan သို့ ပြောင်းလိုက်ပါပြီ" : "Free Plan သို့ ပြောင်းလိုက်ပါပြီ"),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. Receipt Slip Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Store Info Section
                            Center(
                              child: Column(
                                children: [
                                  if (isPremium && receiptLogic.showShopLogo && shopInfoLogic.logoPath.isNotEmpty) ...[
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        shape: shopInfoLogic.logoShape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                                        borderRadius: shopInfoLogic.logoShape == 'rounded' ? BorderRadius.circular(8) : null,
                                        image: DecorationImage(
                                          image: FileImage(File(shopInfoLogic.logoPath)),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                  ],

                                  Text(
                                    shopInfoLogic.nameController.text.trim().isNotEmpty
                                        ? shopInfoLogic.nameController.text.trim()
                                        : "POS STORE",
                                    style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                                  ),

                                  if (isPremium && shopInfoLogic.headerNoteController.text.trim().isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      shopInfoLogic.headerNoteController.text.trim(),
                                      style: const TextStyle(color: Colors.black87, fontSize: 11, fontStyle: FontStyle.italic),
                                    ),
                                  ],

                                  if (isPremium) ...[
                                    if (receiptLogic.showShopAddress && shopInfoLogic.addressController.text.trim().isNotEmpty)
                                      Text(shopInfoLogic.addressController.text.trim(), style: const TextStyle(color: Colors.black87, fontSize: 11)),
                                    if (receiptLogic.showShopPhone && shopInfoLogic.phoneController.text.trim().isNotEmpty)
                                      Text("Ph: ${shopInfoLogic.phoneController.text.trim()}", style: const TextStyle(color: Colors.black87, fontSize: 11)),
                                    if (shopInfoLogic.taxIdController.text.trim().isNotEmpty)
                                      Text("Tax ID: ${shopInfoLogic.taxIdController.text.trim()}", style: const TextStyle(color: Colors.black87, fontSize: 10)),
                                  ],
                                ],
                              ),
                            ),
                            const Divider(height: 20, color: Colors.black26, thickness: 1),

                            // Receipt Metadata
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Receipt: $receiptNo", style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold)),
                                Text(dateStr, style: const TextStyle(color: Colors.black87, fontSize: 11)),
                              ],
                            ),
                            if (receiptLogic.showCustomerInfo) ...[
                              const SizedBox(height: 2),
                              Text("Customer: ${saleLogic.customerDisplayName}", style: const TextStyle(color: Colors.black87, fontSize: 11)),
                            ],
                            const SizedBox(height: 4),
                            Text("Payment: ${saleLogic.selectedPaymentMethod}", style: const TextStyle(color: Colors.black87, fontSize: 11)),
                            const SizedBox(height: 10),

                            // Table Header
                            Row(
                              children: const [
                                Expanded(flex: 4, child: Text("Item", style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text("Qty", textAlign: TextAlign.center, style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 2, child: Text("Price", textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                                Expanded(flex: 3, child: Text("Total", textAlign: TextAlign.right, style: TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                              ],
                            ),
                            const Divider(height: 12, color: Colors.black26),

                            // Item List
                            ...cartItems.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: [
                                    Expanded(flex: 4, child: Text(item.product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 11))),
                                    Expanded(flex: 2, child: Text("${item.quantity}", textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontSize: 11))),
                                    Expanded(flex: 2, child: Text(item.unitPrice.toStringAsFixed(0), textAlign: TextAlign.right, style: const TextStyle(color: Colors.black, fontSize: 11))),
                                    Expanded(flex: 3, child: Text("${item.itemTotal.toStringAsFixed(0)} Ks", textAlign: TextAlign.right, style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold))),
                                  ],
                                ),
                              );
                            }),

                            const Divider(height: 16, color: Colors.black26),

                            // Calculations Section
                            _buildReceiptRow("Sub Total", "${saleLogic.subTotal.toStringAsFixed(0)} Ks"),
                            if (receiptLogic.showDiscount && saleLogic.overallDiscount > 0)
                              _buildReceiptRow("Discount", "-${saleLogic.overallDiscount.toStringAsFixed(0)} Ks"),
                            if (receiptLogic.showTax && saleLogic.taxAmount > 0)
                              _buildReceiptRow("Tax (${saleLogic.taxRate.toStringAsFixed(0)}%)", "+${saleLogic.taxAmount.toStringAsFixed(0)} Ks"),

                            const Divider(height: 12, color: Colors.black26),
                            _buildReceiptRow("Grand Total", "${saleLogic.grandTotal.toStringAsFixed(0)} Ks", isBold: true, fontSize: 14),

                            if (saleLogic.selectedPaymentMethod == 'Cash') ...[
                              const SizedBox(height: 4),
                              _buildReceiptRow("Received Cash", "${saleLogic.receivedCash.toStringAsFixed(0)} Ks"),
                              _buildReceiptRow("Change", "${saleLogic.changeAmount.toStringAsFixed(0)} Ks"),
                            ],

                            const SizedBox(height: 16),

                            // Footer Note
                            Center(
                              child: Text(
                                isPremium
                                    ? (shopInfoLogic.footerNoteController.text.trim().isNotEmpty
                                        ? shopInfoLogic.footerNoteController.text.trim()
                                        : receiptLogic.customFooterText)
                                    : "ကျေးဇူးတင်ပါသည်!",
                                style: const TextStyle(color: Colors.black87, fontSize: 11, fontStyle: FontStyle.italic),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),

                      if (!isPremium)
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.grey.shade200,
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.bolt, size: 12, color: Colors.grey),
                                SizedBox(width: 4),
                                Text(
                                  "Powered by Smart POS App (Free Version)",
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. Printer & Paper Quick Settings ONLY
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    InkWell(
                      onTap: () => setState(() => _showQuickSettings = !_showQuickSettings),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.print, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Text(
                                  "Printer & Paper Quick Settings",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                                ),
                              ],
                            ),
                            Icon(
                              _showQuickSettings ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                              size: 20,
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_showQuickSettings) ...[
                      Divider(height: 1, color: theme.dividerColor),
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Paper Size Choice Chips
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildPaperSizeChip("58mm", PaperSizeOption.mm58, printerService),
                                  const SizedBox(width: 6),
                                  _buildPaperSizeChip("80mm", PaperSizeOption.mm80, printerService),
                                  const SizedBox(width: 6),
                                  _buildPaperSizeChip("A5 Invoice", PaperSizeOption.a5, printerService),
                                  const SizedBox(width: 6),
                                  _buildPaperSizeChip("A4 Invoice", PaperSizeOption.a4, printerService),
                                ],
                              ),
                            ),
                            const SizedBox(height: 10),
                            Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
                            const SizedBox(height: 8),

                            // Printer Device Select / Change Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.print_sharp,
                                        size: 16,
                                        color: printerService.selectedPrinter != null ? Colors.green : Colors.grey,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          printerService.selectedPrinter?.name ?? "No Printer Selected",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: colorScheme.onSurface),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                InkWell(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/printer_setup');
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    child: Row(
                                      children: [
                                        Text("Change", style: TextStyle(fontSize: 12, color: colorScheme.primary, fontWeight: FontWeight.bold)),
                                        Icon(Icons.arrow_forward_ios, size: 10, color: colorScheme.primary),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 4. Action Buttons (Print & Complete)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: colorScheme.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: Icon(Icons.print, color: colorScheme.primary, size: 20),
                      label: Text("Print Receipt", style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold)),
                      onPressed: () async {
                        final selectedPaperSize = printerService.selectedPrinter?.paperSize ?? PaperSizeOption.mm58;

                        if (selectedPaperSize == PaperSizeOption.a4 || selectedPaperSize == PaperSizeOption.a5) {
                          // Logo Bytes ယူခြင်း
                          Uint8List? logoBytes;
                          if (shopInfoLogic.logoPath.isNotEmpty) {
                            final logoFile = File(shopInfoLogic.logoPath);
                            if (await logoFile.exists()) {
                              logoBytes = await logoFile.readAsBytes();
                            }
                          }

                          // PDF Preview Screen သို့ လမ်းကြောင်းပြောင်းရန်
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PdfPreviewScreen(
                                  paperSizeOption: selectedPaperSize,
                                  storeName: shopInfoLogic.nameController.text.trim().isNotEmpty
                                      ? shopInfoLogic.nameController.text.trim()
                                      : "POS STORE",
                                  address: shopInfoLogic.addressController.text.trim(),
                                  phone: shopInfoLogic.phoneController.text.trim(),
                                  invoiceNo: receiptNo,
                                  items: cartItems.map((e) => {
                                    'name': e.product.name,
                                    'qty': e.quantity,
                                    'price': e.unitPrice,
                                  }).toList(),
                                  totalAmount: saleLogic.subTotal,
                                  discount: saleLogic.overallDiscount,
                                  netAmount: saleLogic.grandTotal,
                                  storeLogoBytes: logoBytes,
                                ),
                              ),
                            );
                          }
                        } else {
                          // Thermal Receipt Printing Logic (58mm / 80mm)
                          if (printerService.selectedPrinter == null) {
                            Utils.showTopToast(context, "ကျေးဇူးပြု၍ Printer တစ်ခု အရင်ရွေးချယ်ပေးပါ");
                            Navigator.pushNamed(context, '/printer_setup');
                            return;
                          }

                          final footerText = isPremium
                              ? (shopInfoLogic.footerNoteController.text.trim().isNotEmpty
                                  ? shopInfoLogic.footerNoteController.text.trim()
                                  : receiptLogic.customFooterText)
                              : "ကျေးဇူးတင်ပါသည်!";

                          List<int> bytes = _generateThermalReceiptBytes(
                            shopName: shopInfoLogic.nameController.text.trim().isNotEmpty ? shopInfoLogic.nameController.text.trim() : "POS STORE",
                            address: isPremium && receiptLogic.showShopAddress ? shopInfoLogic.addressController.text.trim() : "",
                            phone: isPremium && receiptLogic.showShopPhone ? shopInfoLogic.phoneController.text.trim() : "",
                            invoiceNo: receiptNo,
                            dateStr: dateStr,
                            customerName: receiptLogic.showCustomerInfo ? saleLogic.customerDisplayName : "",
                            paymentMethod: saleLogic.selectedPaymentMethod,
                            cartItems: cartItems,
                            subTotal: saleLogic.subTotal,
                            discount: receiptLogic.showDiscount ? saleLogic.overallDiscount : 0,
                            tax: receiptLogic.showTax ? saleLogic.taxAmount : 0,
                            grandTotal: saleLogic.grandTotal,
                            receivedCash: saleLogic.receivedCash,
                            change: saleLogic.changeAmount,
                            paperSize: selectedPaperSize,
                            footerText: footerText,
                          );

                          bool success = await printerService.printBytes(bytes);

                          if (mounted) {
                            if (success) {
                              Utils.showTopToast(context, "Receipt ထုတ်ယူခြင်း အောင်မြင်ပါသည်");
                            } else {
                              Utils.showTopToast(context, "Printer သို့ အချက်အလက် ပို့ရန် မအောင်မြင်ပါ");
                            }
                          }
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: _isProcessing
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.check_circle_outline, size: 20),
                      label: Text(_isProcessing ? "သိမ်းနေသည်..." : "ပြီးပြီ (Complete)", style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              setState(() {
                                _isProcessing = true;
                              });

                              bool success = await saleLogic.processCheckout(context, productLogic, vipLogic);

                              setState(() {
                                _isProcessing = false;
                              });

                              if (success && mounted) {
                                Navigator.popUntil(context, (route) => route.isFirst);
                              }
                            },
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

  // Paper Size ChoiceChip Helper Widget
  Widget _buildPaperSizeChip(String label, PaperSizeOption option, PrinterSettingService printerService) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentPaperSize = printerService.selectedPrinter?.paperSize ?? PaperSizeOption.mm58;
    final isSelected = currentPaperSize == option;

    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isSelected ? Colors.white : colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedColor: colorScheme.primary,
      backgroundColor: theme.cardColor,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      onSelected: (selected) {
        if (selected) {
          printerService.setPaperSize(option);
        }
      },
    );
  }

  Widget _buildReceiptRow(String title, String value, {bool isBold = false, double fontSize = 11}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: Colors.black, fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}
