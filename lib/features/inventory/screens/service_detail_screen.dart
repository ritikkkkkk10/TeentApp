import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tent_app/core/config/app_config.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';

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

      final ImagePicker _picker = ImagePicker();

  List<String> imageUrls = [];
  List<File> newImages = [];

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

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
    widget.serviceData["imageUrls"] ?? [],
  );
}

  Future<void> updateService() async {

  String businessId = await getBusinessId();

  List<String> updatedImages = List.from(imageUrls);

  /// upload new images
  for (File file in newImages) {

    String? url =
        await CloudinaryService.uploadImage(file);

    if (url != null) {
      updatedImages.add(url);
    }
  }

  await FirebaseFirestore.instance
      .collection("businesses")
      .doc(businessId)
      .collection("inventoryNodes")
      .doc(widget.serviceId)
      .update({
    "name": nameController.text,
    "price": double.parse(priceController.text),
    "description": descController.text,
    "imageUrls": updatedImages,
  });

  Navigator.pop(context);
}

  Future<void> pickImage() async {

  if (imageUrls.length + newImages.length >= 5) {
    return;
  }

  final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  File file = File(picked.path);

  File? compressed = await compressImage(file);

  if (compressed != null) {
    setState(() {
      newImages.add(compressed);
    });
  }
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
if (imageUrls.isNotEmpty || newImages.isNotEmpty)
SizedBox(
  height: 220,
  child: PageView(
    children: [

      /// Existing images
      ...imageUrls.map((url) {
        return Stack(
          children: [

            Positioned.fill(
              child: Image.network(
                url,
                fit: BoxFit.cover,
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    imageUrls.remove(url);
                  });
                },
              ),
            ),
          ],
        );
      }),

      /// Newly added images
      ...newImages.map((file) {
        return Stack(
          children: [

            Positioned.fill(
              child: Image.file(
                file,
                fit: BoxFit.cover,
              ),
            ),

            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                onPressed: () {
                  setState(() {
                    newImages.remove(file);
                  });
                },
              ),
            ),
          ],
        );
      }),
    ],
  ),
),

const SizedBox(height: 16),

ElevatedButton(
  onPressed: pickImage,
  child: const Text("Add Photo"),
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