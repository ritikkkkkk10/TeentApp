import 'package:flutter/material.dart';
import 'package:tent_app/features/inventory/services/inventory_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cloudinary_service.dart';
import '../../../core/utils/image_compressor.dart';

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

  final ImagePicker _picker = ImagePicker();

  List<File> selectedImages = [];
  List<String> uploadedUrls = [];

  final TextEditingController nameController =
      TextEditingController();

  final TextEditingController priceController =
      TextEditingController();

  final TextEditingController descController =
      TextEditingController();

  bool isLoading = false;


  Future<void> pickImage() async {

  if (selectedImages.length >= 5) return;

  final XFile? picked =
      await _picker.pickImage(source: ImageSource.gallery);

  if (picked == null) return;

  File file = File(picked.path);

  File? compressed = await compressImage(file);

  if (compressed != null) {

    setState(() {
      selectedImages.add(compressed);
    });

  }
}

Future<void> uploadImages() async {

  uploadedUrls.clear();

  for (File file in selectedImages) {

    String? url =
        await CloudinaryService.uploadImage(file);

    if (url != null) {
      uploadedUrls.add(url);
    }
  }
}

  Future<void> saveService() async {

  if (nameController.text.isEmpty ||
      priceController.text.isEmpty) {
    return;
  }

  setState(() => isLoading = true);

  await uploadImages();

  final service = InventoryService();

  await service.addService(
    name: nameController.text,
    price: double.parse(priceController.text),
    description: descController.text,
    imageUrls: uploadedUrls,
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

const SizedBox(height: 16),

/// ADD PHOTO BUTTON
ElevatedButton(
  onPressed: pickImage,
  child: const Text("Add Photo (Max 5)"),
),

const SizedBox(height: 16),

/// IMAGE PREVIEW SLIDER
if (selectedImages.isNotEmpty)
SizedBox(
  height: 200,
  child: PageView.builder(
    itemCount: selectedImages.length,
    itemBuilder: (context, index) {

      return Padding(
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            selectedImages[index],
            fit: BoxFit.cover,
          ),
        ),
      );
    },
  ),
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