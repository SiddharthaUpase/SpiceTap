import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/bill_models.dart';
import '../../models/order_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class BillDetailsDialog extends StatelessWidget {
  final Bill bill;
  final _currencyFormat = NumberFormat.currency(symbol: '₹', decimalDigits: 2);
  final _dateFormat = DateFormat('dd MMM yyyy');
  final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  BillDetailsDialog({super.key, required this.bill});

  Future<void> _generateAndDownloadPdf(BuildContext context) async {
    print('Generating PDF for bill ${bill.id}');
    print('Number of orders: ${bill.orders?.length ?? 0}');

    final pdf = pw.Document();

    try {
      final fontData =
          await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);
      final fontBoldData =
          await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
      final ttfBold = pw.Font.ttf(fontBoldData);

      pdf.addPage(
        pw.MultiPage(
          // Change to MultiPage to handle multiple pages
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          theme: pw.ThemeData.withFont(
            base: ttf,
            bold: ttfBold,
          ),
          build: (context) => [
            // Return a list of widgets
            _buildHeader(),
            pw.SizedBox(height: 20),
            _buildCustomerInfo(),
            pw.SizedBox(height: 20),
            _buildOrdersTable(ttf, ttfBold),
            pw.SizedBox(height: 20),
            _buildTotal(ttfBold),
          ],
        ),
      );

      if (kIsWeb) {
        // For web, use blob and download
        final bytes = await pdf.save();
        final blob = html.Blob([bytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement()
          ..href = url
          ..style.display = 'none'
          ..download = 'bill_${bill.id.substring(0, 8)}.pdf';
        html.document.body?.children.add(anchor);
        anchor.click();
        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);
      } else {
        // For desktop (Windows, macOS)
        final output = await getApplicationDocumentsDirectory();
        final file = File('${output.path}/bill_${bill.id.substring(0, 8)}.pdf');
        await file.writeAsBytes(await pdf.save());
        await OpenFile.open(file.path);
      }
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  // Split the content into separate methods for better organization
  pw.Widget _buildHeader() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('SpiceTap',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
            pw.Text('Bill #${bill.id.substring(0, 8)}'),
            pw.Text('Generated: ${_dateTimeFormat.format(bill.generatedAt)}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Status: ${bill.status.toString().split('.').last.toUpperCase()}',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: bill.status == BillStatus.paid
                    ? PdfColors.green
                    : PdfColors.orange,
              ),
            ),
            if (bill.paidAt != null)
              pw.Text('Paid on: ${_dateTimeFormat.format(bill.paidAt!)}'),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildCustomerInfo() {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.Text(bill.customer?.name ?? 'Unknown Customer'),
          pw.Text(
              'Period: ${_dateFormat.format(bill.startDate)} - ${_dateFormat.format(bill.endDate)}'),
        ],
      ),
    );
  }

  pw.Widget _buildOrdersTable(pw.Font ttf, pw.Font ttfBold) {
    // Sort orders by date in ascending order
    final sortedOrders = List<Order>.from(bill.orders ?? [])
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _buildTableCell('Order Date', ttfBold, isHeader: true),
            _buildTableCell('Items', ttfBold, isHeader: true),
            _buildTableCell('Amount', ttfBold,
                isHeader: true, alignRight: true),
          ],
        ),
        // Data rows with sorted orders
        ...sortedOrders
            .map((order) => pw.TableRow(
                  children: [
                    _buildTableCell(
                        _dateTimeFormat.format(order.createdAt), ttf),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: order.orderItems
                                ?.map((item) => pw.Text(
                                      '${item.quantity}x ${item.menuItem?.name ?? 'Unknown Item'}',
                                      style:
                                          pw.TextStyle(font: ttf, fontSize: 9),
                                    ))
                                .toList() ??
                            [],
                      ),
                    ),
                    _buildTableCell(
                      _currencyFormat.format(order.totalAmount),
                      ttf,
                      alignRight: true,
                    ),
                  ],
                ))
            .toList(),
      ],
    );
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(5),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : null,
        ),
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
      ),
    );
  }

  pw.Widget _buildTotal(pw.Font ttfBold) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Text(
        'Total Amount: ${_currencyFormat.format(bill.totalAmount)}',
        style: pw.TextStyle(
          font: ttfBold,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill Details',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Bill #${bill.id.substring(0, 8)}',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: () => _generateAndDownloadPdf(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Download PDF'),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Customer and Date Info
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Customer',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bill.customer?.name ?? 'Unknown Customer',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Period',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${_dateFormat.format(bill.startDate)} - ${_dateFormat.format(bill.endDate)}',
                              style: GoogleFonts.poppins(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Orders List
              Expanded(
                child: Card(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: bill.orders?.length ?? 0,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, index) {
                      final sortedOrders = List<Order>.from(bill.orders ?? [])
                        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
                      final order = sortedOrders[index];
                      return ListTile(
                        title: Text(
                          _dateTimeFormat.format(order.createdAt),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: order.orderItems?.map((item) {
                                return Text(
                                  '${item.quantity}x ${item.menuItem?.name ?? 'Unknown Item'}',
                                  style: GoogleFonts.poppins(fontSize: 14),
                                );
                              }).toList() ??
                              [],
                        ),
                        trailing: Text(
                          _currencyFormat.format(order.totalAmount),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total and Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Status: ${bill.status.toString().split('.').last.toUpperCase()}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: bill.status == BillStatus.paid
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                      if (bill.paidAt != null)
                        Text(
                          'Paid on: ${_dateTimeFormat.format(bill.paidAt!)}',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                  Text(
                    'Total: ${_currencyFormat.format(bill.totalAmount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
