import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';

class ServiceDetailScreen extends StatefulWidget {

  final Map<String, dynamic> serviceData;
  final String serviceId;

  const ServiceDetailScreen({
    super.key,
    required this.serviceData,
    required this.serviceId,
  });

  @override
  State<ServiceDetailScreen> createState() =>
      _ServiceDetailScreenState();
}

class _ServiceDetailScreenState
    extends State<ServiceDetailScreen> {

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;
  List<String> imageUrls = [];

  @override
void initState() {
  super.initState();

  nameController =
      TextEditingController(text: widget.serviceData["name"]);

  priceController =
      TextEditingController(
          text: widget.serviceData["price"].toString());

  descController =
      TextEditingController(
          text: widget.serviceData["description"] ?? "");

  imageUrls = List<String>.from(
      widget.serviceData["imageUrls"] ?? []);
}

  Future<void> updateService() async {

    String businessId = await getBusinessId();

    await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("inventoryNodes")
        .doc(widget.serviceId)
        .update({
      "name": nameController.text,
      "price": double.parse(priceController.text),
      "description": descController.text,
    });

    Navigator.pop(context);
  }

  Future<void> deleteService() async {

    String businessId = await getBusinessId();

    await FirebaseFirestore.instance
        .collection("businesses")
        .doc(businessId)
        .collection("inventoryNodes")
        .doc(widget.serviceId)
        .delete();

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Service Details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            TextField(
              controller: nameController,
              decoration:
                  const InputDecoration(labelText: "Service Name"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: "Price"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descController,
              maxLines: 3,
              decoration:
                  const InputDecoration(labelText: "Description"),
            ),

            const SizedBox(height: 16),

/// IMAGE PREVIEW
if (imageUrls.isNotEmpty)
SizedBox(
  height: 220,
  child: PageView.builder(
    itemCount: imageUrls.length,
    itemBuilder: (context, index) {

      return Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            imageUrls[index],
            fit: BoxFit.cover,
          ),
        ),
      );
    },
  ),
),

const SizedBox(height: 24),

            ElevatedButton(
              onPressed: updateService,
              child: const Text("Update"),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              onPressed: deleteService,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        ),
      ),
    );
  }
}