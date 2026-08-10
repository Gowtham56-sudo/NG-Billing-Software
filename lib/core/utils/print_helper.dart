import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/cashier/models/cart_item.dart';

class PrintHelper {
  static Future<void> printReceipt({
    required String invoiceNumber,
    required String cashierName,
    required String customerName,
    required List<CartItem> items,
    required String saleType,
    required double subtotal,
    required double gstAmount,
    required double discount,
    required double grandTotal,
    required String paymentMethod,
    PdfPageFormat format = PdfPageFormat.roll80, // Default to 80mm thermal
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                'NEXTGEN SUPERMARKET',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              pw.Text('123 Main Street, City'),
              pw.Text('GSTIN: 29ABCDE1234F1Z5'),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill No: $invoiceNumber'),
                  pw.Text(
                    'Date: ${DateTime.now().toString().substring(0, 10)}',
                  ),
                ],
              ),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Cashier: $cashierName'),
                  pw.Text('Customer: $customerName'),
                ],
              ),
              pw.Divider(),
              // Table Header
              pw.Row(
                children: [
                  pw.Expanded(flex: 3, child: pw.Text('Item')),
                  pw.Expanded(flex: 1, child: pw.Text('Qty')),
                  pw.Expanded(flex: 2, child: pw.Text('Price')),
                  pw.Expanded(
                    flex: 2,
                    child: pw.Text('Total', textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              pw.Divider(),
              // Items
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      pw.Expanded(flex: 3, child: pw.Text(item.product.name)),
                      pw.Expanded(
                        flex: 1,
                        child: pw.Text(item.quantity.toStringAsFixed(1)),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.getPrice(saleType).toStringAsFixed(2),
                        ),
                      ),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          item.getNetAmount(saleType).toStringAsFixed(2),
                          textAlign: pw.TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              // Totals
              _buildTotalRow('Subtotal', subtotal),
              _buildTotalRow('Discount', discount),
              _buildTotalRow('GST', gstAmount),
              pw.Divider(),
              _buildTotalRow(
                'GRAND TOTAL',
                grandTotal,
                isBold: true,
                fontSize: 16,
              ),
              pw.Divider(),
              pw.SizedBox(height: 10),
              pw.Text('Payment Method: $paymentMethod'),
              pw.SizedBox(height: 10),
              pw.Text(
                '*** THANK YOU ***',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 5),
              pw.BarcodeWidget(
                barcode: pw.Barcode.qrCode(),
                data: 'INV:$invoiceNumber|AMT:$grandTotal',
                width: 60,
                height: 60,
              ),
            ],
          );
        },
      ),
    );

    // Direct print without showing dialog
    try {
      final printers = await Printing.listPrinters();
      if (printers.isEmpty) {
        throw Exception('No printers found on this system');
      }

      // Try to find the default printer, otherwise use the first available one
      final targetPrinter = printers.firstWhere(
        (p) => p.isDefault,
        orElse: () => printers.first,
      );

      await Printing.directPrintPdf(
        printer: targetPrinter,
        onLayout: (PdfPageFormat defaultFormat) async => pdf.save(),
        name: 'Receipt_$invoiceNumber',
      );
    } catch (e) {
      throw Exception('Failed to print directly: $e');
    }
  }

  static pw.Widget _buildTotalRow(
    String label,
    double amount, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
          pw.Text(
            amount.toStringAsFixed(2),
            style: pw.TextStyle(
              fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
