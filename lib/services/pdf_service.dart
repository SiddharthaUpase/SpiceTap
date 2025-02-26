import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import '../models/order_models.dart';
import '../models/credit_customer.dart';
import 'package:universal_html/html.dart' as html;

class PdfService {
  Future<void> generateOrdersReport({
    required List<Order> orders,
    required String canteenName,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();

    try {
      // Load font
      final fontData =
          await rootBundle.load("assets/fonts/Poppins-Regular.ttf");
      final ttf = pw.Font.ttf(fontData);

      final fontBoldData =
          await rootBundle.load("assets/fonts/Poppins-Bold.ttf");
      final ttfBold = pw.Font.ttf(fontBoldData);

      // Format dates
      final dateFormat = DateFormat('MMM d, yyyy');
      final dateTimeFormat = DateFormat('MMM d, yyyy h:mm a');

      // Calculate totals
      final totalAmount =
          orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
      final paidAmount = orders
          .where((o) => o.paymentStatus == PaymentStatus.paid)
          .fold<double>(0, (sum, order) => sum + order.totalAmount);
      final pendingAmount = totalAmount - paidAmount;

      // Add header
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                canteenName,
                style: pw.TextStyle(
                  font: ttfBold,
                  fontSize: 24,
                  color: PdfColors.deepOrange,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Orders Report',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 16,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                style: pw.TextStyle(
                  font: ttf,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Divider(),
            ],
          ),
          footer: (context) => pw.Column(
            children: [
              pw.Divider(),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Generated on ${dateTimeFormat.format(DateTime.now())}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ],
          ),
          build: (context) => [
            // Summary section
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Summary',
                    style: pw.TextStyle(
                      font: ttfBold,
                      fontSize: 16,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    children: [
                      _buildSummaryItem(
                        title: 'Total Orders',
                        value: orders.length.toString(),
                        font: ttf,
                        boldFont: ttfBold,
                      ),
                      _buildSummaryItem(
                        title: 'Total Amount',
                        value: '₹${totalAmount.toStringAsFixed(2)}',
                        font: ttf,
                        boldFont: ttfBold,
                      ),
                      _buildSummaryItem(
                        title: 'Paid Amount',
                        value: '₹${paidAmount.toStringAsFixed(2)}',
                        font: ttf,
                        boldFont: ttfBold,
                        valueColor: PdfColors.green700,
                      ),
                      _buildSummaryItem(
                        title: 'Pending Amount',
                        value: '₹${pendingAmount.toStringAsFixed(2)}',
                        font: ttf,
                        boldFont: ttfBold,
                        valueColor: PdfColors.orange700,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 24),

            // Orders table
            pw.Text(
              'Orders',
              style: pw.TextStyle(
                font: ttfBold,
                fontSize: 16,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey300,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Order ID
                1: const pw.FlexColumnWidth(2), // Customer
                2: const pw.FlexColumnWidth(2), // Date & Time
                3: const pw.FlexColumnWidth(1.5), // Amount
                4: const pw.FlexColumnWidth(1), // Status
              },
              children: [
                // Table header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableHeader('Order ID', ttfBold),
                    _buildTableHeader('Customer', ttfBold),
                    _buildTableHeader('Date & Time', ttfBold),
                    _buildTableHeader('Amount', ttfBold),
                    _buildTableHeader('Status', ttfBold),
                  ],
                ),
                // Table rows
                ...orders.map((order) {
                  final customer = order.customer;
                  String shopNumber = '';
                  if (customer is CreditCustomer &&
                      customer.shopNumbers.isNotEmpty) {
                    shopNumber = customer.shopNumbers.first;
                  }

                  return pw.TableRow(
                    children: [
                      _buildTableCell(
                        '#${order.id.substring(0, 8)}',
                        ttf,
                      ),
                      _buildTableCell(
                        '${customer?.name ?? 'Unknown'}\n${shopNumber.isNotEmpty ? 'Shop: $shopNumber' : ''}',
                        ttf,
                      ),
                      _buildTableCell(
                        dateTimeFormat.format(order.createdAt),
                        ttf,
                      ),
                      _buildTableCell(
                        '₹${order.totalAmount.toStringAsFixed(2)}',
                        ttf,
                      ),
                      _buildTableCell(
                        order.paymentStatus == PaymentStatus.paid
                            ? 'Paid'
                            : 'Pending',
                        ttf,
                        textColor: order.paymentStatus == PaymentStatus.paid
                            ? PdfColors.green700
                            : PdfColors.orange700,
                      ),
                    ],
                  );
                }).toList(),
              ],
            ),

            // Order details
            ...orders.map((order) {
              final customer = order.customer;
              String shopNumber = '';
              if (customer is CreditCustomer &&
                  customer.shopNumbers.isNotEmpty) {
                shopNumber = customer.shopNumbers.first;
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(height: 24),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: pw.TextStyle(
                                font: ttfBold,
                                fontSize: 14,
                              ),
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: pw.BoxDecoration(
                                color: order.paymentStatus == PaymentStatus.paid
                                    ? PdfColors.green50
                                    : PdfColors.orange50,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                order.paymentStatus == PaymentStatus.paid
                                    ? 'Paid'
                                    : 'Pending',
                                style: pw.TextStyle(
                                  font: ttf,
                                  fontSize: 10,
                                  color:
                                      order.paymentStatus == PaymentStatus.paid
                                          ? PdfColors.green700
                                          : PdfColors.orange700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          dateTimeFormat.format(order.createdAt),
                          style: pw.TextStyle(
                            font: ttf,
                            fontSize: 10,
                            color: PdfColors.grey700,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Divider(color: PdfColors.grey300),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Expanded(
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(
                                    'Customer',
                                    style: pw.TextStyle(
                                      font: ttf,
                                      fontSize: 10,
                                      color: PdfColors.grey700,
                                    ),
                                  ),
                                  pw.Text(
                                    customer?.name ?? 'Unknown',
                                    style: pw.TextStyle(
                                      font: ttfBold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (shopNumber.isNotEmpty)
                                    pw.Text(
                                      'Shop: $shopNumber',
                                      style: pw.TextStyle(
                                        font: ttf,
                                        fontSize: 10,
                                        color: PdfColors.grey700,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.end,
                              children: [
                                pw.Text(
                                  'Amount',
                                  style: pw.TextStyle(
                                    font: ttf,
                                    fontSize: 10,
                                    color: PdfColors.grey700,
                                  ),
                                ),
                                pw.Text(
                                  '₹${order.totalAmount.toStringAsFixed(2)}',
                                  style: pw.TextStyle(
                                    font: ttfBold,
                                    fontSize: 14,
                                    color: PdfColors.deepOrange,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Order items
                        if (order.orderItems != null &&
                            order.orderItems!.isNotEmpty) ...[
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Items',
                            style: pw.TextStyle(
                              font: ttf,
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          ...order.orderItems!.map((item) => pw.Padding(
                                padding:
                                    const pw.EdgeInsets.symmetric(vertical: 2),
                                child: pw.Row(
                                  children: [
                                    pw.Text(
                                      '${item.quantity}x',
                                      style: pw.TextStyle(
                                        font: ttfBold,
                                        fontSize: 10,
                                      ),
                                    ),
                                    pw.SizedBox(width: 8),
                                    pw.Expanded(
                                      child: pw.Text(
                                        item.menuItem!.name,
                                        style: pw.TextStyle(
                                          font: ttf,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                    pw.Text(
                                      '₹${item.totalPrice.toStringAsFixed(2)}',
                                      style: pw.TextStyle(
                                        font: ttf,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ],
        ),
      );

      // For web, use blob and download
      final bytes = await pdf.save();
      final blob = html.Blob([bytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement()
        ..href = url
        ..style.display = 'none'
        ..download =
            'orders_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error generating PDF: $e');
      rethrow;
    }
  }

  pw.Widget _buildSummaryItem({
    required String title,
    required String value,
    required pw.Font font,
    required pw.Font boldFont,
    PdfColor valueColor = PdfColors.black,
  }) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 10,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              font: boldFont,
              fontSize: 14,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
        ),
      ),
    );
  }

  pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    PdfColor textColor = PdfColors.black,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 9,
          color: textColor,
        ),
      ),
    );
  }
}
