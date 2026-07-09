import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/theme/app_theme.dart';
import '../widgets/glass_container.dart';

class PermissionsScreen extends StatefulWidget {
  const PermissionsScreen({Key? key}) : super(key: key);

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen> {
  // Permission states tracking
  bool _cameraGranted = false;
  bool _locationGranted = false;
  bool _sensorsGranted = false;
  bool _notificationsGranted = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermissions();
  }

  Future<void> _checkCurrentPermissions() async {
    final camera = await Permission.camera.isGranted;
    final location = await Permission.location.isGranted;
    final sensors = await Permission.sensors.isGranted;
    final notification = await Permission.notification.isGranted;

    setState(() {
      _cameraGranted = camera;
      _locationGranted = location;
      _sensorsGranted = sensors;
      _notificationsGranted = notification;
    });

    _checkAllGrantedAndProceed();
  }

  void _checkAllGrantedAndProceed() {
    if (_cameraGranted && _locationGranted && _sensorsGranted && _notificationsGranted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
  }

  Future<void> _requestPermission(Permission permission, Function(bool) updateState) async {
    final status = await permission.request();
    setState(() {
      updateState(status.isGranted);
    });
    _checkAllGrantedAndProceed();
  }

  Future<void> _requestAllPermissions() async {
    // Sequential request flow
    await Permission.camera.request();
    await Permission.location.request();
    await Permission.sensors.request();
    await Permission.notification.request();
    
    await _checkCurrentPermissions();
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Heading
                Text(
                  'SYSTEM PERMISSIONS',
                  style: TextStyle(
                    fontSize: 28,
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
                const SizedBox(height: 8),
                Text(
                  'DriveAssist AI requires the following permissions to act as a real-time ADAS on the road.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 32),

                // Cards list
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildPermissionCard(
                        title: 'Camera Access',
                        description: 'Required for live traffic detection, vehicle tracking and lane mapping.',
                        icon: Icons.camera_alt,
                        isGranted: _cameraGranted,
                        onPressed: () => _requestPermission(Permission.camera, (val) => _cameraGranted = val),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: 'GPS Location',
                        description: 'Used for reading GPS speed, generating distance warnings, and mapping trip speed graphs.',
                        icon: Icons.gps_fixed,
                        isGranted: _locationGranted,
                        onPressed: () => _requestPermission(Permission.location, (val) => _locationGranted = val),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: 'Accelerometer & Gyroscope',
                        description: 'Accesses motion sensors to detect hard braking, sudden deceleration, and acceleration.',
                        icon: Icons.sensors,
                        isGranted: _sensorsGranted,
                        onPressed: () => _requestPermission(Permission.sensors, (val) => _sensorsGranted = val),
                      ),
                      const SizedBox(height: 16),
                      _buildPermissionCard(
                        title: 'Push Notifications',
                        description: 'Required for background service trip telemetry, system logs and sound alerts.',
                        icon: Icons.notifications_active,
                        isGranted: _notificationsGranted,
                        onPressed: () => _requestPermission(Permission.notification, (val) => _notificationsGranted = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                // Master Action button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.electricTeal,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 8,
                      shadowColor: AppTheme.electricTeal.withOpacity(0.4),
                    ),
                    onPressed: _requestAllPermissions,
                    child: const Text(
                      'GRANT ALL PERMISSIONS',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                    child: Text(
                      'Skip for now (Limited Functionality)',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String description,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onPressed,
  }) {
    final statusColor = isGranted ? AppTheme.electricTeal : AppTheme.neonCrimson;
    
    return GlassContainer(
      opacity: 0.08,
      borderRadius: 16,
      borderColor: isGranted ? AppTheme.electricTeal.withOpacity(0.3) : AppTheme.glassBorder,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Checkmark or request button
          IconButton(
            icon: Icon(
              isGranted ? Icons.check_circle : Icons.arrow_circle_right,
              color: statusColor,
              size: 28,
            ),
            onPressed: isGranted ? null : onPressed,
          )
        ],
      ),
    );
  }
}
