import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomerScreen extends StatelessWidget {
  const CustomerScreen({Key? key}) : super(key: key);

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$text ကို Copy ကူးပြီးပါပြီ။'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button & Gradient Customer Support Title)
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
                      "Customer Support",
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

              // 2. Info / Intro Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Headset Icon Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.headset_mic_rounded,
                        size: 48,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "We are here to help!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigoAccent,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "အကြံပြုလိုသည်များ၊ အခက်အခဲရှိသည်များကို အောက်ပါ ဆက်သွယ်ရေးလမ်းကြောင်းများမှ တစ်ဆင့် ဆက်သွယ်မေးမြန်းနိုင်ပါသည်။ (ဖုန်းနံပါတ်ကို နှိပ်၍ Copy ကူးယူနိုင်ပါသည်)",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 3. Facebook Messenger (Coming Soon) Card
              _buildSupportCard(
                context,
                icon: Icons.chat_bubble_outline_rounded,
                title: "Facebook Messenger",
                subtitle: "Coming Soon !",
                subtitleColor: Colors.orange,
              ),
              const SizedBox(height: 12),

              // 4. Telegram Support Card
              _buildSupportCard(
                context,
                icon: Icons.send_rounded,
                title: "Telegram Support",
                subtitle: "+959957794689 (Tap to Copy)",
                copyValue: "+959957794689",
                showCopyButton: true,
              ),
              const SizedBox(height: 12),

              // 5. Viber Support Card
              _buildSupportCard(
                context,
                icon: Icons.phone_in_talk_rounded,
                title: "Viber Support",
                subtitle: "+959957794689 (Tap to Copy)",
                copyValue: "+959957794689",
                showCopyButton: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Color? subtitleColor,
    String? copyValue,
    bool showCopyButton = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: copyValue != null ? () => _copyToClipboard(context, copyValue) : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left Icon Container
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: colorScheme.onSurface.withOpacity(0.8),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            // Middle Text Data
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: subtitleColor != null ? FontWeight.bold : FontWeight.normal,
                      color: subtitleColor ?? colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // Right Copy Button (Optional)
            if (showCopyButton)
              ElevatedButton(
                onPressed: copyValue != null ? () => _copyToClipboard(context, copyValue) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  minimumSize: Size.zero,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  "Copy",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
