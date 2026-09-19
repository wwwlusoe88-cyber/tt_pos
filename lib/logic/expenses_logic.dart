import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sqflite/sqflite.dart';
import '../database/local_database.dart';

class ExpenseModel {
  final int? id;
  final String expenseCode;
  final String title;
  final double amount;
  final String category;
  final DateTime dateTime;
  final String paymentMethod;
  final String? note;
  final File? receiptImage;
  final String ownerId;

  ExpenseModel({
    this.id,
    required this.expenseCode,
    required this.title,
    required this.amount,
    required this.category,
    required this.dateTime,
    required this.paymentMethod,
    this.note,
    this.receiptImage,
    this.ownerId = '',
  });

  ExpenseModel copyWith({
    int? id,
    String? expenseCode,
    String? title,
    double? amount,
    String? category,
    DateTime? dateTime,
    String? paymentMethod,
    String? note,
    File? receiptImage,
    String? ownerId,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      expenseCode: expenseCode ?? this.expenseCode,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      dateTime: dateTime ?? this.dateTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      note: note ?? this.note,
      receiptImage: receiptImage ?? this.receiptImage,
      ownerId: ownerId ?? this.ownerId,
    );
  }

  // SQLite DB မှ Map ကို ExpenseModel အဖြစ် ပြောင်းလဲခြင်း
  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    final imagePath = map['image_path'] as String?;
    return ExpenseModel(
      id: map['id'] as int?,
      expenseCode: map['expense_code'] ?? '',
      title: map['title'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: map['category'] ?? 'Others',
      dateTime: map['date_time'] != null
          ? DateTime.tryParse(map['date_time']) ?? DateTime.now()
          : DateTime.now(),
      paymentMethod: map['payment_method'] ?? 'Cash',
      note: map['note'],
      receiptImage: (imagePath != null && imagePath.isNotEmpty)
          ? File(imagePath)
          : null,
      ownerId: map['owner_id'] ?? '',
    );
  }

  // ExpenseModel ကို SQLite DB တွင် သိမ်းဆည်းရန် Map အဖြစ် ပြောင်းလဲခြင်း
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'expense_code': expenseCode,
      'title': title,
      'amount': amount,
      'category': category,
      'date_time': dateTime.toIso8601String(),
      'payment_method': paymentMethod,
      'note': note,
      'image_path': receiptImage?.path,
      'owner_id': ownerId,
      'updated_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
      'is_deleted': 0,
    };
  }
}

class ExpensesLogic {
  static final List<String> categories = [
    "All",
    "Utilities",
    "Salaries",
    "Rent",
    "Transport",
    "Marketing",
    "Others"
  ];

  static final List<String> paymentMethods = [
    "Cash",
    "KPay",
    "Wave Money",
    "Mobile Banking",
  ];

  // Database ထဲမှ စရိတ်စာရင်း အားလုံးကို ဆွဲထုတ်ခြင်း
  Future<List<ExpenseModel>> fetchExpenses() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'expenses',
      where: 'is_deleted = 0',
      orderBy: 'date_time DESC',
    );

    return maps.map((map) => ExpenseModel.fromMap(map)).toList();
  }

  // စရိတ်စာရင်း အသစ်ထည့်သွင်းခြင်း
  Future<int> insertExpense(ExpenseModel expense) async {
    final db = await LocalDatabase.instance.database;
    return await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // စရိတ်စာရင်း ပြင်ဆင်ခြင်း
  Future<int> updateExpense(ExpenseModel expense) async {
    if (expense.id == null) return 0;
    final db = await LocalDatabase.instance.database;
    return await db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    );
  }

  // စရိတ်စာရင်း ဖျက်ပစ်ခြင်း (Soft Delete ဖြင့် is_deleted = 1 ပြုလုပ်ခြင်း)
  Future<int> deleteExpense(int id) async {
    final db = await LocalDatabase.instance.database;
    return await db.update(
      'expenses',
      {
        'is_deleted': 1,
        'updated_at': DateTime.now().toIso8601String(),
        'is_synced': 0,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense Code အလိုအလျောက် ထုတ်ပေးသည့် Helper Method
  static String generateExpenseCode() {
    final now = DateTime.now();
    final timestamp =
        "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    return "EXP-$timestamp";
  }

  static IconData getCategoryIcon(String category) {
    switch (category) {
      case "Utilities":
        return Icons.bolt_rounded;
      case "Salaries":
        return Icons.badge_outlined;
      case "Rent":
        return Icons.storefront_rounded;
      case "Transport":
        return Icons.directions_car_rounded;
      case "Marketing":
        return Icons.campaign_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case "Utilities":
        return Colors.orangeAccent;
      case "Salaries":
        return Colors.blueAccent;
      case "Rent":
        return Colors.purpleAccent;
      case "Transport":
        return Colors.greenAccent;
      case "Marketing":
        return Colors.pinkAccent;
      default:
        return Colors.tealAccent;
    }
  }

  static Future<File?> pickReceiptImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 70);
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
