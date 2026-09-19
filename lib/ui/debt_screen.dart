import 'package:flutter/material.dart';

class DebtScreen extends StatelessWidget {
  const DebtScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F7),
      appBar: AppBar(
        title: const Text("Debt List (အကြွေးစာရင်း)"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: Colors.orangeAccent,
            ),
            SizedBox(height: 16),
            Text(
              "Debt Screen (Coming Soon)",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 8),
            Text(
              "ဖောက်သည်များ၏ အကြွေးစာရင်းများ မှတ်တမ်းတင်ရန် နေရာ",
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
