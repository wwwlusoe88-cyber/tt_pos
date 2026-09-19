import 'package:flutter/material.dart';

class TTPosLogo extends StatelessWidget {
  final double size; // Logo အရွယ်အစား (Size) ကို စိတ်ကြိုက် သတ်မှတ်နိုင်သည်

  // const constructor ဖြင့် စနစ်တကျ သတ်မှတ်ပေးထားပါသည်
  const TTPosLogo({Key? key, this.size = 180}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF031B4E), // Dark Blue Inner Circle
        border: Border.all(
          color: const Color(0xFF00A2FF), 
          width: size * 0.035,
        ), // Light Blue Outer Ring
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00A2FF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Section: 'TT' Bold Text & POS Machine Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 'T' White
                  Text(
                    "T",
                    style: TextStyle(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                  // 'T' Light Blue
                  Text(
                    "T",
                    style: TextStyle(
                      fontSize: size * 0.28,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF00A2FF),
                    ),
                  ),
                  SizedBox(width: size * 0.03),
                  // POS Terminal Icon Wrapper
                  Container(
                    padding: EdgeInsets.all(size * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(size * 0.04),
                    ),
                    child: Icon(
                      Icons.point_of_sale,
                      size: size * 0.18,
                      color: const Color(0xFF031B4E),
                    ),
                  ),
                ],
              ),

              SizedBox(height: size * 0.02),

              // Middle Section: 'TT POS' Text
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "TT ",
                    style: TextStyle(
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    "POS",
                    style: TextStyle(
                      fontSize: size * 0.12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF00A2FF),
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),

              SizedBox(height: size * 0.01),

              // Bottom Tagline: SMART POS, EASY BUSINESS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: size * 0.08, 
                    height: 1.5, 
                    color: const Color(0xFF00A2FF),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size * 0.02),
                    child: Text(
                      "SMART POS, EASY BUSINESS",
                      style: TextStyle(
                        fontSize: size * 0.038,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    width: size * 0.08, 
                    height: 1.5, 
                    color: const Color(0xFF00A2FF),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
