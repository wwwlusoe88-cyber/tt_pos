// lib/service/printer_setting.dart

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';

// 1. Printer ချိတ်ဆက်မှု အမျိုးအစား
enum PrinterConnectionType { bluetooth, wifi }

// 2. စာရွက် အရွယ်အစား
enum PaperSizeOption { mm58, mm80, a5, a4 }

// 3. Printer အချက်အလက် Model Class
class PrinterDeviceModel {
  final String name;
  final String address; // Bluetooth MAC Address သို့မဟုတ် WiFi IP Address
  final PrinterConnectionType connectionType;
  final PaperSizeOption paperSize;

  PrinterDeviceModel({
    required this.name,
    required this.address,
    required this.connectionType,
    required this.paperSize,
  });

  PrinterDeviceModel copyWith({
    String? name,
    String? address,
    PrinterConnectionType? connectionType,
    PaperSizeOption? paperSize,
  }) {
    return PrinterDeviceModel(
      name: name ?? this.name,
      address: address ?? this.address,
      connectionType: connectionType ?? this.connectionType,
      paperSize: paperSize ?? this.paperSize,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'connection_type': connectionType.name,
      'paper_size': paperSize.name,
    };
  }

  factory PrinterDeviceModel.fromMap(Map<String, dynamic> map) {
    return PrinterDeviceModel(
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      connectionType: PrinterConnectionType.values.firstWhere(
        (e) => e.name == map['connection_type'],
        orElse: () => PrinterConnectionType.bluetooth,
      ),
      paperSize: PaperSizeOption.values.firstWhere(
        (e) => e.name == map['paper_size'],
        orElse: () => PaperSizeOption.mm58,
      ),
    );
  }
}

class PrinterSettingService extends ChangeNotifier {
  PrinterDeviceModel? _selectedPrinter;
  bool _isScanning = false;
  bool _isConnected = false;

  final BlueThermalPrinter _bluetooth = BlueThermalPrinter.instance;

  PrinterDeviceModel? get selectedPrinter => _selectedPrinter;
  bool get isScanning => _isScanning;
  bool get isConnected => _isConnected;

  void setSelectedPrinter(PrinterDeviceModel printer) {
    _selectedPrinter = printer;
    notifyListeners();
  }

  void setScanning(bool value) {
    _isScanning = value;
    notifyListeners();
  }

  void setPaperSize(PaperSizeOption option) {
    if (_selectedPrinter != null) {
      _selectedPrinter = _selectedPrinter!.copyWith(paperSize: option);
    } else {
      _selectedPrinter = PrinterDeviceModel(
        name: 'Default Printer',
        address: '00:00:00:00:00:00',
        connectionType: PrinterConnectionType.bluetooth,
        paperSize: option,
      );
    }
    notifyListeners();
  }

  // >>> အမှန်တကယ် Print ထုတ်ပေးသည့် Logic <<<
  Future<bool> printBytes(List<int> bytes) async {
    if (_selectedPrinter == null) return false;

    try {
      if (_selectedPrinter!.connectionType == PrinterConnectionType.wifi) {
        // Network / WiFi ESC/POS Thermal Printer များအတွက် Socket Connection ဖြင့် ပို့ခြင်း
        final String ipAddress = _selectedPrinter!.address;
        final socket = await Socket.connect(ipAddress, 9100, timeout: const Duration(seconds: 5));
        socket.add(bytes);
        await socket.flush();
        await socket.close();
        
        _isConnected = true;
        notifyListeners();
        return true;
      } else {
        // Bluetooth Thermal Printer များအတွက် BlueThermalPrinter စနစ်
        final String macAddress = _selectedPrinter!.address;

        // Valid MAC Address စစ်ဆေးခြင်း
        if (macAddress.isEmpty || macAddress == '00:00:00:00:00:00') {
          debugPrint("Print Error: Invalid Bluetooth MAC Address");
          return false;
        }

        // Bluetooth Device Model ဖန်တီးခြင်း
        final device = BluetoothDevice(_selectedPrinter!.name, macAddress);

        // ယခင် ချိတ်ဆက်ထားသည်များ အားလုံးကို ဖြတ်တောက်ပြီး မိတ်ဆက်ခြင်း
        bool? isAlreadyConnected = await _bluetooth.isConnected;
        if (isAlreadyConnected == true) {
          await _bluetooth.disconnect();
        }

        // Bluetooth ချိတ်ဆက်ပြီး Direct writeBytes ပြုလုပ်ခြင်း
        await _bluetooth.connect(device);

        // Data များကို Uint8List Format ဖြင့် Send လုပ်ခြင်း
        await _bluetooth.writeBytes(Uint8List.fromList(bytes));

        _isConnected = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint("Print Error: $e");
      _isConnected = false;
      notifyListeners();
      return false;
    }
  }
}
