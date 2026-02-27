import 'package:flutter/material.dart';

class ItemDetailScreen extends StatelessWidget {

  final Map<String, dynamic> itemData;

  const ItemDetailScreen({
    super.key,
    required this.itemData,
  });

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(itemData['name']),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            Text(
              "Total Quantity: ${itemData['quantity']}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 10),

            Text(
              "Rent Price: ₹${itemData['rentPrice']}",
              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            Text(
              "Description:",
              style: const TextStyle(
                  fontWeight: FontWeight.bold),
            ),

            Text(
              itemData['description'] ?? "-",
            ),
          ],
        ),
      ),
    );
  }
}