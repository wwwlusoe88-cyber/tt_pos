import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/viplist_logic.dart';
import '../global/utility/utils.dart';

class VipListScreen extends StatelessWidget {
  const VipListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<VipListLogic>(
      builder: (context, vipLogic, child) {
        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          floatingActionButton: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: FloatingActionButton.extended(
              onPressed: () => _showAddVipBottomSheet(context, vipLogic),
              backgroundColor: Colors.transparent,
              elevation: 0,
              highlightElevation: 0,
              icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
              label: const Text(
                "VIP အသစ်ထည့်မည်",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. App Header Bar
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
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(Rect.fromLTWH(0, 0, bounds.width, bounds.height)),
                        child: const Text(
                          "VIP Members",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
                          icon: Icon(Icons.tune_rounded, color: colorScheme.primary, size: 20),
                          onPressed: () => _showSettingsDialog(context, vipLogic),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 2. Metrics Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          "Total VIP",
                          "${vipLogic.totalMembers}",
                          Icons.workspace_premium_rounded,
                          colorScheme.primary,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMetricCard(
                          context,
                          "Total Points",
                          Utils.formatAmount(vipLogic.totalPoints.toDouble()),
                          Icons.stars_rounded,
                          Colors.amber,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      style: TextStyle(color: colorScheme.onSurface),
                      onChanged: (value) => vipLogic.setSearchQuery(value),
                      decoration: InputDecoration(
                        hintText: "အမည် သို့မဟုတ် ဖုန်းနံပါတ် ရှာပါ...",
                        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: colorScheme.onSurface.withOpacity(0.5)),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4. Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ["All", "Diamond", "Gold", "Silver"].map((tier) {
                        final isSelected = vipLogic.selectedTierFilter == tier;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tier),
                            selected: isSelected,
                            onSelected: (_) => vipLogic.setTierFilter(tier),
                            selectedColor: colorScheme.primary,
                            backgroundColor: theme.cardColor,
                            elevation: isSelected ? 2 : 0,
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : theme.dividerColor.withOpacity(0.6),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : colorScheme.onSurface.withOpacity(0.8),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 5. VIP Members List
                  Expanded(
                    child: vipLogic.vipMembers.isEmpty
                        ? Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(0.08),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.card_membership_rounded,
                                      size: 64,
                                      color: colorScheme.primary.withOpacity(0.6),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "VIP Member များ မရှိသေးပါ",
                                    style: TextStyle(
                                      color: colorScheme.onSurface,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "VIP Member အသစ် ထည့်သွင်းရန် အောက်ပါ ခလုတ်ကို နှိပ်ပါ",
                                    style: TextStyle(
                                      color: colorScheme.onSurface.withOpacity(0.5),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemCount: vipLogic.vipMembers.length,
                            itemBuilder: (context, index) {
                              final member = vipLogic.vipMembers[index];
                              return _buildVipCard(context, member, vipLogic, isDark);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color iconColor, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 24, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.6), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVipCard(BuildContext context, VipMember member, VipListLogic logic, bool isDark) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color tierColor = Colors.grey;
    if (member.tier == "Diamond") tierColor = Colors.cyan;
    if (member.tier == "Gold") tierColor = Colors.amber;
    if (member.tier == "Silver") tierColor = Colors.blueGrey;

    final discountPercent = logic.getDiscountPercentageForTier(member.tier);

    double nextTarget = 0;
    String nextTierName = '';
    if (member.tier == 'Silver') {
      final goldSetting = logic.tierSettings.firstWhere((s) => s.tierName == 'Gold', orElse: () => VipTierSetting(tierName: '', minAmount: 300000, discountPercent: 0));
      nextTarget = goldSetting.minAmount;
      nextTierName = 'Gold';
    } else if (member.tier == 'Gold') {
      final diamondSetting = logic.tierSettings.firstWhere((s) => s.tierName == 'Diamond', orElse: () => VipTierSetting(tierName: '', minAmount: 500000, discountPercent: 0));
      nextTarget = diamondSetting.minAmount;
      nextTierName = 'Diamond';
    }

    double progress = (nextTarget > 0) ? (member.totalSpent / nextTarget).clamp(0.0, 1.0) : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: tierColor.withOpacity(0.15),
                child: Text(
                  member.name.isNotEmpty ? member.name[0].toUpperCase() : "V",
                  style: TextStyle(fontWeight: FontWeight.bold, color: tierColor, fontSize: 16),
                ),
              ),
              const SizedBox(width: 10),
              // Name and Tier Block (Overflow မဖြစ်အောင် Expanded သုံးထားပါသည်)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            member.name,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: tierColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: tierColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            member.tier,
                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tierColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${member.phone}  •  Discount ${discountPercent.toInt()}%",
                      style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.6)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              // Action Buttons Row (Overflow မဖြစ်စေရန် Space များကို ကျဉ်းပေးထားပါသည်)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.stars_outlined, size: 18, color: Colors.amber),
                    onPressed: () => _showPointAdjustDialog(context, logic, member),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'Points ပြင်မည်',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
                    onPressed: () => _showAddVipBottomSheet(context, logic, memberToEdit: member),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'ပြင်ဆင်မည်',
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                    onPressed: () {
                      Utils.showConfirmDialog(
                        context: context,
                        title: "VIP Member ဖျက်ရန်",
                        content: "'${member.name}' ကို VIP စာရင်းမှ ဖျက်ပစ်ရန် သေချာပါသလား။",
                        confirmText: "ဖျက်မည်",
                        onConfirm: () async {
                          await logic.deleteVipMember(member.id);
                          if (context.mounted) {
                            Utils.showTopToast(context, "VIP Member ကို ဖျက်ပြီးပါပြီ");
                          }
                        },
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                    tooltip: 'ဖျက်မည်',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          if (nextTarget > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 5,
                backgroundColor: theme.dividerColor.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(tierColor),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "နောက်ထပ် ${Utils.formatCurrency(nextTarget - member.totalSpent)} ဝယ်ယူပါက $nextTierName Tier သို့ ရောက်ရှိမည်",
              style: TextStyle(fontSize: 10, color: colorScheme.onSurface.withOpacity(0.5)),
            ),
            const SizedBox(height: 8),
          ],

          Divider(height: 1, color: theme.dividerColor.withOpacity(0.6)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Spent: ${Utils.formatCurrency(member.totalSpent)}",
                style: TextStyle(fontSize: 13, color: colorScheme.onSurface, fontWeight: FontWeight.w500),
              ),
              Row(
                children: [
                  const Icon(Icons.stars_rounded, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    "${member.points} Pts",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddVipBottomSheet(BuildContext context, VipListLogic logic, {VipMember? memberToEdit}) {
    final nameController = TextEditingController(text: memberToEdit?.name ?? '');
    final phoneController = TextEditingController(text: memberToEdit?.phone ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 16,
            left: 20,
            right: 20,
          ),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  memberToEdit == null ? "VIP Member အသစ်ထည့်ရန်" : "VIP Member ပြင်ဆင်ရန်",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "အမည်",
                    hintText: "ဝယ်ယူသူအမည်",
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: "ဖုန်းနံပါတ်",
                    hintText: "09xxxxxxxxx",
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: theme.scaffoldBackgroundColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("မလုပ်တော့ပါ"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          if (!Utils.validateField(context, nameController.text, "အမည်")) return;
                          if (!Utils.validateField(context, phoneController.text, "ဖုန်းနံပါတ်")) return;

                          if (memberToEdit == null) {
                            await logic.addVipMember(
                              VipMember(
                                id: "VIP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}",
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                tier: 'Silver',
                                totalSpent: 0,
                                points: 0,
                                lastPurchaseDate: DateTime.now().toString().split(' ')[0],
                              ),
                            );
                          } else {
                            await logic.updateVipMember(
                              VipMember(
                                id: memberToEdit.id,
                                name: nameController.text.trim(),
                                phone: phoneController.text.trim(),
                                tier: memberToEdit.tier,
                                totalSpent: memberToEdit.totalSpent,
                                points: memberToEdit.points,
                                lastPurchaseDate: memberToEdit.lastPurchaseDate,
                              ),
                            );
                          }

                          if (context.mounted) {
                            Navigator.pop(context);
                            Utils.showTopToast(context, memberToEdit == null ? "VIP Member ထည့်သွင်းပြီးပါပြီ" : "VIP Member အချက်အလက် ပြင်ပြီးပါပြီ");
                          }
                        },
                        child: const Text("သိမ်းဆည်းမည်", style: TextStyle(fontWeight: FontWeight.bold)),
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

  void _showPointAdjustDialog(BuildContext context, VipListLogic logic, VipMember member) {
    final pointsController = TextEditingController();
    bool isAdd = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final theme = Theme.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              title: Text("${member.name} - Point ပြင်ရန်", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("+ ပေါင်းမည်"),
                          selected: isAdd,
                          onSelected: (_) => setState(() => isAdd = true),
                          selectedColor: Colors.green,
                          labelStyle: TextStyle(color: isAdd ? Colors.white : theme.textTheme.bodyMedium?.color, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text("- နှုတ်မည်"),
                          selected: !isAdd,
                          onSelected: (_) => setState(() => isAdd = false),
                          selectedColor: Colors.redAccent,
                          labelStyle: TextStyle(color: !isAdd ? Colors.white : theme.textTheme.bodyMedium?.color, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: pointsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Points ပမာဏ",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("မလုပ်တော့ပါ"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final pts = int.tryParse(pointsController.text.trim()) ?? 0;
                    if (pts <= 0) return;
                    await logic.adjustPoints(member.id, isAdd ? pts : -pts);
                    if (context.mounted) {
                      Navigator.pop(context);
                      Utils.showTopToast(context, "Points ပြင်ဆင်ပြီးပါပြီ");
                    }
                  },
                  child: const Text("အတည်ပြုမည်"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSettingsDialog(BuildContext context, VipListLogic logic) {
    final goldMinCtrl = TextEditingController(
      text: logic.tierSettings.firstWhere((s) => s.tierName == 'Gold', orElse: () => VipTierSetting(tierName: 'Gold', minAmount: 300000, discountPercent: 5)).minAmount.toInt().toString(),
    );
    final goldDiscCtrl = TextEditingController(
      text: logic.tierSettings.firstWhere((s) => s.tierName == 'Gold', orElse: () => VipTierSetting(tierName: 'Gold', minAmount: 300000, discountPercent: 5)).discountPercent.toInt().toString(),
    );

    final diamondMinCtrl = TextEditingController(
      text: logic.tierSettings.firstWhere((s) => s.tierName == 'Diamond', orElse: () => VipTierSetting(tierName: 'Diamond', minAmount: 500000, discountPercent: 10)).minAmount.toInt().toString(),
    );
    final diamondDiscCtrl = TextEditingController(
      text: logic.tierSettings.firstWhere((s) => s.tierName == 'Diamond', orElse: () => VipTierSetting(tierName: 'Diamond', minAmount: 500000, discountPercent: 10)).discountPercent.toInt().toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.settings_suggest_rounded, color: colorScheme.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "VIP Tier & Discount",
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                            ),
                            Text(
                              "သတ်မှတ်ချက်များ ပြင်ဆင်ရန်",
                              style: TextStyle(fontSize: 11, color: colorScheme.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildTierSettingCard(
                    context: context,
                    tierTitle: "Gold Tier သတ်မှတ်ချက်",
                    titleColor: Colors.amber,
                    minCtrl: goldMinCtrl,
                    discCtrl: goldDiscCtrl,
                  ),
                  const SizedBox(height: 12),

                  _buildTierSettingCard(
                    context: context,
                    tierTitle: "Diamond Tier သတ်မှတ်ချက်",
                    titleColor: Colors.cyan,
                    minCtrl: diamondMinCtrl,
                    discCtrl: diamondDiscCtrl,
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text("မလုပ်တော့ပါ", style: TextStyle(fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          final goldMin = double.tryParse(goldMinCtrl.text) ?? 300000;
                          final goldDisc = double.tryParse(goldDiscCtrl.text) ?? 5;
                          final diamondMin = double.tryParse(diamondMinCtrl.text) ?? 500000;
                          final diamondDisc = double.tryParse(diamondDiscCtrl.text) ?? 10;

                          final updatedList = [
                            VipTierSetting(tierName: 'Silver', minAmount: 0, discountPercent: 0),
                            VipTierSetting(tierName: 'Gold', minAmount: goldMin, discountPercent: goldDisc),
                            VipTierSetting(tierName: 'Diamond', minAmount: diamondMin, discountPercent: diamondDisc),
                          ];

                          await logic.updateTierSettings(updatedList);
                          if (context.mounted) {
                            Navigator.pop(context);
                            Utils.showTopToast(context, "VIP Settings ပြင်ဆင်ပြီးပါပြီ");
                          }
                        },
                        child: const Text("သိမ်းဆည်းမည်", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTierSettingCard({
    required BuildContext context,
    required String tierTitle,
    required Color titleColor,
    required TextEditingController minCtrl,
    required TextEditingController discCtrl,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: titleColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                tierTitle,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: minCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: "Min Total Spent (Ks)",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: discCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              labelText: "Discount (%)",
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }
}
