import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRInventoryDialog extends StatelessWidget {
  final String url;

  const QRInventoryDialog({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text("Scan to View Inventory"),
      content: SizedBox(
        width: 250,
        height: 280,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: QrImageView(
                  data: url,
                  version: QrVersions.auto,
                  size: 200,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SelectableText(
              url,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        )
      ],
    );
  }
}