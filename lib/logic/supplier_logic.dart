import 'package:flutter/material.dart';
import '../global/utility/utils.dart';
import '../database/local_database.dart';

class SupplierModel {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String address;
  final String note;
  final String ownerId;

  // Sync & Soft Delete Metadata
  final String updatedAt;
  final int isSynced;
  final int isDeleted;

  SupplierModel({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.address,
    required this.note,
    required this.ownerId,
    required this.updatedAt,
    this.isSynced = 0,
    this.isDeleted = 0,
  });

  factory SupplierModel.fromMap(Map<String, dynamic> map) {
    return SupplierModel(
      id: map['id'].toString(),
      name: map['name'] ?? '',
      contactPerson: map['contact_person'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      note: map['note'] ?? '',
      ownerId: map['owner_id'] ?? '',
      updatedAt: map['updated_at'] ?? '',
      isSynced: map['is_synced'] ?? 0,
      isDeleted: map['is_deleted'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'name': name,
      'contact_person': contactPerson,
      'phone': phone,
      'address': address,
      'note': note,
      'owner_id': ownerId,
      'updated_at': updatedAt,
      'is_synced': isSynced,
      'is_deleted': isDeleted,
    };
    if (id.isNotEmpty) {
      map['id'] = int.tryParse(id) ?? id;
    }
    return map;
  }
}

class SupplierLogic extends ChangeNotifier {
  List<SupplierModel> _allSuppliers = [];
  List<SupplierModel> _filteredSuppliers = [];
  String _searchQuery = '';

  final String _currentOwnerId = "default_owner";

  SupplierLogic() {
    fetchSuppliers();
  }

  List<SupplierModel> get suppliers => _filteredSuppliers;

  Future<void> fetchSuppliers() async {
    final db = await LocalDatabase.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'suppliers',
      where: 'owner_id = ? AND (is_deleted = 0 OR is_deleted IS NULL)',
      whereArgs: [_currentOwnerId],
      orderBy: 'id DESC',
    );

    _allSuppliers = maps.map((map) => SupplierModel.fromMap(map)).toList();
    filterSuppliers(_searchQuery);
  }

  void filterSuppliers(String query) {
    _searchQuery = query;
    if (query.isEmpty) {
      _filteredSuppliers = _allSuppliers;
    } else {
      _filteredSuppliers = _allSuppliers
          .where((s) =>
              s.name.toLowerCase().contains(query.toLowerCase()) ||
              s.phone.toLowerCase().contains(query.toLowerCase()) ||
              s.contactPerson.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  Future<bool> saveSupplier(
    BuildContext context, {
    String? id,
    required String name,
    required String contactPerson,
    required String phone,
    required String address,
    required String note,
  }) async {
    if (name.trim().isEmpty || phone.trim().isEmpty) {
      Utils.showTopToast(context, "ကျေးဇူးပြု၍ Company / Supplier Name နှင့် Phone Number ထည့်သွင်းပါ။", isError: true);
      return false;
    }

    final db = await LocalDatabase.instance.database;
    String nowIsoString = DateTime.now().toIso8601String();

    final supplierData = SupplierModel(
      id: id ?? '',
      name: name.trim(),
      contactPerson: contactPerson.trim().isEmpty ? name.trim() : contactPerson.trim(),
      phone: phone.trim(),
      address: address.trim().isEmpty ? '-' : address.trim(),
      note: note.trim().isEmpty ? '-' : note.trim(),
      ownerId: _currentOwnerId,
      updatedAt: nowIsoString,
      isSynced: 0,
      isDeleted: 0,
    );

    if (id == null || id.isEmpty) {
      await db.insert('suppliers', supplierData.toMap());
      if (context.mounted) {
        Utils.showTopToast(context, "Supplier အသစ် ထည့်သွင်းပြီးပါပြီ။");
      }
    } else {
      int? numericId = int.tryParse(id);
      await db.update(
        'suppliers',
        supplierData.toMap(),
        where: 'id = ?',
        whereArgs: [numericId ?? id],
      );
      if (context.mounted) {
        Utils.showTopToast(context, "Supplier အချက်အလက် ပြင်ဆင်ပြီးပါပြီ။");
      }
    }

    await fetchSuppliers();
    return true;
  }

  Future<void> deleteSupplier(BuildContext context, String id) async {
    Utils.showConfirmDialog(
      context: context,
      title: "သတိပေးချက်",
      content: "ဤ Supplier ကို ဖျက်ရန် သေချာပါသလား?",
      confirmText: "ဖျက်မည်",
      onConfirm: () async {
        final db = await LocalDatabase.instance.database;
        int? numericId = int.tryParse(id);

        await db.update(
          'suppliers',
          {
            'is_deleted': 1,
            'updated_at': DateTime.now().toIso8601String(),
            'is_synced': 0,
          },
          where: 'id = ?',
          whereArgs: [numericId ?? id],
        );

        await fetchSuppliers();
        if (context.mounted) {
          Utils.showTopToast(context, "Supplier ကို ဖျက်ပြီးပါပြီ။");
        }
      },
    );
  }

  static void showAddSupplierDialog(BuildContext context, SupplierLogic logic, {SupplierModel? supplierToEdit}) {
    final bool isEditing = supplierToEdit != null;

    final TextEditingController nameController = TextEditingController(text: isEditing ? supplierToEdit.name : '');
    final TextEditingController contactController = TextEditingController(text: isEditing ? supplierToEdit.contactPerson : '');
    final TextEditingController phoneController = TextEditingController(text: isEditing ? supplierToEdit.phone : '');
    final TextEditingController addressController = TextEditingController(text: isEditing ? supplierToEdit.address : '');
    final TextEditingController noteController = TextEditingController(text: isEditing ? supplierToEdit.note : '');

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        final theme = Theme.of(dialogContext);
        final colorScheme = theme.colorScheme;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: theme.cardColor,
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEditing ? "Edit Supplier" : "Add Supplier",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.close, color: colorScheme.onSurface.withOpacity(0.6)),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildTextFieldLabel(dialogContext, "Company / Supplier Name *"),
                const SizedBox(height: 6),
                _buildTextField(dialogContext, nameController, "Enter supplier name"),
                const SizedBox(height: 12),

                _buildTextFieldLabel(dialogContext, "Contact Person"),
                const SizedBox(height: 6),
                _buildTextField(dialogContext, contactController, "Enter contact person"),
                const SizedBox(height: 12),

                _buildTextFieldLabel(dialogContext, "Phone Number *"),
                const SizedBox(height: 6),
                _buildTextField(dialogContext, phoneController, "Enter phone number", keyboardType: TextInputType.phone),
                const SizedBox(height: 12),

                _buildTextFieldLabel(dialogContext, "Address"),
                const SizedBox(height: 6),
                _buildTextField(dialogContext, addressController, "Enter address"),
                const SizedBox(height: 12),

                _buildTextFieldLabel(dialogContext, "Note"),
                const SizedBox(height: 6),
                _buildTextField(dialogContext, noteController, "Additional notes..."),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.dividerColor.withOpacity(0.15),
                          foregroundColor: colorScheme.onSurface,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text("Cancel", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          bool success = await logic.saveSupplier(
                            context,
                            id: isEditing ? supplierToEdit.id : null,
                            name: nameController.text,
                            contactPerson: contactController.text,
                            phone: phoneController.text,
                            address: addressController.text,
                            note: noteController.text,
                          );
                          if (success && dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: Text(isEditing ? "Update" : "Save", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
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

  static Widget _buildTextFieldLabel(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Text(
      label,
      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: colorScheme.onSurface),
    );
  }

  static Widget _buildTextField(BuildContext context, TextEditingController controller, String hintText, {TextInputType keyboardType = TextInputType.text}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      height: 42,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textAlignVertical: TextAlignVertical.center,
        style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.4), fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
    );
  }
}
