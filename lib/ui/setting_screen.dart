// lib/ui/setting_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/setting_logic.dart';
import 'shopinfo_screen.dart';
import 'buypremium_screen.dart'; 
import 'aboutapp_screen.dart';
import 'customer_screen.dart'; 
import 'printer_setting_screen.dart'; // PrinterSettingScreen Import ထည့်သွင်းထားပါသည်

class SettingScreen extends StatelessWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settingLogic = Provider.of<SettingLogic>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // ညာဘက်မှ စခရင်တစ်ဝက် (သို့) 78% ခန့် Slide ပွင့်လာစေမည့် Drawer
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.78,
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: theme.iconTheme.color ?? colorScheme.onSurface,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Setting",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ) ?? TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Title ကို Center ကျစေရန် spacer
                ],
              ),
            ),

            // Settings Items List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
                children: [
                  // SHOP
                  _buildSectionHeader(context, "SHOP"),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.store_outlined,
                    iconColor: Colors.brown,
                    title: "Shop Information",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ShopInfoScreen()),
                      );
                    },
                  ),

                  // APPEARANCE
                  _buildSectionHeader(context, "APPEARANCE"),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.nightlight_round,
                    iconColor: Colors.amber.shade700,
                    title: "Theme",
                    onTap: () => _showThemeSelectionDialog(context),
                  ),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.language,
                    iconColor: Colors.blue,
                    title: "Language",
                    onTap: () {},
                  ),

                  // SYSTEM & MANAGEMENT
                  _buildSectionHeader(context, "SYSTEM & MANAGEMENT"),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.print_outlined,
                    iconColor: Colors.blueGrey,
                    title: "Printer Setup",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PrinterSettingScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.people_alt_outlined,
                    iconColor: theme.hintColor,
                    title: "Staff Management",
                    onTap: () {},
                  ),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.save_outlined,
                    iconColor: colorScheme.primary,
                    title: "Backup & Restore",
                    onTap: () {},
                  ),

                  // ACCOUNT
                  _buildSectionHeader(context, "ACCOUNT"),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.star_rounded,
                    iconColor: Colors.amber,
                    title: "Buy Premium",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BuyPremiumScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.door_back_door_outlined,
                    iconColor: colorScheme.error,
                    title: "Log Out",
                    onTap: () => settingLogic.logout(context),
                  ),

                  // ABOUT
                  _buildSectionHeader(context, "ABOUT"),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.info_outline,
                    iconColor: Colors.lightBlue,
                    title: "About App",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AboutAppScreen(),
                        ),
                      );
                    },
                  ),
                  _buildSettingCard(
                    context: context,
                    icon: Icons.headset_mic_outlined,
                    iconColor: colorScheme.secondary,
                    title: "Customer Support Team",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CustomerScreen(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Section Label
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 12, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).hintColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // Setting Item Card
  Widget _buildSettingCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.dividerColor.withOpacity(0.2)),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        leading: Icon(icon, color: iconColor, size: 22),
        title: Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, size: 18, color: theme.hintColor),
        onTap: onTap,
      ),
    );
  }

  // Theme ရွေးချယ်ရန် Dialog
  void _showThemeSelectionDialog(BuildContext context) {
    final settingLogic = Provider.of<SettingLogic>(context, listen: false);
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Text(
            "Select Theme",
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<AppThemeOption>(
                title: Text("Default Light", style: theme.textTheme.bodyMedium),
                value: AppThemeOption.light,
                groupValue: settingLogic.selectedThemeOption,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    settingLogic.changeTheme(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<AppThemeOption>(
                title: Text("Dark Theme", style: theme.textTheme.bodyMedium),
                value: AppThemeOption.dark,
                groupValue: settingLogic.selectedThemeOption,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    settingLogic.changeTheme(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<AppThemeOption>(
                title: Text("Modern Highlight (Neon)", style: theme.textTheme.bodyMedium),
                value: AppThemeOption.modernHighlight,
                groupValue: settingLogic.selectedThemeOption,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    settingLogic.changeTheme(val);
                    Navigator.pop(context);
                  }
                },
              ),
              RadioListTile<AppThemeOption>(
                title: Text("System Default", style: theme.textTheme.bodyMedium),
                value: AppThemeOption.system,
                groupValue: settingLogic.selectedThemeOption,
                activeColor: theme.colorScheme.primary,
                onChanged: (val) {
                  if (val != null) {
                    settingLogic.changeTheme(val);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
