// lib/service/pdf_printer.dart

import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'printer_setting.dart';

class PdfPrinterService {
  // A4 သို့မဟုတ် A5 PDF Document ဖန်တီးပေးခြင်း
  static Future<Uint8List> generatePdfDocument({
    required PaperSizeOption paperSizeOption,
    required String storeName,
    required String address,
    required String phone,
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double discount,
    required double netAmount,
    Uint8List? storeLogoBytes, // Shop Logo image bytes (optional)
  }) async {
    final pdf = pw.Document();

    final PdfPageFormat format = paperSizeOption == PaperSizeOption.a5
        ? PdfPageFormat.a5
        : PdfPageFormat.a4;

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. Header Section (Logo, Shop Info & Invoice Header)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (storeLogoBytes != null) ...[
                          pw.Container(
                            height: 45,
                            child: pw.Image(pw.MemoryImage(storeLogoBytes)),
                          ),
                          pw.SizedBox(height: 6),
                        ],
                        pw.Text(
                          storeName,
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.blueGrey900,
                          ),
                        ),
                        if (address.isNotEmpty)
                          pw.Text(
                            address,
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                        if (phone.isNotEmpty)
                          pw.Text(
                            'Ph: $phone',
                            style: const pw.TextStyle(
                              fontSize: 9,
                              color: PdfColors.grey700,
                            ),
                          ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'INVOICE',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 6),
                      pw.Text(
                        'Invoice No: $invoiceNo',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Date: ${DateTime.now().toString().substring(0, 10)}',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1, color: PdfColors.blueGrey200),
              pw.SizedBox(height: 12),

              // 2. Items Table Section (Excel-Style Grid)
              pw.Table.fromTextArray(
                headers: ['No.', 'Item Name', 'Qty', 'Price', 'Total'],
                data: List.generate(items.length, (index) {
                  final item = items[index];
                  double total = (item['qty'] as num) * (item['price'] as num).toDouble();
                  return [
                    '${index + 1}',
                    item['name'].toString(),
                    item['qty'].toString(),
                    item['price'].toStringAsFixed(0),
                    total.toStringAsFixed(0),
                  ];
                }),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 10,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.centerLeft,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(
                  color: PdfColors.grey400,
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FixedColumnWidth(30),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FixedColumnWidth(40),
                  3: const pw.FixedColumnWidth(65),
                  4: const pw.FixedColumnWidth(75),
                },
              ),
              pw.SizedBox(height: 12),

              // 3. Calculation Summary Section
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 180,
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                      borderRadius: pw.BorderRadius.circular(4),
                      color: PdfColors.grey50,
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Sub Total:', style: const pw.TextStyle(fontSize: 9)),
                            pw.Text(totalAmount.toStringAsFixed(0), style: const pw.TextStyle(fontSize: 9)),
                          ],
                        ),
                        if (discount > 0) ...[
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Discount:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
                              pw.Text('-${discount.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700)),
                            ],
                          ),
                        ],
                        pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Net Total:',
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                            ),
                            pw.Text(
                              netAmount.toStringAsFixed(0),
                              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // 4. Footer Section
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Divider(thickness: 0.5, color: PdfColors.grey300),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Thank you for your business!',
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blueGrey700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // Native Print Dialog စနစ်ဖြင့် Direct Print ထုတ်ရန် (သို့မဟုတ် လိုအပ်ပါက သုံးရန်)
  static Future<void> printOrShareDocument({
    required PaperSizeOption paperSizeOption,
    required String storeName,
    required String address,
    required String phone,
    required String invoiceNo,
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required double discount,
    required double netAmount,
    Uint8List? storeLogoBytes,
  }) async {
    final pdfBytes = await generatePdfDocument(
      paperSizeOption: paperSizeOption,
      storeName: storeName,
      address: address,
      phone: phone,
      invoiceNo: invoiceNo,
      items: items,
      totalAmount: totalAmount,
      discount: discount,
      netAmount: netAmount,
      storeLogoBytes: storeLogoBytes,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Invoice_$invoiceNo.pdf',
    );
  }
}
