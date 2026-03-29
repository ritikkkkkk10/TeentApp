import 'package:flutter/material.dart';
import '../services/inventory_service.dart';

class BulkEntry {
  String type;

  final TextEditingController nameController;
  final TextEditingController qtyController;
  final TextEditingController rentController;
  final TextEditingController servicePriceController;

  BulkEntry({
    this.type = "item",
  })  : nameController = TextEditingController(),
        qtyController = TextEditingController(),
        rentController = TextEditingController(),
        servicePriceController = TextEditingController();
}

class BulkAddInventoryScreen extends StatefulWidget {
  final String? parentId;

  const BulkAddInventoryScreen({
    super.key,
    required this.parentId,
  });

  @override
  State<BulkAddInventoryScreen> createState() => _BulkAddInventoryScreenState();
}

class _BulkAddInventoryScreenState extends State<BulkAddInventoryScreen> {
  List<BulkEntry> entries = [BulkEntry()];
  bool isLoading = false;

  void addRow() {
    setState(() {
      entries.add(BulkEntry());
    });
  }

  void removeRow(int index) {
    setState(() {
      entries.removeAt(index);
    });
  }

  Widget buildRow(int index) {
    final entry = entries[index];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
          )
        ],
      ),
      child: Column(
        children: [
          /// 🔷 HEADER (THINNER + PURE BLUE)
          Container(
            height: 40, // ✅ thinner bar
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1E4FA3), // ✅ pure blue
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonHideUnderline(
 child: DropdownButton<String>(
  value: entry.type,
  isExpanded: true,
  dropdownColor: Colors.white,
  iconEnabledColor: Colors.white,

  /// ✅ FIXED — clean selected view (no layout break)
  selectedItemBuilder: (context) {
    return ["item", "service", "category"].map((value) {
      return Align(
        alignment: Alignment.centerLeft, // ✅ fixes weird spacing
        child: Text(
          value[0].toUpperCase() + value.substring(1),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }).toList();
  },

  /// ✅ dropdown menu text color
  style: const TextStyle(
    color: Colors.black,
    fontSize: 14,
  ),

  items: const [
    DropdownMenuItem(value: "item", child: Text("Item")),
    DropdownMenuItem(value: "service", child: Text("Service")),
    DropdownMenuItem(value: "category", child: Text("Category")),
  ],

  onChanged: (val) {
    setState(() {
      entry.type = val!;
    });
  },
)),
                ),
                IconButton(
                  onPressed: () => removeRow(index),
                  icon: const Icon(Icons.delete, color: Colors.white, size: 18),
                )
              ],
            ),
          ),

          const SizedBox(height: 2),

          /// 🔽 FIELDS (VERY COMPACT)
          TextField(
            controller: entry.nameController,
            style: const TextStyle(fontSize: 14),
            decoration: const InputDecoration(
              labelText: "Name",
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 2),
            ),
          ),

          const SizedBox(height: 2),

          if (entry.type == "item") ...[
            TextField(
              controller: entry.qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: "Quantity",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
            ),
            const SizedBox(height: 2),
            TextField(
              controller: entry.rentController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: "Rent Price",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
            ),
          ],

          if (entry.type == "service") ...[
            TextField(
              controller: entry.servicePriceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14),
              decoration: const InputDecoration(
                labelText: "Service Price",
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> saveAll() async {
    final service = InventoryService();

    /// ❗ CHECK EMPTY ROWS (STRICT)
    for (var e in entries) {
      final name = e.nameController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Remove or fill all rows")),
        );
        return;
      }

      if (e.type == "item") {
        if (e.qtyController.text.isEmpty || e.rentController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fill all fields for item: $name")),
          );
          return;
        }
      }

      if (e.type == "service") {
        if (e.servicePriceController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Fill all fields for service: $name")),
          );
          return;
        }
      }
    }

    /// ❗ DUPLICATE CHECK (UI)
    final seen = <String>{};

    for (var e in entries) {
      final key = "${e.type}_${e.nameController.text.trim().toLowerCase()}";

      if (seen.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Duplicate in list: ${e.nameController.text}")),
        );
        return;
      }

      seen.add(key);
    }

    setState(() => isLoading = true);

    try {
      /// ❗ CHECK DB DUPLICATES FIRST
      for (var e in entries) {
        final exists = await service.nodeExists(
          name: e.nameController.text,
          type: e.type,
          parentId: widget.parentId,
        );

        if (exists) {
          throw Exception("${e.type} exists: ${e.nameController.text}");
        }
      }

      /// ✅ SAVE ALL
      for (var e in entries) {
        final name = e.nameController.text;

        if (e.type == "category") {
          await service.addCategory(
            name: name,
            parentId: widget.parentId,
          );
        } else if (e.type == "item") {
          await service.addItem(
            name: name,
            quantity: int.parse(e.qtyController.text),
            rentPrice: double.parse(e.rentController.text),
            parentId: widget.parentId,
            description: "",
            imageUrl: null,
          );
        } else if (e.type == "service") {
          await service.addService(
            name: name,
            price: double.parse(e.servicePriceController.text),
            description: "",
            imageUrls: [],
            parentId: widget.parentId,
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Inventory added successfully")),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceAll("Exception:", "").trim(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text("Quick Add Multiple"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: entries.length,
              itemBuilder: (_, index) => buildRow(index),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 42, // ✅ thin button
                    child: ElevatedButton.icon(
                      onPressed: addRow,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text("Add Row"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 42, // ✅ thin button
                    child: ElevatedButton(
                      onPressed: isLoading ? null : saveAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4FA3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: EdgeInsets.zero,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text("Save All"),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
