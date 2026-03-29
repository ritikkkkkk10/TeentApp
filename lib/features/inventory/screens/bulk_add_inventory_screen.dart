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
  State<BulkAddInventoryScreen> createState() =>
      _BulkAddInventoryScreenState();
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

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            /// TYPE + DELETE
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: entry.type,
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
                  ),
                ),
                IconButton(
                  onPressed: () => removeRow(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                )
              ],
            ),

            const SizedBox(height: 8),

            /// NAME
            TextField(
              controller: entry.nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),

            const SizedBox(height: 8),

            /// ITEM
            if (entry.type == "item") ...[
              TextField(
                controller: entry.qtyController,
                decoration: const InputDecoration(labelText: "Quantity"),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: entry.rentController,
                decoration: const InputDecoration(labelText: "Rent Price"),
                keyboardType: TextInputType.number,
              ),
            ],

            /// SERVICE
            if (entry.type == "service") ...[
              TextField(
                controller: entry.servicePriceController,
                decoration: const InputDecoration(labelText: "Service Price"),
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
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
        if (e.qtyController.text.isEmpty ||
            e.rentController.text.isEmpty) {
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
      final key =
          "${e.type}_${e.nameController.text.trim().toLowerCase()}";

      if (seen.contains(key)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Duplicate in list: ${e.nameController.text}")),
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

          /// ADD ROW
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton.icon(
              onPressed: addRow,
              icon: const Icon(Icons.add),
              label: const Text("Add Row"),
            ),
          ),

          /// SAVE
          Padding(
            padding: const EdgeInsets.all(10),
            child: ElevatedButton(
              onPressed: isLoading ? null : saveAll,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Save All"),
            ),
          )
        ],
      ),
    );
  }
}