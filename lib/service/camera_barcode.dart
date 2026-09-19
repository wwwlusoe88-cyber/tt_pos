import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CameraBarcodeScanner {
  /// Camera Barcode Scanner ကို Dialog ပုံစံဖြင့် ပေါ်လာစေရန် Method
  /// [isContinuous] သည် true ဆိုပါက Sale Screen ကဲ့သို့ ဆက်တိုက် စကန်ဖတ်နိုင်မည် (အလိုအလျောက် မပိတ်ပါ။)
  static void showScanner(
    BuildContext context, {
    required Function(String scannedCode) onScanCompleted,
    bool isContinuous = false,
  }) {
    final MobileScannerController scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    bool isScanned = false; // တစ်ကြိမ်တက်လာရင် ခဏရပ်တန့်ရန် ထိန်းချုပ်ရန်

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 450,
              child: Stack(
                children: [
                  // Camera Scanner View
                  MobileScanner(
                    controller: scannerController,
                    onDetect: (BarcodeCapture capture) {
                      if (isScanned && !isContinuous) return;

                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null) {
                          String code = barcode.rawValue!;

                          if (isContinuous) {
                            // ဆက်တိုက်စကန်ဖတ်မုဒ် (ခဏရပ်ပြီး ထပ်ဖတ်ရန် 0.8 စက္ကန့် စောင့်မည်)
                            isScanned = true;
                            onScanCompleted(code);

                            // ချက်ချင်းထပ်မခေါ်မိစေရန် ခေတ္တစောင့်မည်
                            Future.delayed(const Duration(milliseconds: 800), () {
                              isScanned = false;
                            });
                          } else {
                            // ပုံမှန် တစ်ခုဖတ်ပြီးတာနဲ့ ပိတ်မုဒ်
                            if (isScanned) return;
                            isScanned = true;

                            scannerController.stop();
                            Navigator.pop(dialogContext);
                            onScanCompleted(code);
                          }
                          break;
                        }
                      }
                    },
                  ),

                  // Top Bar (Title & Close Button)
                  Positioned(
                    top: 16,
                    left: 16,
                    right: 16,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isContinuous ? "Continuous Scan Mode" : "Scan Barcode",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () {
                              scannerController.stop();
                              Navigator.pop(dialogContext);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Center Scanning Frame Indicator (Guide Box)
                  Center(
                    child: Container(
                      width: 250,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isContinuous ? Colors.greenAccent : Colors.blueAccent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // Bottom Controls (Torch / Flashlight Button)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: ValueListenableBuilder<MobileScannerState>(
                        valueListenable: scannerController,
                        builder: (context, state, child) {
                          bool isTorchOn = state.torchState == TorchState.on;
                          return FloatingActionButton(
                            backgroundColor: Colors.white24,
                            elevation: 0,
                            onPressed: () => scannerController.toggleTorch(),
                            child: Icon(
                              isTorchOn ? Icons.flash_on : Icons.flash_off,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ).then((_) {
      // 🟢 UPGRADE: Dialog ပိတ်သွားသည်နှင့် (မည်သည့်နည်းဖြင့်မဆို ပိတ်သည်ဖြစ်စေ) 
      // Camera Controller ကို memory ထဲမှ အပြီးအပိုင် ရှင်းလင်းပေးရန် (Memory Leak ကာကွယ်ရန်)
      scannerController.dispose();
    });
  }
}
