// lib/ui/pdf_preview_screen.dart

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import '../service/pdf_printer.dart';
import '../service/printer_setting.dart';

class PdfPreviewScreen extends StatefulWidget {
  final PaperSizeOption paperSizeOption;
  final String storeName;
  final String address;
  final String phone;
  final String invoiceNo;
  final List<Map<String, dynamic>> items;
  final double totalAmount;
  final double discount;
  final double netAmount;
  final Uint8List? storeLogoBytes;

  const PdfPreviewScreen({
    Key? key,
    required this.paperSizeOption,
    required this.storeName,
    required this.address,
    required this.phone,
    required this.invoiceNo,
    required this.items,
    required this.totalAmount,
    required this.discount,
    required this.netAmount,
    this.storeLogoBytes,
  }) : super(key: key);

  @override
  State<PdfPreviewScreen> createState() => _PdfPreviewScreenState();
}

class _PdfPreviewScreenState extends State<PdfPreviewScreen> {
  String get _paperSizeLabel =>
      widget.paperSizeOption == PaperSizeOption.a5 ? "A5" : "A4";

  // PDF Document Byte Data ထုတ်ပေးသည့် Helper Function
  Future<Uint8List> _buildPdfBytes() {
    return PdfPrinterService.generatePdfDocument(
      paperSizeOption: widget.paperSizeOption,
      storeName: widget.storeName,
      address: widget.address,
      phone: widget.phone,
      invoiceNo: widget.invoiceNo,
      items: widget.items,
      totalAmount: widget.totalAmount,
      discount: widget.discount,
      netAmount: widget.netAmount,
      storeLogoBytes: widget.storeLogoBytes,
    );
  }

  // Storage Access Framework (SAF) ဖြင့် PDF ကို တိုက်ရိုက် Save သည့် Function
  Future<void> _savePdfToDevice() async {
    try {
      final bytes = await _buildPdfBytes();
      final fileName = 'Invoice_${widget.invoiceNo}.pdf';

      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'PDF ဖိုင်သိမ်းဆည်းမည့်နေရာ ရွေးပါ',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        bytes: bytes,
      );

      if (outputFile != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("PDF ဖိုင် အောင်မြင်စွာ သိမ်းဆည်းပြီးပါပြီ။"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Save မအောင်မြင်ပါ: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Header Area
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button
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

                  // Title
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
                    child: Text(
                      "$_paperSizeLabel Invoice Preview",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(width: 38),
                ],
              ),
            ),

            const Divider(height: 1),

            // 2. PDF Preview Area
            Expanded(
              child: PdfPreview(
                build: (format) => _buildPdfBytes(),
                allowPrinting: false, // Default Native Printer Icon ကို Hide လုပ်ထားပါသည်
                allowSharing: true,   // Share Icon လေးကို မူလအတိုင်း ပြထားပါသည်
                canChangePageFormat: false,
                canChangeOrientation: false,
                canDebug: false,
                pdfFileName: 'Invoice_${widget.invoiceNo}.pdf',
                loadingWidget: Center(
                  child: CircularProgressIndicator(color: colorScheme.primary),
                ),
                // Action Bar တွင် Custom Download Icon ထည့်သွင်းခြင်း
                actions: [
                  PdfPreviewAction(
                    icon: const Icon(Icons.download_rounded),
                    onPressed: (context, build, page) async {
                      await _savePdfToDevice();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
