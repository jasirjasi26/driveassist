import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/trip.dart';

class PdfService {
  /// Generates a PDF document for a specific trip and opens the system print/share sheet.
  static Future<void> exportTripPdf(Trip trip) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(trip.date);
    final durationStr = _formatDuration(trip.durationSeconds);

    // Custom theme styling
    final primaryColor = PdfColor.fromHex('#00B0FF');
    final secondaryColor = PdfColor.fromHex('#1E2530');
    final criticalColor = PdfColor.fromHex('#FF2A6D');
    final warningColor = PdfColor.fromHex('#FF8C00');
    final successColor = PdfColor.fromHex('#00E5FF');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'DriveAssist AI',
                          style: pw.TextStyle(
                            fontSize: 28,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        pw.Text(
                          'Advanced Driver Assistance System',
                          style: const pw.TextStyle(
                            fontSize: 10,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('TRIP REPORT',
                            style: pw.TextStyle(
                                fontSize: 14, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Date: $dateStr',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Trip ID: ${trip.id.substring(0, 8)}...',
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey500)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 2, color: primaryColor),
                pw.SizedBox(height: 20),

                // Driving Score Summary Card
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius:
                        const pw.BorderRadius.all(pw.Radius.circular(8)),
                    border: pw.Border.all(color: PdfColors.grey300),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'DRIVING SAFETY SCORE',
                            style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: secondaryColor),
                          ),
                          pw.SizedBox(height: 8),
                          pw.Row(
                            children: [
                              pw.Text(
                                '${trip.score}',
                                style: pw.TextStyle(
                                  fontSize: 48,
                                  fontWeight: pw.FontWeight.bold,
                                  color: trip.score >= 85
                                      ? PdfColors.green
                                      : trip.score >= 70
                                          ? PdfColors.orange
                                          : PdfColors.red,
                                ),
                              ),
                              pw.Text(' / 100',
                                  style: const pw.TextStyle(
                                      fontSize: 16, color: PdfColors.grey600)),
                            ],
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            trip.score >= 85
                                ? 'EXCELLENT SAFETY'
                                : trip.score >= 70
                                    ? 'AVERAGE SAFETY'
                                    : 'UNSAFE - ATTENTION REQUIRED',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: trip.score >= 85
                                  ? PdfColors.green
                                  : trip.score >= 70
                                      ? PdfColors.orange
                                      : PdfColors.red,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Based on tailgating, overspeeding,\nhard braking and lane drift events.',
                            textAlign: pw.TextAlign.right,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.grey600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 24),

                // Trip Metrics
                pw.Text('TRIP METRICS',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor)),
                pw.SizedBox(height: 8),
                pw.GridView(
                  crossAxisCount: 2,
                  childAspectRatio: 0.35,
                  children: [
                    _buildMetricRow('Distance Driven:',
                        '${trip.distance.toStringAsFixed(2)} km'),
                    _buildMetricRow('Duration:', durationStr),
                    _buildMetricRow('Average Speed:',
                        '${trip.avgSpeed.toStringAsFixed(1)} km/h'),
                    _buildMetricRow('Maximum Speed:',
                        '${trip.maxSpeed.toStringAsFixed(1)} km/h'),
                    _buildMetricRow(
                        'Hard Braking Events:', '${trip.hardBrakingCount}'),
                    _buildMetricRow('Sudden Accelerations:',
                        '${trip.suddenAccelerationCount}'),
                    _buildMetricRow(
                        'Tailgating Duration:', '${trip.tailgatingSeconds} s'),
                    _buildMetricRow(
                        'Lane Departures:', '${trip.laneDepartureCount}'),
                  ],
                ),
                pw.SizedBox(height: 24),

                // Warnings Breakdown
                pw.Text('SAFETY WARNINGS LOG',
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: secondaryColor)),
                pw.SizedBox(height: 8),

                if (trip.warnings.isEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(6)),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'Perfect Drive! No safety warnings triggered.',
                        style: pw.TextStyle(
                            color: PdfColors.green700,
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 10),
                      ),
                    ),
                  )
                else
                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300),
                    children: [
                      // Table Header
                      pw.TableRow(
                        decoration:
                            const pw.BoxDecoration(color: PdfColors.grey200),
                        children: [
                          _buildTableHeaderCell('Time'),
                          _buildTableHeaderCell('Alert Type'),
                          _buildTableHeaderCell('Details'),
                          _buildTableHeaderCell('Speed'),
                        ],
                      ),
                      // Table Rows
                      ...trip.warnings.map((w) {
                        final timeStr =
                            DateFormat('HH:mm:ss').format(w.timestamp);
                        return pw.TableRow(
                          children: [
                            _buildTableCell(timeStr),
                            _buildTableCell(w.type.toUpperCase(), isBold: true),
                            _buildTableCell(w.message),
                            _buildTableCell(
                                '${w.speed.toStringAsFixed(0)} km/h'),
                          ],
                        );
                      }),
                    ],
                  ),

                pw.Spacer(),
                // Footer details
                pw.Divider(thickness: 1, color: PdfColors.grey300),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Generated by DriveAssist AI App',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                    pw.Text(
                        'Drive Safely. DriveAssist AI is an advisory dashboard tool.',
                        style: const pw.TextStyle(
                            fontSize: 8, color: PdfColors.grey500)),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );

    // Render & Share
    try {
      final pdfBytes = await pdf.save();
      await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'driveassist_trip_${trip.id.substring(0, 6)}.pdf');
    } catch (e) {
      print("Error generating PDF: $e");
    }
  }

  static pw.Widget _buildMetricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
          pw.Text(value,
              style:
                  pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.black),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
            fontSize: 8,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
      ),
    );
  }

  static String _formatDuration(int seconds) {
    final int hours = seconds ~/ 3600;
    final int minutes = (seconds % 3600) ~/ 60;
    final int remainingSeconds = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${remainingSeconds}s';
    } else {
      return '${remainingSeconds}s';
    }
  }
}
