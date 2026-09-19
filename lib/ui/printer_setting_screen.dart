// lib/ui/printer_setting_screen.dart

import 'package:flutter/material.dart';
import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:provider/provider.dart';
import '../service/printer_setting.dart';
import '../service/thermal_printer.dart';
import '../service/pdf_printer.dart';
import '../global/utility/utils.dart';

class PrinterSettingScreen extends StatefulWidget {
  const PrinterSettingScreen({super.key});

  @override
  State<PrinterSettingScreen> createState() => _PrinterSettingScreenState();
}

class _PrinterSettingScreenState extends State<PrinterSettingScreen> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _printerNameController = TextEditingController();
  
  PrinterConnectionType _selectedConnectionType = PrinterConnectionType.bluetooth;
  PaperSizeOption _selectedPaperSize = PaperSizeOption.mm58;

  // BluetoothPrint Instance
  final BluetoothPrint _bluetoothPrint = BluetoothPrint.instance;

  // Bluetooth Devices
  List<BluetoothDevice> _pairedDevices = [];
  BluetoothDevice? _selectedBluetoothDevice;
  bool _isLoadingDevices = false;

  @override
  void initState() {
    super.initState();
    final printerService = Provider.of<PrinterSettingService>(context, listen: false);
    if (printerService.selectedPrinter != null) {
      _selectedConnectionType = printerService.selectedPrinter!.connectionType;
      _selectedPaperSize = printerService.selectedPrinter!.paperSize;
      _ipController.text = printerService.selectedPrinter!.address;
      _printerNameController.text = printerService.selectedPrinter!.name;
    } else {
      _printerNameController.text = "Thermal Printer";
    }

    _getBondedDevices();
  }

  // Bluetooth Devices ရှာဖွေခြင်း
  Future<void> _getBondedDevices() async {
    setState(() {
      _isLoadingDevices = true;
    });

    try {
      _bluetoothPrint.startScan(timeout: const Duration(seconds: 4));
      
      _bluetoothPrint.scanResults.listen((val) {
        if (!mounted) return;
        setState(() {
          _pairedDevices = val;
          
          if (_ipController.text.isNotEmpty) {
            try {
              _selectedBluetoothDevice = _pairedDevices.firstWhere(
                (device) => device.address == _ipController.text,
              );
            } catch (_) {
              _selectedBluetoothDevice = null;
            }
          }
        });
      });
    } catch (e) {
      debugPrint("Bluetooth Scan Error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDevices = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _ipController.dispose();
    _printerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final printerService = Provider.of<PrinterSettingService>(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
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
                      "Printer Setup",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 20),

              // Paper Size
              _buildSectionTitle(context, "Paper Size"),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  children: [
                    _buildRadioItem("58mm Thermal", PaperSizeOption.mm58, Icons.receipt_long),
                    Divider(height: 1, color: theme.dividerColor),
                    _buildRadioItem("80mm Thermal", PaperSizeOption.mm80, Icons.receipt),
                    Divider(height: 1, color: theme.dividerColor),
                    _buildRadioItem("A5 Document", PaperSizeOption.a5, Icons.description_outlined),
                    Divider(height: 1, color: theme.dividerColor),
                    _buildRadioItem("A4 Document", PaperSizeOption.a4, Icons.description),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Connection Type
              _buildSectionTitle(context, "Connection Type"),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildConnectionTab(
                      context,
                      title: "Bluetooth",
                      icon: Icons.bluetooth,
                      isSelected: _selectedConnectionType == PrinterConnectionType.bluetooth,
                      onTap: () => setState(() {
                        _selectedConnectionType = PrinterConnectionType.bluetooth;
                        if (_printerNameController.text.isEmpty || _printerNameController.text == "Network Printer") {
                          _printerNameController.text = "Bluetooth Printer";
                        }
                      }),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildConnectionTab(
                      context,
                      title: "WiFi / LAN",
                      icon: Icons.wifi,
                      isSelected: _selectedConnectionType == PrinterConnectionType.wifi,
                      onTap: () => setState(() {
                        _selectedConnectionType = PrinterConnectionType.wifi;
                        if (_printerNameController.text.isEmpty || _printerNameController.text == "Bluetooth Printer") {
                          _printerNameController.text = "Network Printer";
                        }
                      }),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: _selectedConnectionType == PrinterConnectionType.bluetooth
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.bluetooth_searching, color: colorScheme.primary, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Bluetooth Printer Configuration",
                                    style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 14),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.refresh, size: 20),
                                color: colorScheme.primary,
                                tooltip: "Refresh Bluetooth Devices",
                                onPressed: _getBondedDevices,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          _isLoadingDevices
                              ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                              : DropdownButtonFormField<BluetoothDevice>(
                                  value: _selectedBluetoothDevice,
                                  decoration: InputDecoration(
                                    labelText: "Select Paired Bluetooth Device",
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    isDense: true,
                                  ),
                                  items: _pairedDevices.map((device) {
                                    return DropdownMenuItem<BluetoothDevice>(
                                      value: device,
                                      child: Text(
                                        "${device.name ?? 'Unknown'} (${device.address ?? ''})",
                                        style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (device) {
                                    if (device != null) {
                                      setState(() {
                                        _selectedBluetoothDevice = device;
                                        _printerNameController.text = device.name ?? "Bluetooth Printer";
                                        _ipController.text = device.address ?? "";
                                      });
                                    }
                                  },
                                ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _printerNameController,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Printer Name / Model",
                              hintText: "e.g. PT-210, RPP02N",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),

                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "ဖုန်း၏ Bluetooth Settings ထဲတွင် Printer ကို Pair အရင်ပြုလုပ်ပေးပါ။ ထို့နောက် စာရင်းထဲမှ ရွေးချယ်ပေးပါခင်ဗျာ။",
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.lan, color: colorScheme.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                "Network Printer Configuration",
                                style: TextStyle(fontWeight: FontWeight.bold, color: colorScheme.onSurface, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _printerNameController,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "Printer Name",
                              hintText: "e.g. Cashier Network Printer",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _ipController,
                            keyboardType: TextInputType.number,
                            style: TextStyle(color: colorScheme.onSurface, fontSize: 14),
                            decoration: InputDecoration(
                              labelText: "IP Address",
                              hintText: "e.g. 192.168.1.100",
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                              isDense: true,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 18, color: colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Printer နှင့် ဖုန်း/Tablet သည် Same Wi-Fi Network (LAN) တစ်ခုတည်း ချိတ်ဆက်ထားရပါမည်။",
                                    style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.save, color: Colors.white, size: 20),
                label: const Text(
                  "Save Printer Settings",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () {
                  final printer = PrinterDeviceModel(
                    name: _printerNameController.text.trim().isEmpty 
                        ? (_selectedConnectionType == PrinterConnectionType.wifi ? "Network Printer" : "Bluetooth Printer") 
                        : _printerNameController.text.trim(),
                    address: _ipController.text.trim(),
                    connectionType: _selectedConnectionType,
                    paperSize: _selectedPaperSize,
                  );

                  printerService.setSelectedPrinter(printer);
                  Utils.showTopToast(context, "Printer Setting ပြင်ဆင် သိမ်းဆည်းပြီးပါပြီ။");
                },
              ),

              const SizedBox(height: 10),

              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: BorderSide(color: colorScheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: Icon(Icons.print, color: colorScheme.primary, size: 20),
                label: Text(
                  "Test Print",
                  style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                onPressed: () async {
                  if (_selectedPaperSize == PaperSizeOption.a4 || _selectedPaperSize == PaperSizeOption.a5) {
                    await PdfPrinterService.printOrShareDocument(
                      paperSizeOption: _selectedPaperSize,
                      storeName: "TT POS Testing",
                      address: "Yangon, Myanmar",
                      phone: "09123456789",
                      invoiceNo: "TEST-001",
                      items: [
                        {'name': 'Sample Product A', 'qty': 2, 'price': 1500.0},
                        {'name': 'Sample Product B', 'qty': 1, 'price': 3000.0},
                      ],
                      totalAmount: 6000.0,
                      discount: 0.0,
                      netAmount: 6000.0,
                    );
                  } else {
                    if (_ipController.text.trim().isEmpty) {
                      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Printer တစ်ခု အရင်ရွေးချယ်ပေးပါ");
                      return;
                    }

                    Utils.showTopToast(context, "Thermal Receipt Test Print ထုတ်ယူနေပါသည်...");

                    List<int> bytes = await ThermalPrinterService.generateReceiptBytes(
                      paperSizeOption: _selectedPaperSize,
                      storeName: "TT POS TESTING",
                      address: "Yangon, Myanmar",
                      phone: "09123456789",
                      invoiceNo: "TEST-001",
                      dateStr: DateTime.now().toString().substring(0, 16),
                      items: [
                        {'name': 'Test Item 1', 'qty': 1, 'price': 1000.0},
                        {'name': 'Test Item 2', 'qty': 2, 'price': 2500.0},
                      ],
                      totalAmount: 6000.0,
                      discount: 0.0,
                      netAmount: 6000.0,
                    );

                    final testPrinter = PrinterDeviceModel(
                      name: _printerNameController.text.trim(),
                      address: _ipController.text.trim(),
                      connectionType: _selectedConnectionType,
                      paperSize: _selectedPaperSize,
                    );
                    printerService.setSelectedPrinter(testPrinter);

                    bool success = await printerService.printBytes(bytes);

                    if (context.mounted) {
                      if (success) {
                        Utils.showTopToast(context, "Test Print ထုတ်ယူခြင်း အောင်မြင်ပါသည်");
                      } else {
                        Utils.showTopToast(context, "Printer သို့ ချိတ်ဆက်၍ မရပါ");
                      }
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildRadioItem(String title, PaperSizeOption value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedPaperSize == value;

    return InkWell(
      onTap: () => setState(() => _selectedPaperSize = value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.5)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            Radio<PaperSizeOption>(
              value: value,
              groupValue: _selectedPaperSize,
              activeColor: colorScheme.primary,
              onChanged: (val) {
                if (val != null) setState(() => _selectedPaperSize = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTab(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
