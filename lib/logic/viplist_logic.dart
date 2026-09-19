import 'package:flutter/material.dart';
import '../database/local_database.dart';

class VipMember {
  final String id;
  final String name;
  final String phone;
  final String tier;
  final double totalSpent;
  final int points;
  final String lastPurchaseDate;

  VipMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.tier,
    required this.totalSpent,
    required this.points,
    required this.lastPurchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'tier': tier,
      'total_spent': totalSpent,
      'points': points,
      'last_purchase_date': lastPurchaseDate,
      'updated_at': DateTime.now().toIso8601String(),
      'is_deleted': 0,
    };
  }

  factory VipMember.fromMap(Map<String, dynamic> map) {
    return VipMember(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      tier: map['tier'] ?? 'Silver',
      totalSpent: (map['total_spent'] as num?)?.toDouble() ?? 0.0,
      points: map['points'] ?? 0,
      lastPurchaseDate: map['last_purchase_date'] ?? '',
    );
  }
}

class VipTierSetting {
  final String tierName;
  final double minAmount;
  final double discountPercent;

  VipTierSetting({
    required this.tierName,
    required this.minAmount,
    required this.discountPercent,
  });

  factory VipTierSetting.fromMap(Map<String, dynamic> map) {
    return VipTierSetting(
      tierName: map['tier_name'],
      minAmount: (map['min_amount'] as num).toDouble(),
      discountPercent: (map['discount_percent'] as num).toDouble(),
    );
  }
}

class VipListLogic extends ChangeNotifier {
  List<VipMember> _allMembers = [];
  List<VipTierSetting> _tierSettings = [];
  String _searchQuery = '';
  String _selectedTierFilter = 'All';

  VipListLogic() {
    initData();
  }

  Future<void> initData() async {
    await fetchVipSettings();
    await fetchVipMembers();
  }

  Future<void> fetchVipSettings() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query('vip_settings', orderBy: 'min_amount ASC');
    _tierSettings = maps.map((m) => VipTierSetting.fromMap(m)).toList();
    notifyListeners();
  }

  Future<void> updateTierSettings(List<VipTierSetting> settings) async {
    final db = await LocalDatabase.instance.database;
    await db.transaction((txn) async {
      for (var setting in settings) {
        await txn.update(
          'vip_settings',
          {
            'min_amount': setting.minAmount,
            'discount_percent': setting.discountPercent,
          },
          where: 'tier_name = ?',
          whereArgs: [setting.tierName],
        );
      }
    });
    await fetchVipSettings();
    await _recalculateAllMemberTiers();
  }

  Future<void> fetchVipMembers() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'vips',
      where: 'is_deleted = 0',
      orderBy: 'total_spent DESC',
    );

    _allMembers = maps.map((map) => VipMember.fromMap(map)).toList();
    notifyListeners();
  }

  List<VipMember> get vipMembers {
    return _allMembers.where((member) {
      final matchesSearch = member.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          member.phone.contains(_searchQuery);
      final matchesTier = _selectedTierFilter == 'All' || member.tier == _selectedTierFilter;
      return matchesSearch && matchesTier;
    }).toList();
  }

  int get totalMembers => _allMembers.length;
  int get totalPoints => _allMembers.fold(0, (sum, member) => sum + member.points);
  String get selectedTierFilter => _selectedTierFilter;
  List<VipTierSetting> get tierSettings => _tierSettings;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setTierFilter(String tier) {
    _selectedTierFilter = tier;
    notifyListeners();
  }

  String calculateTier(double totalSpent) {
    String matchedTier = 'Silver';
    double maxMinAmount = -1;

    for (var setting in _tierSettings) {
      if (totalSpent >= setting.minAmount && setting.minAmount > maxMinAmount) {
        maxMinAmount = setting.minAmount;
        matchedTier = setting.tierName;
      }
    }
    return matchedTier;
  }

  double getDiscountPercentageForTier(String tier) {
    final setting = _tierSettings.firstWhere(
      (s) => s.tierName == tier,
      orElse: () => VipTierSetting(tierName: 'Silver', minAmount: 0, discountPercent: 0),
    );
    return setting.discountPercent;
  }

  // UNIQUE constraint error မတက်စေရန် Soft-deleted record ရှိပါက ပြန်လည် အသုံးပြုရန် ပြင်ဆင်ထားပါသည်
  Future<void> addVipMember(VipMember member) async {
    final db = await LocalDatabase.instance.database;
    final autoTier = calculateTier(member.totalSpent);

    final existing = await db.query('vips', where: 'phone = ?', whereArgs: [member.phone]);

    if (existing.isNotEmpty) {
      await db.update(
        'vips',
        {
          'name': member.name,
          'tier': autoTier,
          'total_spent': member.totalSpent,
          'points': member.points,
          'last_purchase_date': member.lastPurchaseDate,
          'is_deleted': 0,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'phone = ?',
        whereArgs: [member.phone],
      );
    } else {
      final newMember = VipMember(
        id: member.id,
        name: member.name,
        phone: member.phone,
        tier: autoTier,
        totalSpent: member.totalSpent,
        points: member.points,
        lastPurchaseDate: member.lastPurchaseDate,
      );
      await db.insert('vips', newMember.toMap());
    }
    await fetchVipMembers();
  }

  Future<void> updateVipMember(VipMember member) async {
    final db = await LocalDatabase.instance.database;
    final autoTier = calculateTier(member.totalSpent);

    await db.update(
      'vips',
      {
        'name': member.name,
        'phone': member.phone,
        'tier': autoTier,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [member.id],
    );
    await fetchVipMembers();
  }

  Future<void> adjustPoints(String id, int pointsChange) async {
    final db = await LocalDatabase.instance.database;
    final result = await db.query('vips', where: 'id = ?', whereArgs: [id]);
    if (result.isNotEmpty) {
      final currentPoints = result.first['points'] as int? ?? 0;
      final updatedPoints = (currentPoints + pointsChange) < 0 ? 0 : (currentPoints + pointsChange);

      await db.update(
        'vips',
        {
          'points': updatedPoints,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
      await fetchVipMembers();
    }
  }

  Future<void> _recalculateAllMemberTiers() async {
    final db = await LocalDatabase.instance.database;
    for (var member in _allMembers) {
      final newTier = calculateTier(member.totalSpent);
      if (newTier != member.tier) {
        await db.update(
          'vips',
          {'tier': newTier, 'updated_at': DateTime.now().toIso8601String()},
          where: 'id = ?',
          whereArgs: [member.id],
        );
      }
    }
    await fetchVipMembers();
  }

  Future<void> deleteVipMember(String id) async {
    final db = await LocalDatabase.instance.database;
    await db.update(
      'vips',
      {'is_deleted': 1, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
    await fetchVipMembers();
  }
}
