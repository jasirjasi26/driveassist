import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme/app_theme.dart';
import '../models/trip.dart';
import '../services/pdf_service.dart';
import '../services/storage_service.dart';
import '../widgets/glass_container.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final StorageService _storage = StorageService();
  List<Trip> _trips = [];

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  void _loadTrips() {
    setState(() {
      _trips = _storage.getTrips();
    });
  }

  void _deleteTrip(String id) async {
    await _storage.deleteTrip(id);
    _loadTrips();
  }

  void _clearAllHistory() async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Logs?'),
        content: const Text('Are you sure you want to permanently delete all logged trip records? This cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.neonCrimson),
            child: const Text('DELETE ALL'),
            onPressed: () async {
              Navigator.pop(ctx);
              await _storage.clearTripHistory();
              _loadTrips();
            },
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top control bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text('JOURNEYS LOG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: AppTheme.neonCrimson),
                      onPressed: _trips.isEmpty ? null : _clearAllHistory,
                    ),
                  ],
                ),
                
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 12),
                      
                      // 1. Line Chart Trend of Safety Score
                      if (_trips.isNotEmpty) ...[
                        Text(
                          'SAFETY SCORE TREND',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4), letterSpacing: 1.0),
                        ),
                        const SizedBox(height: 8),
                        _buildSafetyScoreLineChart(),
                        const SizedBox(height: 24),
                      ],

                      // 2. Trips List
                      Text(
                        'HISTORY LIST',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      
                      if (_trips.isEmpty)
                        _buildEmptyState()
                      else
                        ..._trips.map((trip) => _buildTripCard(trip)),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildSafetyScoreLineChart() {
    // Collect last 6 scores (reverse for chronological order left-to-right)
    final trendTrips = _trips.take(6).toList().reversed.toList();
    
    List<FlSpot> spots = [];
    for (int i = 0; i < trendTrips.length; i++) {
      spots.add(FlSpot(i.toDouble(), trendTrips[i].score.toDouble()));
    }

    return GlassContainer(
      opacity: 0.08,
      borderRadius: 24,
      height: 180,
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 16, right: 24),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int idx = value.toInt();
                  if (idx >= 0 && idx < trendTrips.length) {
                    final date = trendTrips[idx].date;
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${date.month}/${date.day}',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 20,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 8, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: max(1.0, (trendTrips.length - 1).toDouble()),
          minY: 40,
          maxY: 100,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.electricTeal,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                  radius: 4,
                  color: AppTheme.electricTeal,
                  strokeWidth: 1.5,
                  strokeColor: Colors.black,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.electricTeal.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 500.ms).scaleY(begin: 0.95);
  }

  Widget _buildTripCard(Trip trip) {
    final scoreColor = trip.score >= 85
        ? AppTheme.electricTeal
        : trip.score >= 70
            ? AppTheme.warningOrange
            : AppTheme.neonCrimson;

    final dateStr = '${trip.date.year}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.day.toString().padLeft(2, '0')} ${trip.date.hour.toString().padLeft(2, '0')}:${trip.date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 20,
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: () => _showTripDetailsSheet(trip),
          child: Row(
            children: [
              // Score Indicator Circle
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: scoreColor, width: 2),
                  color: scoreColor.withOpacity(0.06),
                ),
                child: Center(
                  child: Text(
                    '${trip.score}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: scoreColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Summary
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${trip.distance.toStringAsFixed(1)} km  •  ${_formatDuration(trip.durationSeconds)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              IconButton(
                icon: Icon(Icons.picture_as_pdf, color: Colors.white.withOpacity(0.4)),
                onPressed: () => PdfService.exportTripPdf(trip),
              ),
              const Icon(Icons.arrow_right, color: Colors.white30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassContainer(
      opacity: 0.04,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_toggle_off, size: 48, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 16),
            Text(
              'No Journeys Logged Yet',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All driving logs will reside here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TRIP DETAILS BOTTOM SHEET ---

  void _showTripDetailsSheet(Trip trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scoreColor = trip.score >= 85
            ? AppTheme.electricTeal
            : trip.score >= 70
                ? AppTheme.warningOrange
                : AppTheme.neonCrimson;
                
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.darkBlueGray.withOpacity(0.95),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: const Border(
              top: BorderSide(color: AppTheme.glassBorder, width: 0.8),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bottom sheet drag indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'JOURNEY LOG SUMMARY',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppTheme.neonCrimson),
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteTrip(trip.id);
                    },
                  )
                ],
              ),
              const Divider(color: AppTheme.glassBorder),
              const SizedBox(height: 12),

              // Score Card Row
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: scoreColor, width: 2.5),
                    ),
                    child: Center(
                      child: Text(
                        '${trip.score}',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: scoreColor),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.score >= 85
                              ? 'EXCELLENT RUN'
                              : trip.score >= 70
                                  ? 'MODERATE PERFORMANCE'
                                  : 'CRITICAL ATTENTION REQUIRED',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scoreColor),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Average trip speed of ${trip.avgSpeed.toStringAsFixed(1)} km/h over ${trip.distance.toStringAsFixed(2)} kilometers.',
                          style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5), height: 1.3),
                        ),
                      ],
                    ),
                  )
                ],
              ),

              const SizedBox(height: 24),

              // Telemetry stats grid
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSheetMetric('DURATION', _formatDuration(trip.durationSeconds)),
                  _buildSheetMetric('MAX SPEED', '${trip.maxSpeed.toStringAsFixed(0)} km/h'),
                  _buildSheetMetric('ALERTS', '${trip.warnings.length}'),
                ],
              ),

              const SizedBox(height: 24),

              // Safety details table
              const Text('SAFETY REPORT LOG', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white54)),
              const SizedBox(height: 8),
              
              Table(
                children: [
                  _buildSheetTableRow('Tailgating events:', '${trip.tailgatingSeconds} seconds'),
                  _buildSheetTableRow('Hard braking incidents:', '${trip.hardBrakingCount}'),
                  _buildSheetTableRow('Sudden accelerations:', '${trip.suddenAccelerationCount}'),
                  _buildSheetTableRow('Lane drift departures:', '${trip.laneDepartureCount}'),
                ],
              ),

              const SizedBox(height: 32),

              // Share PDF Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.electricTeal,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    PdfService.exportTripPdf(trip);
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('EXPORT REPORT AS PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  TableRow _buildSheetTableRow(String label, String value) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.6))),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Text(value, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  Widget _buildSheetMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        Text(value, style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${remainingSecs}s';
    }
    return '${remainingSecs}s';
  }
}
extension on Table {
  // Mock support helper for pdf layout row mapping
}
