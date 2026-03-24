import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> generateInvoice(
  BuildContext context, {
    required bool isPreview, 
  /// BUSINESS
  required String businessName,
  required String ownerName,
  required String businessPhone,
  required String businessAddress,
  String? gst,

  /// CUSTOMER
  required String customerName,
  required String customerPhone,
  required String customerAddress,

  /// EVENT
  required String eventName,
  required DateTime startDate,
  required DateTime endDate,

  /// ITEMS & SERVICES
  required List<Map<String, dynamic>> items,
  required List<Map<String, dynamic>> services,

  /// PAYMENT
  required double total,
  required double paid,
}) async {
  final pdf = pw.Document();

  String formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) {
  return [
    pw.Padding(
          padding: const pw.EdgeInsets.all(20),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [

              /// BUSINESS HEADER
              pw.Text(
                businessName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text("Owner: $ownerName"),
              pw.Text("Phone: $businessPhone"),
              pw.Text("Address: $businessAddress"),

              if (gst != null && gst.isNotEmpty)
                pw.Text("GST: $gst"),

              pw.SizedBox(height: 20),

              /// INVOICE TITLE
              pw.Center(
                child: pw.Text(
                  "INVOICE",
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),

              pw.SizedBox(height: 20),

              /// EVENT
              pw.Text("Event: $eventName"),
              pw.Text("Start Date: ${formatDate(startDate)}"),

              if (startDate != endDate)
                pw.Text("End Date: ${formatDate(endDate)}"),

              pw.SizedBox(height: 20),

              /// CUSTOMER
              pw.Text(
                "Bill To",
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),

              pw.Text("Customer: $customerName"),
              pw.Text("Phone: $customerPhone"),
              pw.Text("Address: $customerAddress"),

              pw.SizedBox(height: 20),

              /// ITEMS
              pw.Text(
                "Items",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),

              pw.Table.fromTextArray(
                headers: ["Item", "Qty", "Price", "Total"],
                data: items.map((item) {
                  int requested = item["requested"] ?? 0;
                  int dispatched = item["dispatched"] ?? 0;

                  int qty = dispatched > 0 ? dispatched : requested;

                  double price = (item["price"] as num).toDouble();

                  return [
                    item["name"],
                    qty.toString(),
                    price.toStringAsFixed(2),
                    (qty * price).toStringAsFixed(2),
                  ];
                }).toList(),
              ),

              pw.SizedBox(height: 20),

              /// SERVICES
              if (services.isNotEmpty) ...[
                pw.Text(
                  "Services",
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),

                pw.Table.fromTextArray(
                  headers: ["Service", "Price"],
                  data: services.map((service) {
                    return [
                      service["name"],
                      (service["price"] as num).toDouble().toStringAsFixed(2),
                    ];
                  }).toList(),
                ),

                pw.SizedBox(height: 20),
              ],

              /// PAYMENT SUMMARY
              pw.Divider(),

              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text("Total: Rs ${total.toStringAsFixed(2)}"),
                    pw.Text("Paid: Rs ${paid.toStringAsFixed(2)}"),
                    pw.Text(
                      "Remaining: Rs ${(total - paid).toStringAsFixed(2)}",
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ];
      },
    ),
  );

if (isPreview) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text("Invoice")),
        body: PdfPreview(
          build: (format) async => pdf.save(),
        ),
      ),
    ),
  );
} else {
  final output = await getTemporaryDirectory();
  final file = File(
      "${output.path}/invoice_${DateTime.now().millisecondsSinceEpoch}.pdf");

  await file.writeAsBytes(await pdf.save());

  await Share.shareXFiles(
    [XFile(file.path)],
    text: "Invoice for your booking",
  );
}
}