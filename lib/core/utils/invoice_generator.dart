import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> generateInvoice({
  required String customerName,
  required String phone,
  required String eventName,
  required List<Map<String, dynamic>> items,
  required List<Map<String, dynamic>> services,
  required double total,
  required double paid,
}) async {

  final pdf = pw.Document();

  pdf.addPage(
    pw.Page(
      build: (pw.Context context) {

        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [

            pw.Text(
              "INVOICE",
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),

            pw.SizedBox(height: 20),

            pw.Text("Customer: $customerName"),
            pw.Text("Phone: $phone"),
            pw.Text("Event: $eventName"),

            pw.SizedBox(height: 20),

            pw.Text("Items",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

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
      price.toString(),
      (qty * price).toString(),
    ];

  }).toList(),
),

            pw.SizedBox(height: 20),

            pw.Text("Services",
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),

            pw.Table.fromTextArray(
              headers: ["Service", "Price"],
              data: services.map((service) {
                return [
                  service["name"],
                  service["price"].toString(),
                ];
              }).toList(),
            ),

            pw.SizedBox(height: 20),

            pw.Text("Total: ₹$total"),
            pw.Text("Paid: ₹$paid"),
            pw.Text("Remaining: ₹${total - paid}"),
          ],
        );
      },
    ),
  );

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
  );
}