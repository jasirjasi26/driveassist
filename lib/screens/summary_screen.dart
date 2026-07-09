import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme/app_theme.dart';
import '../models/trip.dart';
import '../services/pdf_service.dart';
import '../widgets/glass_container.dart';

class SummaryScreen extends StatelessWidget {
  const SummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Retrieve the trip arguments passed from the drive screen
    final trip = ModalRoute.of(context)!.settings.arguments as Trip;

    final scoreColor = trip.score >= 85
        ? AppTheme.electricTeal
        : trip.score >= 70
            ? AppTheme.warningOrange
            : AppTheme.neonCrimson;

    final ratingString = trip.score >= 85
        ? 'EXCELLENT DRIVER'
        : trip.score >= 70
            ? 'CAUTIOUS DRIVER'
            : 'UNSAFE - NEED ATTENTION';

    final adviceString = trip.score >= 85
        ? 'Fantastic drive! You kept a safe distance, obeyed limits, and braked smoothly. Keep it up!'
        : trip.score >= 70
            ? 'Good run, but remember to keep a safe distance from lead vehicles and monitor your speedometer.'
            : 'Critical warnings detected. Keep a wider gap, reduce speed, and steer defensively.';

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
                const SizedBox(height: 16),
                Text(
                  'TRIP SUMMARY',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.5,
                    shadows: [
                      Shadow(
                        color: AppTheme.electricTeal.withOpacity(0.3),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // 1. Massive Score Display
                      GlassContainer(
                        opacity: 0.08,
                        borderRadius: 24,
                        child: Column(
                          children: [
                            const Text(
                              'SAFETY PERFORMANCE SCORE',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white60),
                            ),
                            const SizedBox(height: 12),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 140,
                                  height: 140,
                                  child: CircularProgressIndicator(
                                    value: trip.score / 100,
                                    strokeWidth: 10,
                                    color: scoreColor,
                                    backgroundColor: Colors.white.withOpacity(0.04),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${trip.score}',
                                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: scoreColor),
                                    ),
                                    const Text('SCORE', style: TextStyle(fontSize: 8, color: Colors.white30, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                  ],
                                )
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              ratingString,
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: scoreColor, letterSpacing: 1.0),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Text(
                                adviceString,
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5), height: 1.4),
                              ),
                            )
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms).scaleY(begin: 0.9),

                      const SizedBox(height: 20),

                      // 2. Metrics Card
                      Text(
                        'METRICS LOG',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      GlassContainer(
                        opacity: 0.05,
                        borderRadius: 20,
                        child: Column(
                          children: [
                            _buildSummaryMetricRow('Distance Driven', '${trip.distance.toStringAsFixed(2)} km', Icons.map),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildSummaryMetricRow('Duration', _formatDuration(trip.durationSeconds), Icons.timer),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildSummaryMetricRow('Average Speed', '${trip.avgSpeed.toStringAsFixed(1)} km/h', Icons.speed),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildSummaryMetricRow('Maximum Speed', '${trip.maxSpeed.toStringAsFixed(1)} km/h', Icons.speed_outlined),
                          ],
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                      const SizedBox(height: 20),

                      // 3. Deductions & Infractions Card
                      Text(
                        'ADAS SAFETY INFRACTIONS',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.4), letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 8),
                      GlassContainer(
                        opacity: 0.05,
                        borderRadius: 20,
                        child: Column(
                          children: [
                            _buildInfractionRow('Hard Braking Events', '${trip.hardBrakingCount}', trip.hardBrakingCount > 0 ? AppTheme.neonCrimson : AppTheme.electricTeal),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildInfractionRow('Sudden Accelerations', '${trip.suddenAccelerationCount}', trip.suddenAccelerationCount > 0 ? AppTheme.warningOrange : AppTheme.electricTeal),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildInfractionRow('Tailgating Duration', '${trip.tailgatingSeconds} s', trip.tailgatingSeconds > 0 ? AppTheme.neonCrimson : AppTheme.electricTeal),
                            const Divider(color: AppTheme.glassBorder, height: 16),
                            _buildInfractionRow('Lane Departure Drift Alerts', '${trip.laneDepartureCount}', trip.laneDepartureCount > 0 ? AppTheme.warningOrange : AppTheme.electricTeal),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),

                // Bottom Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.electricTeal, width: 1.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => PdfService.exportTripPdf(trip),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.picture_as_pdf, color: AppTheme.electricTeal),
                            SizedBox(width: 8),
                            Text('EXPORT PDF', style: TextStyle(color: AppTheme.electricTeal, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.electricTeal,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
                        child: const Text('GO TO DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetricRow(String label, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white54, size: 18),
            const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
      ],
    );
  }

  Widget _buildInfractionRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  String _formatDuration(int seconds) {
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
