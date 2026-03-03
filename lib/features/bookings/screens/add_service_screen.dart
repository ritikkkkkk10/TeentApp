import 'package:flutter/material.dart';
import 'package:tent_app/features/inventory/services/inventory_service.dart';

class AddServiceScreen extends StatefulWidget {

  final String? parentId;

  const AddServiceScreen({
    super.key,
    this.parentId,
  });

  @override
  State<AddServiceScreen> createState() =>
      _AddServiceScreenState();
}

class _AddServiceScreenState
    extends State<AddServiceScreen> {

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController descController =
      TextEditingController();

  bool isLoading = false;

  Future<void> saveService() async {

    if (nameController.text.isEmpty ||
        priceController.text.isEmpty) {
      return;
    }

    setState(() => isLoading = true);

    final service = InventoryService();

    await service.addService(
      name: nameController.text,
      price: double.parse(priceController.text),
      description: descController.text,
      parentId: widget.parentId,
    );

    setState(() => isLoading = false);

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(
                      labelText: "Service Name"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priceController,
              keyboardType:
                  TextInputType.number,
              decoration:
                  const InputDecoration(
                      labelText: "Price"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration:
                  const InputDecoration(
                      labelText: "Description"),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    isLoading ? null : saveService,
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white)
                    : const Text("Save Service"),
              ),
            )
          ],
        ),
      ),
    );
  }
}