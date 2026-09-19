// lib/service/thermal_printer.dart

import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'printer_setting.dart';

class ThermalPrinterService {
  // ESC/POS Bytes များ ထုတ်ပေးမည့် Logic
  static Future<List<int>> generateReceiptBytes({
    required PaperSizeOption paperSizeOption,
    required String storeName,
    required String address,
    required String phone,
    required String invoiceNo,
    String? dateStr,
    required List<Map<String, dynamic>> items, // [{'name': 'Item', 'qty': 1, 'price': 1000}]
    required double totalAmount,
    required double discount,
    required double netAmount,
  }) async {
    final CapabilityProfile profile = await CapabilityProfile.load();
    final PaperSize paperSize = paperSizeOption == PaperSizeOption.mm80 
        ? PaperSize.mm80 
        : PaperSize.mm58;

    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // Header
    bytes += generator.text(
      storeName,
      styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2, width: PosTextSize.size2),
    );
    if (address.isNotEmpty) {
      bytes += generator.text(address, styles: const PosStyles(align: PosAlign.center));
    }
    if (phone.isNotEmpty) {
      bytes += generator.text('Ph: $phone', styles: const PosStyles(align: PosAlign.center));
    }
    bytes += generator.hr();

    // Invoice Info
    bytes += generator.text('Invoice: $invoiceNo', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Date: ${dateStr ?? DateTime.now().toString().substring(0, 16)}', styles: const PosStyles(align: PosAlign.left));
    bytes += generator.hr();

    // Items List
    if (paperSizeOption == PaperSizeOption.mm80) {
      bytes += generator.row([
        PosColumn(text: 'Item', width: 6, styles: const PosStyles(bold: true)),
        PosColumn(text: 'Qty', width: 2, styles: const PosStyles(bold: true, align: PosAlign.right)),
        PosColumn(text: 'Price', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
      ]);
      for (var item in items) {
        bytes += generator.row([
          PosColumn(text: item['name'].toString(), width: 6),
          PosColumn(text: item['qty'].toString(), width: 2, styles: const PosStyles(align: PosAlign.right)),
          PosColumn(text: item['price'].toStringAsFixed(0), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    } else {
      // 58mm
      for (var item in items) {
        bytes += generator.text(item['name'].toString(), styles: const PosStyles(bold: true));
        bytes += generator.row([
          PosColumn(text: '  ${item['qty']} x ${item['price'].toStringAsFixed(0)}', width: 8),
          PosColumn(text: (item['qty'] * item['price']).toStringAsFixed(0), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }

    bytes += generator.hr();

    // Calculation Summary
    bytes += generator.row([
      PosColumn(text: 'Total:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: totalAmount.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    
    if (discount > 0) {
      bytes += generator.row([
        PosColumn(text: 'Discount:', width: 6),
        PosColumn(text: '-${discount.toStringAsFixed(0)}', width: 6, styles: const PosStyles(align: PosAlign.right)),
      ]);
    }

    bytes += generator.row([
      PosColumn(text: 'Net Total:', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: netAmount.toStringAsFixed(0), width: 6, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.hr();
    bytes += generator.text('Thank You!', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.feed(2);
    bytes += generator.cut();

    return bytes;
  }
}
