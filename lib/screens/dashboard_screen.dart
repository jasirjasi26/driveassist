import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/trip.dart';
import '../providers/settings_provider.dart';
import '../services/storage_service.dart';
import '../widgets/glass_container.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final StorageService _storage = StorageService();
  List<Trip> _recentTrips = [];
  double _lifetimeDistance = 0.0;
  double _avgDrivingScore = 0.0;
  int _totalTrips = 0;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final trips = _storage.getTrips();
    setState(() {
      _recentTrips = trips.take(3).toList();
      _totalTrips = trips.length;
      if (trips.isNotEmpty) {
        _lifetimeDistance = trips.fold(0.0, (sum, item) => sum + item.distance);
        _avgDrivingScore = trips.fold(0.0, (sum, item) => sum + item.score) / trips.length;
      } else {
        _lifetimeDistance = 0.0;
        _avgDrivingScore = 100.0; // Perfect starting score
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top System Status Bar
              _buildTopHeader(context),
              
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 12),
                      
                      // 1. Driving Score Card
                      _buildLifetimeScoreCard(),
                      
                      const SizedBox(height: 20),
                      
                      // 2. ADAS Launch Control Card
                      _buildLaunchAdasCard(context, settings),

                      const SizedBox(height: 20),
                      
                      // 3. Grid Stats (Distance, Average Speed, Trips)
                      _buildQuickStatsGrid(),

                      const SizedBox(height: 24),
                      
                      // 4. Recent Journeys Heading
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'RECENT JOURNEYS',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/history').then((_) => _loadStats());
                            },
                            child: const Text(
                              'VIEW ALL',
                              style: TextStyle(color: AppTheme.electricTeal, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      
                      const SizedBox(height: 4),

                      // 5. Recent Journeys List
                      if (_recentTrips.isEmpty)
                        _buildEmptyTripCard()
                      else
                        ..._recentTrips.map((trip) => _buildTripListItem(trip)),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET CONSTRUCTORS ---

  Widget _buildTopHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DRIVEASSIST',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: AppTheme.electricTeal.withOpacity(0.4),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppTheme.electricTeal),
                  const SizedBox(width: 6),
                  Text(
                    'SYSTEM ONLINE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // Action controls (Settings Shortcut)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white70),
                onPressed: () {
                  Navigator.pushNamed(context, '/settings').then((_) => _loadStats());
                },
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLifetimeScoreCard() {
    final scoreColor = _avgDrivingScore >= 85
        ? AppTheme.electricTeal
        : _avgDrivingScore >= 70
            ? AppTheme.warningOrange
            : AppTheme.neonCrimson;

    return GlassContainer(
      opacity: 0.08,
      borderRadius: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COGNITIVE SAFETY SCORE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _avgDrivingScore.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 54,
                      fontWeight: FontWeight.w900,
                      color: scoreColor,
                      shadows: [
                        Shadow(
                          color: scoreColor.withOpacity(0.4),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '/100',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white24,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withOpacity(0.3), width: 0.8),
                ),
                child: Text(
                  _avgDrivingScore >= 85
                      ? 'EXCELLENT'
                      : _avgDrivingScore >= 70
                          ? 'ALERT'
                          : 'DANGER',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Based on $_totalTrips drives',
                style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.4)),
              )
            ],
          )
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).scaleY(begin: 0.8);
  }

  Widget _buildLaunchAdasCard(BuildContext context, SettingsProvider settings) {
    return GlassContainer(
      opacity: 0.12,
      borderRadius: 24,
      borderColor: AppTheme.electricTeal.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.electricTeal.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.radar,
                  color: AppTheme.electricTeal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ADAS active co-pilot',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rear Camera ADAS & safety calculations',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
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
                elevation: 4,
                shadowColor: AppTheme.electricTeal.withOpacity(0.4),
              ),
              onPressed: () {
                Navigator.pushNamed(context, '/drive').then((_) => _loadStats());
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.navigation, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'START DRIVE ASSIST',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 500.ms);
  }

  Widget _buildQuickStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 1.6,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildGridStatCard(
          title: 'TOTAL DISTANCE',
          value: '${_lifetimeDistance.toStringAsFixed(1)} km',
          icon: Icons.alt_route,
        ),
        _buildGridStatCard(
          title: 'TOTAL JOURNEYS',
          value: '$_totalTrips',
          icon: Icons.insights,
        ),
      ],
    ).animate().fadeIn(delay: 300.ms, duration: 500.ms);
  }

  Widget _buildGridStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return GlassContainer(
      opacity: 0.06,
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppTheme.electricTeal.withOpacity(0.7), size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripListItem(Trip trip) {
    final scoreColor = trip.score >= 85
        ? AppTheme.electricTeal
        : trip.score >= 70
            ? AppTheme.warningOrange
            : AppTheme.neonCrimson;
    
    // Formatting date (e.g. 2026-07-09)
    final dateStr = '${trip.date.year}-${trip.date.month.toString().padLeft(2, '0')}-${trip.date.day.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: 16,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Score circle indicator
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: scoreColor, width: 2),
                color: scoreColor.withOpacity(0.06),
              ),
              child: Center(
                child: Text(
                  '${trip.score}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Trip summary details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Drive summary - $dateStr',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${trip.distance.toStringAsFixed(1)} km  •  ${_formatDuration(trip.durationSeconds)}  •  ${trip.warnings.length} alerts',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.3)),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildEmptyTripCard() {
    return GlassContainer(
      opacity: 0.04,
      borderRadius: 16,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.directions_car_outlined, size: 36, color: Colors.white.withOpacity(0.2)),
            const SizedBox(height: 12),
            Text(
              'No journeys logged yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tap START DRIVE ASSIST to log your first run.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
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
