import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../logic/expenses_logic.dart';
import '../global/utility/utils.dart';

enum DateFilterType { day, week, month, year, custom }

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final ExpensesLogic _expensesLogic = ExpensesLogic();
  List<ExpenseModel> _expensesList = [];
  bool _isLoading = true;

  String _selectedCategory = "All";
  String _searchQuery = "";

  DateFilterType _selectedDateFilter = DateFilterType.month;
  DateTimeRange? _customDateRange;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  // Database ထဲမှ စရိတ်စာရင်းများကို ဆွဲထုတ်ခြင်း
  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final list = await _expensesLogic.fetchExpenses();
      setState(() {
        _expensesList = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        Utils.showTopToast(context, "စရိတ်စာရင်းများ ရယူရာတွင် အမှားအယွင်းရှိပါသည်: $e", isError: true);
      }
    }
  }

  // Filter ခွဲထုတ်သည့် Logic
  List<ExpenseModel> get _filteredExpenses {
    final now = DateTime.now();

    return _expensesList.where((expense) {
      // 1. Category Filter
      final matchesCategory = _selectedCategory == "All" || expense.category == _selectedCategory;

      // 2. Search Query Filter
      final matchesSearch = expense.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          expense.paymentMethod.toLowerCase().contains(_searchQuery.toLowerCase());

      // 3. Date Filter Logic
      bool matchesDate = true;
      final expDate = expense.dateTime;

      switch (_selectedDateFilter) {
        case DateFilterType.day:
          matchesDate = expDate.year == now.year && expDate.month == now.month && expDate.day == now.day;
          break;
        case DateFilterType.week:
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
          final cleanStart = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          matchesDate = expDate.isAfter(cleanStart.subtract(const Duration(seconds: 1))) && expDate.isBefore(endOfWeek);
          break;
        case DateFilterType.month:
          matchesDate = expDate.year == now.year && expDate.month == now.month;
          break;
        case DateFilterType.year:
          matchesDate = expDate.year == now.year;
          break;
        case DateFilterType.custom:
          if (_customDateRange != null) {
            final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
            final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
            matchesDate = expDate.isAfter(start.subtract(const Duration(seconds: 1))) && expDate.isBefore(end);
          }
          break;
      }

      return matchesCategory && matchesSearch && matchesDate;
    }).toList();
  }

  // Filter လုပ်ထားသော စရိတ် စုစုပေါင်း
  double get _filteredTotal {
    return _filteredExpenses.fold(0.0, (sum, item) => sum + item.amount);
  }

  // အသစ်ထည့်ရန်နှင့် ပြင်ဆင်ရန် Dialog
  void _openExpenseDialog({ExpenseModel? expenseToEdit}) {
    final isEditing = expenseToEdit != null;
    final titleController = TextEditingController(text: isEditing ? expenseToEdit.title : '');
    final amountController = TextEditingController(
      text: isEditing
          ? (expenseToEdit.amount == expenseToEdit.amount.roundToDouble()
              ? expenseToEdit.amount.toInt().toString()
              : expenseToEdit.amount.toString())
          : '',
    );
    final noteController = TextEditingController(text: isEditing ? expenseToEdit.note : '');
    String selectedCat = isEditing ? expenseToEdit.category : "Utilities";
    String selectedPayment = isEditing ? expenseToEdit.paymentMethod : "Cash";
    File? selectedImage = isEditing ? expenseToEdit.receiptImage : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 16,
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEditing ? "စရိတ်စာရင်း ပြင်ဆင်မည်" : "စရိတ်အသစ် စာရင်းသွင်းမည်",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.pop(context),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Title
                    TextField(
                      controller: titleController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "စရိတ်အမည် (Expense Title)",
                        labelStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.edit_note_rounded, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Amount
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "ကျပ်ပမာဏ (Amount in Ks)",
                        labelStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.payments_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Category
                    const Text("Category ရွေးချယ်ပါ", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: ExpensesLogic.categories.where((c) => c != "All").map((cat) {
                        final isSelected = selectedCat == cat;
                        return ChoiceChip(
                          label: Text(cat, style: const TextStyle(fontSize: 12)),
                          selected: isSelected,
                          visualDensity: VisualDensity.compact,
                          selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                          onSelected: (val) {
                            if (val) setModalState(() => selectedCat = cat);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),

                    // Payment Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedPayment,
                      style: TextStyle(fontSize: 14, color: theme.colorScheme.onSurface),
                      decoration: InputDecoration(
                        labelText: "ငွေပေးချေသည့် နည်းလမ်း",
                        labelStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      items: ExpensesLogic.paymentMethods.map((pm) {
                        return DropdownMenuItem(value: pm, child: Text(pm, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setModalState(() => selectedPayment = val);
                      },
                    ),
                    const SizedBox(height: 8),

                    // Image Picker
                    const Text("ပြေစာ/Voucher ဓာတ်ပုံ (Optional)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final img = await ExpensesLogic.pickReceiptImage(ImageSource.camera);
                              if (img != null) setModalState(() => selectedImage = img);
                            },
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text("Camera", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final img = await ExpensesLogic.pickReceiptImage(ImageSource.gallery);
                              if (img != null) setModalState(() => selectedImage = img);
                            },
                            icon: const Icon(Icons.photo_library_outlined, size: 16),
                            label: const Text("Gallery", style: TextStyle(fontSize: 12)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (selectedImage != null) ...[
                      const SizedBox(height: 8),
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(selectedImage!, height: 80, width: double.infinity, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () => setModalState(() => selectedImage = null),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                child: const Icon(Icons.close, color: Colors.white, size: 14),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Note
                    TextField(
                      controller: noteController,
                      style: const TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        labelText: "မှတ်ချက် (Note - Optional)",
                        labelStyle: const TextStyle(fontSize: 13),
                        prefixIcon: const Icon(Icons.description_outlined, size: 20),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Submit Button (Save to SQLite Database)
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEditing ? Colors.orange[800] : theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: Icon(isEditing ? Icons.save_outlined : Icons.check_circle_outline, size: 18),
                        label: Text(
                          isEditing ? "ပြင်ဆင်ချက် သိမ်းမည်" : "သိမ်းဆည်းမည်",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () async {
                          final title = titleController.text;
                          final amountText = amountController.text;

                          if (!Utils.validateField(context, title, "စရိတ်အမည်")) return;
                          if (!Utils.validateField(context, amountText, "ကျပ်ပမာဏ")) return;

                          final amount = double.tryParse(amountText.trim()) ?? 0.0;
                          if (amount <= 0) {
                            Utils.showTopToast(context, "ကျေးဇူးပြု၍ ကျပ်ပမာဏ မှန်ကန်စွာ ဖြည့်ပါ။", isError: true);
                            return;
                          }

                          if (isEditing) {
                            final updatedModel = expenseToEdit.copyWith(
                              title: title.trim(),
                              amount: amount,
                              category: selectedCat,
                              paymentMethod: selectedPayment,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                              receiptImage: selectedImage,
                            );
                            await _expensesLogic.updateExpense(updatedModel);
                          } else {
                            final newExpense = ExpenseModel(
                              expenseCode: ExpensesLogic.generateExpenseCode(),
                              title: title.trim(),
                              amount: amount,
                              category: selectedCat,
                              dateTime: DateTime.now(),
                              paymentMethod: selectedPayment,
                              note: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
                              receiptImage: selectedImage,
                            );
                            await _expensesLogic.insertExpense(newExpense);
                          }

                          if (mounted) {
                            Navigator.pop(context);
                            Utils.showTopToast(
                              context,
                              isEditing ? "စရိတ်စာရင်း ပြင်ဆင်ပြီးပါပြီ။" : "စရိတ်စာရင်း အသစ်ထည့်သွင်းပြီးပါပြီ။",
                            );
                            _loadExpenses(); // DB မှ စာရင်းအသစ် ပြန်လည်ဆွဲထုတ်ရန်
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Delete Confirmation Dialog (Delete from Database)
  void _deleteExpense(int? id) {
    if (id == null) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("စာရင်းဖျက်မည်", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text("ဤစရိတ်စာရင်းကို ဖျက်ရန် သေချာပါသလား။"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("မဖျက်ပါ"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await _expensesLogic.deleteExpense(id);
              if (mounted) {
                Navigator.pop(ctx);
                Utils.showTopToast(context, "စရိတ်စာရင်း ဖျက်ပြီးပါပြီ။");
                _loadExpenses(); // DB မှ စာရင်းပြန်လည်ဆွဲထုတ်ရန်
              }
            },
            child: const Text("ဖျက်မည်", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // Custom Date Range Picker
  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedDateFilter = DateFilterType.custom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
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
                  Expanded(
                    child: Center(
                      child: ShaderMask(
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
                          "Expenses",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // Date Filter Segment Buttons (Day / Week / Month / Year / Custom)
                          _buildDateFilterSegment(context),

                          const SizedBox(height: 12),

                          // Filtered Total Summary Card
                          _buildSummaryCard(context),

                          const SizedBox(height: 16),
                          _buildChartSection(context),
                          const SizedBox(height: 16),

                          // Search Input
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: theme.cardColor,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: TextField(
                              onChanged: (v) => setState(() => _searchQuery = v),
                              decoration: const InputDecoration(
                                hintText: "စရိတ်စာရင်း ရှာဖွေပါ...",
                                prefixIcon: Icon(Icons.search, size: 20),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Category Chips
                          SizedBox(
                            height: 38,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: ExpensesLogic.categories.length,
                              itemBuilder: (context, index) {
                                final cat = ExpensesLogic.categories[index];
                                final isSelected = _selectedCategory == cat;
                                final color = cat == "All"
                                    ? colorScheme.primary
                                    : ExpensesLogic.getCategoryColor(cat);

                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: FilterChip(
                                    label: Text(
                                      cat,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : theme.textTheme.bodyMedium?.color,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        fontSize: 12,
                                      ),
                                    ),
                                    selected: isSelected,
                                    selectedColor: color,
                                    backgroundColor: theme.cardColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    showCheckmark: false,
                                    onSelected: (val) {
                                      setState(() => _selectedCategory = cat);
                                    },
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Expenses List (${_filteredExpenses.length})",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Icon(Icons.history_toggle_off_rounded, size: 20, color: theme.disabledColor),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Expenses List Display
                          _filteredExpenses.isEmpty
                              ? Container(
                                  height: 180,
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.receipt_long_outlined, size: 48, color: theme.disabledColor),
                                      const SizedBox(height: 8),
                                      Text(
                                        "စရိတ် စာရင်း မရှိသေးပါ။",
                                        style: TextStyle(color: theme.disabledColor),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _filteredExpenses.length,
                                  itemBuilder: (context, index) {
                                    final item = _filteredExpenses[index];
                                    return _buildExpenseCard(context, item);
                                  },
                                ),

                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(),
        backgroundColor: colorScheme.primary,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          "Add Expense",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Date Filter Segment Control UI
  Widget _buildDateFilterSegment(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip("Day", DateFilterType.day),
          _buildFilterChip("Week", DateFilterType.week),
          _buildFilterChip("Month", DateFilterType.month),
          _buildFilterChip("Year", DateFilterType.year),
          InkWell(
            onTap: _selectCustomDateRange,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _selectedDateFilter == DateFilterType.custom
                    ? colorScheme.primary
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range,
                    size: 14,
                    color: _selectedDateFilter == DateFilterType.custom
                        ? Colors.white
                        : colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedDateFilter == DateFilterType.custom && _customDateRange != null
                        ? "${Utils.formatDate(_customDateRange!.start)} - ${Utils.formatDate(_customDateRange!.end)}"
                        : "Custom",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _selectedDateFilter == DateFilterType.custom
                          ? Colors.white
                          : colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type) {
    final theme = Theme.of(context);
    final isSelected = _selectedDateFilter == type;

    return Container(
      margin: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: isSelected,
        selectedColor: theme.colorScheme.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : theme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        showCheckmark: false,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedDateFilter = type;
            });
          }
        },
      ),
    );
  }

  // Filter လုပ်ထားသော ပမာဏအလိုက် တင်ပြပေးသည့် Summary Card
  Widget _buildSummaryCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    String labelText = "Total Expense";
    switch (_selectedDateFilter) {
      case DateFilterType.day:
        labelText = "Today's Expense";
        break;
      case DateFilterType.week:
        labelText = "This Week's Expense";
        break;
      case DateFilterType.month:
        labelText = "This Month's Expense";
        break;
      case DateFilterType.year:
        labelText = "This Year's Expense";
        break;
      case DateFilterType.custom:
        labelText = "Selected Period Expense";
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                labelText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                Utils.formatCurrency(_filteredTotal),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 24, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }

  // Chart Breakdown Section
  Widget _buildChartSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Map<String, double> categoryTotals = {};
    double totalAll = 0;

    for (var exp in _filteredExpenses) {
      categoryTotals[exp.category] = (categoryTotals[exp.category] ?? 0) + exp.amount;
      totalAll += exp.amount;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Expense Breakdown",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Icon(Icons.pie_chart_outline_rounded, size: 18, color: theme.colorScheme.primary),
            ],
          ),
          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: totalAll == 0
                  ? Container(color: theme.dividerColor)
                  : Row(
                      children: categoryTotals.entries.map((entry) {
                        final flex = ((entry.value / totalAll) * 100).toInt();
                        if (flex <= 0) return const SizedBox.shrink();
                        return Expanded(
                          flex: flex,
                          child: Container(
                            color: ExpensesLogic.getCategoryColor(entry.key),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: categoryTotals.entries.map((entry) {
              final percentage = totalAll > 0 ? (entry.value / totalAll * 100).toStringAsFixed(0) : "0";
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: ExpensesLogic.getCategoryColor(entry.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "${entry.key} ($percentage%)",
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Edit/Delete ပါဝင်သော Expense Card
  Widget _buildExpenseCard(BuildContext context, ExpenseModel item) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = ExpensesLogic.getCategoryColor(item.category);
    final catIcon = ExpensesLogic.getCategoryIcon(item.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Receipt Image သို့မဟုတ် Category Icon
              item.receiptImage != null
                  ? GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => Dialog(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(item.receiptImage!),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(item.receiptImage!, width: 40, height: 40, fit: BoxFit.cover),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: catColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(catIcon, color: catColor, size: 20),
                    ),
              const SizedBox(width: 10),

              // Title နှင့် Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "-${Utils.formatCurrency(item.amount)}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),

              // Edit & Delete Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Edit Button (ခဲတံ)
                  InkWell(
                    onTap: () => _openExpenseDialog(expenseToEdit: item),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: Icon(Icons.edit_outlined, size: 16, color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Delete Button (အမှိုက်ပုံး)
                  InkWell(
                    onTap: () => _deleteExpense(item.id),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: theme.dividerColor),
          const SizedBox(height: 6),

          // Subtitle Details (Date, Payment Method & Note)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                Utils.formatDate(item.dateTime),
                style: TextStyle(fontSize: 11, color: theme.disabledColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.dividerColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.paymentMethod,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
                ),
              ),
            ],
          ),

          if (item.note != null) ...[
            const SizedBox(height: 4),
            Text(
              "Note: ${item.note}",
              style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: theme.colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ],
      ),
    );
  }
}
