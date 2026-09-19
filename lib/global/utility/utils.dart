import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Utils {
  // 1. Top Drop-down Toast (Safety logic ပါဝင်အောင် ပြင်ဆင်ထားပါသည်)
  static void showTopToast(BuildContext context, String message, {bool isError = false}) {
    final overlayState = Overlay.maybeOf(context);
    if (overlayState == null) return;

    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, (1 - value) * -50),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isError ? Colors.redAccent : Colors.green[700],
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // 2. Form Field Validation Helper
  static bool validateField(BuildContext context, String value, String fieldName) {
    if (value.trim().isEmpty) {
      showTopToast(context, "ကျေးဇူးပြု၍ $fieldName ထည့်သွင်းပေးပါ။", isError: true);
      return false;
    }
    return true;
  }

  // 3. Global Confirmation Dialog
  static void showConfirmDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = "သေချာပါတယ်",
    String cancelText = "မလုပ်တော့ပါ",
    Color confirmColor = Colors.redAccent,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: confirmColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          confirmText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
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
  }

  // 4. Decimal `.00` / `.0` များမပါဘဲ ပုံစံကျပြသပေးသည့် Helper
  static String formatAmount(double amount) {
    if (amount == amount.roundToDouble()) {
      final formatter = NumberFormat('#,##0', 'en_US');
      return formatter.format(amount.toInt());
    } else {
      final formatter = NumberFormat('#,##0.##', 'en_US');
      return formatter.format(amount);
    }
  }

  // 5. Currency Formatting (ကျပ်ငွေ စာသားပါဝင်သည့် ပုံစံ)
  static String formatCurrency(double amount) {
    return "${formatAmount(amount)} ကျပ်";
  }

  // 6. Date Formatting
  static String formatDate(DateTime date) {
    return DateFormat('dd-MMM-yyyy, hh:mm a').format(date);
  }
}
