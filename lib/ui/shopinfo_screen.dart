import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../logic/shopinfo_logic.dart';

class ShopInfoScreen extends StatelessWidget {
  const ShopInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ChangeNotifierProvider(
      create: (_) => ShopInfoLogic(),
      child: Consumer<ShopInfoLogic>(
        builder: (context, logic, child) {
          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: SafeArea(
              child: logic.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 1. Header (Back Button & Gradient "Shop Information" Title)
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
                                  "Shop Information",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 38), // Center Alignment အတွက် နေရာလွတ်
                            ],
                          ),
                          const SizedBox(height: 20),

                          // 2. Logo Display
                          Center(
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    shape: logic.logoShape == 'circle' ? BoxShape.circle : BoxShape.rectangle,
                                    borderRadius: logic.logoShape == 'rounded' ? BorderRadius.circular(16) : null,
                                    border: Border.all(color: theme.dividerColor, width: 1.5),
                                    image: logic.logoPath.isNotEmpty
                                        ? DecorationImage(
                                            image: FileImage(File(logic.logoPath)),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: logic.logoPath.isEmpty
                                      ? Icon(Icons.storefront, size: 48, color: colorScheme.primary.withOpacity(0.7))
                                      : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Choose Logo Button
                          OutlinedButton(
                            onPressed: () => _showImagePickerModal(context, logic),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: theme.dividerColor),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Text(
                              "Choose Logo",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Logo Shape Selection
                          Text(
                            "Logo Shape",
                            style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: _buildShapeSelector(
                                  context: context,
                                  label: "Rounded Square",
                                  isSelected: logic.logoShape == 'rounded',
                                  shapeIcon: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  onTap: () => logic.setLogoShape('rounded'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildShapeSelector(
                                  context: context,
                                  label: "Circle",
                                  isSelected: logic.logoShape == 'circle',
                                  shapeIcon: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: colorScheme.primary, width: 2),
                                    ),
                                  ),
                                  onTap: () => logic.setLogoShape('circle'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Input Fields
                          _buildInputField(context, "Shop Name", logic.nameController, "Enter shop name"),
                          const SizedBox(height: 12),
                          _buildInputField(context, "Phone Number", logic.phoneController, "09xxxxxxxxx", keyboardType: TextInputType.phone),
                          const SizedBox(height: 12),
                          _buildInputField(context, "Address", logic.addressController, "Enter shop address", maxLines: 2),
                          const SizedBox(height: 12),
                          _buildInputField(context, "Tax ID / Business Reg No.", logic.taxIdController, "e.g. TAX-987654"),
                          const SizedBox(height: 12),
                          _buildInputField(context, "Receipt Header Note", logic.headerNoteController, "e.g. Welcome to Our Store!"),
                          const SizedBox(height: 12),
                          _buildInputField(context, "Receipt Footer Note", logic.footerNoteController, "e.g. Thank you! Please come again."),
                          const SizedBox(height: 24),

                          // Save Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: () => logic.saveShopInfo(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Save Information",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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
    );
  }

  Widget _buildShapeSelector({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required Widget shapeIcon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? colorScheme.primary : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            shapeIcon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context,
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 13.5, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
            filled: true,
            fillColor: theme.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  void _showImagePickerModal(BuildContext context, ShopInfoLogic logic) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery မှ ရွေးမည်"),
                onTap: () {
                  Navigator.pop(context);
                  logic.pickLogoImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera ဖြင့် ဓာတ်ပုံရိုက်မည်"),
                onTap: () {
                  Navigator.pop(context);
                  logic.pickLogoImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
