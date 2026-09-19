import 'package:flutter/material.dart';
import '../logic/supplier_logic.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({Key? key}) : super(key: key);

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  late final SupplierLogic _supplierLogic;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _supplierLogic = SupplierLogic();
    _supplierLogic.addListener(_onLogicChanged);
  }

  void _onLogicChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _supplierLogic.removeListener(_onLogicChanged);
    _supplierLogic.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    int totalCount = _supplierLogic.suppliers.length;
    String supplierLabel = "$totalCount Suppliers";

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Back Button & Title)
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
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.iconTheme.color ?? colorScheme.onSurface,
                        size: 20,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        "Supplier Management",
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ) ?? TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: colorScheme.primary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Add Supplier Button
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => SupplierLogic.showAddSupplierDialog(context, _supplierLogic),
                  icon: Icon(Icons.add, size: 18, color: colorScheme.onPrimary),
                  label: Text(
                    "Add Supplier",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: colorScheme.onPrimary),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 3. Search Bar
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => _supplierLogic.filterSuppliers(value),
                  style: textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: "Search supplier name or phone...",
                    hintStyle: TextStyle(color: theme.hintColor, fontSize: 14),
                    prefixIcon: Icon(Icons.search, color: theme.hintColor),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Counter Label
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 4.0),
                  child: Text(
                    supplierLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // 5. Supplier List Cards
              _supplierLogic.suppliers.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(top: 40),
                      child: Center(
                        child: Text(
                          "Supplier မရှိသေးပါ။",
                          style: TextStyle(color: theme.hintColor, fontSize: 15),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _supplierLogic.suppliers.length,
                      itemBuilder: (context, index) {
                        final supplier = _supplierLogic.suppliers[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 8,
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
                                  Expanded(
                                    child: Text(
                                      supplier.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          SupplierLogic.showAddSupplierDialog(
                                            context,
                                            _supplierLogic,
                                            supplierToEdit: supplier,
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: theme.dividerColor.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: theme.dividerColor),
                                          ),
                                          child: Icon(Icons.edit_outlined, size: 16, color: theme.hintColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () => _supplierLogic.deleteSupplier(context, supplier.id),
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: colorScheme.error.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: colorScheme.error.withOpacity(0.3)),
                                          ),
                                          child: Icon(Icons.delete_outline, size: 16, color: colorScheme.error),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Divider(height: 1, color: theme.dividerColor),
                              const SizedBox(height: 8),

                              // Contact Person Info
                              Row(
                                children: [
                                  Icon(Icons.person, size: 16, color: theme.hintColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      supplier.contactPerson,
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Phone Info
                              Row(
                                children: [
                                  Icon(Icons.phone, size: 16, color: theme.hintColor),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "ဖုန်း: ${supplier.phone}",
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),

                              // Address Info
                              Row(
                                children: [
                                  Icon(Icons.location_on, size: 16, color: colorScheme.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "လိပ်စာ: ${supplier.address}",
                                      style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
