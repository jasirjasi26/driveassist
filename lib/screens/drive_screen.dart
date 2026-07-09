import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';

import '../core/theme/app_theme.dart';
import '../models/vehicle.dart';
import '../providers/drive_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/speedometer_gauge.dart';
import '../widgets/bounding_box_painter.dart';
import '../widgets/lane_painter.dart';

class DriveScreen extends StatefulWidget {
  const DriveScreen({Key? key}) : super(key: key);

  @override
  State<DriveScreen> createState() => _DriveScreenState();
}

class _DriveScreenState extends State<DriveScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
    _startDriveAssist();
  }

  Future<void> _stopEverything() async {
    final driveProvider =
    Provider.of<DriveProvider>(context, listen: false);

    // Stop Trip
    await driveProvider.stopTrip();

    // Stop Camera
    if (_cameraController != null) {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }

      await _cameraController!.dispose();
    }

    // Stop detector
    driveProvider.detectorService.stopDetection();

    // Stop GPS
    driveProvider.stopTrip();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        // Choose back camera
        final backCamera = _cameras.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.back,
          orElse: () => _cameras.first,
        );

        _cameraController = CameraController(
          backCamera,
          ResolutionPreset.medium,
          enableAudio: false,
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() {
            _isCameraInitialized = true;
          });
        }

        // Connect image stream to DetectorService
        final detector = Provider.of<DriveProvider>(context, listen: false);
        _cameraController!.startImageStream((CameraImage image) {
          detector.detectorService.processCameraImage(image);
        });
      }
    } catch (e) {
      print("Camera initialization error: $e");
    }
  }

  void _startDriveAssist() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final driveProvider = Provider.of<DriveProvider>(context, listen: false);
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      driveProvider.startTrip(settings.speedLimit);
    });
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    final drive =
    Provider.of<DriveProvider>(context, listen: false);

    drive.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drive = Provider.of<DriveProvider>(context);
    final settings = Provider.of<SettingsProvider>(context);

    // Dynamic warning animation values
    final activeBordersColor = drive.isTailgating
        ? AppTheme.neonCrimson.withOpacity(0.6)
        : drive.isLaneDeparture
            ? AppTheme.warningOrange.withOpacity(0.6)
            : Colors.transparent;

    // Build the visual dashboard layers
    Widget mainUi = Stack(
      children: [
        // 1. Camera Feed / AR Simulator Sandbox
        Positioned.fill(
          child: _buildCameraPreviewOrSimulation(drive),
        ),

        // 2. Active Screen Danger Border Warning Flash
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              decoration: BoxDecoration(
                border: Border.all(
                  color: activeBordersColor,
                  width: drive.isTailgating || drive.isLaneDeparture ? 8.0 : 0.0,
                ),
              ),
            ),
          ),
        ),

        // 3. Main Gauges and HUD Widgets Overlay
        settings.hudModeEnabled
            ? _buildHudWindshieldLayout(drive, settings)
            : _buildDashboardLayout(context, drive, settings),
      ],
    );

    // Apply HORIZONTAL MIRROR rotation if HUD Mode is enabled
    if (settings.hudModeEnabled) {
      mainUi = Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi), // Mirrors layout for windshield reflection
        child: Theme(
          data: AppTheme.hudTheme,
          child: mainUi,
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await _stopEverything();

        if (mounted) {
          Navigator.pop(context);
        }
      },
      child:  Scaffold(
        backgroundColor: settings.hudModeEnabled ? Colors.black : AppTheme.spaceCadet,
        body: mainUi,
      ),
    );
  }

  bool isRecording = false;

  Widget buildRecordButton() {
    return GestureDetector(
      onTap: () async {
        if (isRecording) {
          await stopRecording();
        } else {
          await startRecording();
        }

        setState(() {
          isRecording = !isRecording;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 45,
        width: 140,
        decoration: BoxDecoration(
          color: isRecording
              ? Colors.red.shade700
              : Colors.black.withOpacity(.65),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isRecording ? Colors.redAccent : Colors.white24,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isRecording ? Icons.stop : Icons.fiber_manual_record,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isRecording ? "STOP" : "REC VIDEO",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> startRecording() async {
    if (!_cameraController!.value.isInitialized) return;

    if (_cameraController!.value.isRecordingVideo) return;

    await _cameraController!.startVideoRecording();
  }

  Future<void> stopRecording() async {
    if (!_cameraController!.value.isRecordingVideo) return;

    final dir = Directory('/storage/emulated/0/Movies/DriveAssist');

    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    final XFile video = await _cameraController!.stopVideoRecording();

    final newPath =
        '${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    await File(video.path).copy(newPath);
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildCameraPreviewOrSimulation(DriveProvider drive) {
    if (_isCameraInitialized && _cameraController != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_cameraController!),
          // AI Object detection overlays
          Positioned.fill(
            child: CustomPaint(
              painter: BoundingBoxPainter(
                detections: drive.detectorService.isSimulationMode ? [] : [], // If live mode is connected
                safeDistance: drive.safeDistance,
              ),
            ),
          ),
        ],
      );
    }

    // High Fidelity Vector Simulation overlay when camera unavailable (Emulators)
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Cyber Grid background representing a camera highway feed
          CustomPaint(
            painter: _VectorHighwayPainter(
              laneOffset: drive.laneOffset,
            ),
          ),
          
          // Stream AI Detections overlay
          StreamBuilder<List<DetectedVehicle>>(
            stream: drive.detectorService.detectionStream,
            builder: (context, snapshot) {
              final list = snapshot.data ?? [];
              return CustomPaint(
                painter: BoundingBoxPainter(
                  detections: list,
                  safeDistance: drive.safeDistance,
                ),
              );
            },
          ),

          // Stream Lanes overlay
          StreamBuilder<Map<String, List<Offset>>>(
            stream: drive.detectorService.laneStream,
            builder: (context, snapshot) {
              final map = snapshot.data ?? {};
              return CustomPaint(
                painter: LanePainter(
                  leftLane: map['left'] ?? [],
                  rightLane: map['right'] ?? [],
                  isLaneDeparture: drive.isLaneDeparture,
                  driftOffset: drive.laneOffset,
                ),
              );
            },
          )
        ],
      ),
    );
  }

  Widget _buildDashboardLayout(BuildContext context, DriveProvider drive, SettingsProvider settings) {
    return Positioned.fill(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top control bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _confirmExit(context, drive),
                  ),
                  Row(
                    children: [
                      _buildHeaderDiagnosticChip('FPS: ${drive.detectorFps.toStringAsFixed(0)}', Icons.bolt),
                      const SizedBox(width: 8),
                      _buildHeaderDiagnosticChip('GPS: ${drive.gpsAccuracy.toStringAsFixed(1)}m', Icons.gps_fixed),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Warning Panel
              if (drive.isTailgating)
                _buildSafetyStatusIndicator('COLLISION WARNING', 'MAINTAIN SAFE DISTANCE', AppTheme.neonCrimson, Icons.warning)
              else if (drive.isLaneDeparture)
                _buildSafetyStatusIndicator('LANE DRIFT ALERT', 'STEER BACK TO CENTER', AppTheme.warningOrange, Icons.navigation)
              else if (drive.isOverspeeding)
                _buildSafetyStatusIndicator('OVERSPEEDING', 'REDUCE SPEED IMMEDIATELY', AppTheme.neonCrimson, Icons.speed),

              const SizedBox(height: 16),

              // Bottom Glassmorphic Dashboard HUD
              GlassContainer(
                opacity: 0.15,
                borderRadius: 24,
                child: Column(
                  children: [
                    // Speedometer & Distance Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        SpeedometerGauge(
                          speed: drive.currentSpeed,
                          limit: settings.speedLimit,
                          isOverspeeding: drive.isOverspeeding,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatText('LEAD VEHICLE', drive.leadVehicleLabel.toUpperCase(), Colors.white.withOpacity(0.6)),
                            const SizedBox(height: 12),
                            _buildStatText('GAP DISTANCE', '${drive.leadVehicleDistance.toStringAsFixed(1)} m', Colors.white),
                            const SizedBox(height: 12),
                            _buildStatText('SAFE DISTANCE', '${drive.safeDistance.toStringAsFixed(1)} m', AppTheme.electricTeal),
                          ],
                        ),
                      ],
                    ),
                    const Divider(color: AppTheme.glassBorder, height: 12, thickness: 0.1),
                    
                    // Auxiliary driving telemetry
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSubStat('SCORE', '${drive.drivingScore}', drive.drivingScore >= 85 ? AppTheme.electricTeal : AppTheme.warningOrange),
                        _buildSubStat('TIME', _formatDuration(drive.elapsedSeconds), Colors.white),
                        _buildSubStat('DIST', '${drive.distanceTraveled.toStringAsFixed(2)} km', Colors.white),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: Icon(
                              settings.hudModeEnabled ? Icons.flip : Icons.visibility,
                              color: Colors.white,
                            ),
                            onPressed: () => settings.setHudModeEnabled(!settings.hudModeEnabled),
                          ),
                        ),
                        buildRecordButton()
                      ],
                    ),

                    //const SizedBox(height: 16),

                    // Controls panel
                    Row(
                      children: [
                        // SOS Emergency Button
                        // Expanded(
                        //   child: ElevatedButton(
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: AppTheme.neonCrimson,
                        //       foregroundColor: Colors.white,
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(12),
                        //       ),
                        //       padding: const EdgeInsets.symmetric(vertical: 14),
                        //     ),
                        //     onPressed: drive.triggerSosAlert,
                        //     child: const Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         Icon(Icons.sos, size: 20),
                        //         SizedBox(width: 6),
                        //         Text('SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        //       ],
                        //     ),
                        //   ),
                        // ),
                        //const SizedBox(width: 10),

                        // Simulated test brake button (Developer tool)
                        // if (drive.detectorService.isSimulationMode)
                        //   Expanded(
                        //     child: OutlinedButton(
                        //       style: OutlinedButton.styleFrom(
                        //         side: const BorderSide(color: AppTheme.electricTeal, width: 1.0),
                        //         shape: RoundedRectangleBorder(
                        //           borderRadius: BorderRadius.circular(12),
                        //         ),
                        //         padding: const EdgeInsets.symmetric(vertical: 14),
                        //       ),
                        //       onPressed: () {
                        //         drive.forceSimulatorBrake();
                        //         Future.delayed(const Duration(seconds: 4), () {
                        //           drive.resetSimulatorMetrics();
                        //         });
                        //       },
                        //       child: const Text(
                        //         'SIMULATE BRAKE',
                        //         style: TextStyle(color: AppTheme.electricTeal, fontWeight: FontWeight.bold, fontSize: 11),
                        //       ),
                        //     ),
                        //   ),
                        // const SizedBox(width: 10),
                        //
                        // // HUD Mirror Toggle
                        // Container(
                        //   decoration: BoxDecoration(
                        //     border: Border.all(color: AppTheme.glassBorder, width: 0.8),
                        //     borderRadius: BorderRadius.circular(12),
                        //   ),
                        //   child: IconButton(
                        //     icon: Icon(
                        //       settings.hudModeEnabled ? Icons.flip : Icons.visibility,
                        //       color: Colors.white,
                        //     ),
                        //     onPressed: () => settings.setHudModeEnabled(!settings.hudModeEnabled),
                        //   ),
                        // )
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHudWindshieldLayout(DriveProvider drive, SettingsProvider settings) {
    // HUD Mode UI - optimized strictly for reflection (black bg, neon green text)
    final criticalColor = AppTheme.brightGreen; // In HUD everything is green
    
    return Positioned.fill(
      child: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Safe Distance HUD readout
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text('LEAD DISTANCE', style: TextStyle(fontSize: 16, color: criticalColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${drive.leadVehicleDistance.toStringAsFixed(0)} m', style: TextStyle(fontSize: 42, color: criticalColor, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    Text('SAFE GAP', style: TextStyle(fontSize: 16, color: criticalColor, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('${drive.safeDistance.toStringAsFixed(0)} m', style: TextStyle(fontSize: 42, color: criticalColor, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 48),

            // Giant HUD Speedometer
            Text(
              drive.currentSpeed.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 140,
                fontWeight: FontWeight.w900,
                color: drive.isOverspeeding ? AppTheme.neonCrimson : criticalColor,
              ),
            ),
            Text(
              'KM/H',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 4.0,
                color: criticalColor,
              ),
            ),
            
            const SizedBox(height: 48),

            // Heavy text safety notices
            if (drive.isTailgating)
              Text('COLLISION CRITICAL - SLOW DOWN', style: TextStyle(fontSize: 20, color: AppTheme.neonCrimson, fontWeight: FontWeight.bold))
            else if (drive.isLaneDeparture)
              Text('LANE DEPARTURE ALERT', style: TextStyle(fontSize: 20, color: AppTheme.neonCrimson, fontWeight: FontWeight.bold))
            else
              Text('DRIVE ASSIST ACTIVE', style: TextStyle(fontSize: 16, color: criticalColor, fontWeight: FontWeight.bold)),

            const SizedBox(height: 48),

            // Close button (needs to be visible but discreet)
            IconButton(
              icon: Icon(Icons.close, color: criticalColor, size: 28),
              onPressed: () => settings.setHudModeEnabled(false),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderDiagnosticChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 0.8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.electricTeal, size: 10),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSafetyStatusIndicator(String title, String subtitle, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.0),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.08), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.0)),
              Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 9)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildStatText(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
            color: Colors.white.withOpacity(0.4),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSubStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 8, color: Colors.white.withOpacity(0.4), fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 15, color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSecs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSecs.toString().padLeft(2, '0')}';
  }

  void _confirmExit(BuildContext context, DriveProvider drive) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Complete Journey?'),
        content: const Text('Are you sure you want to end this active Drive Assist session? Your statistics will be logged.'),
        actions: [
          TextButton(
            child: const Text('CANCEL'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.electricTeal, foregroundColor: Colors.black),
            child: const Text('COMPLETE DRIVE'),
            onPressed: () async {
              Navigator.pop(ctx);
              final trip = await drive.stopTrip();
              if (mounted && trip != null) {
                // Navigate to Trip Summary screen, replacing the drive screen in stack
                Navigator.pushReplacementNamed(context, '/summary', arguments: trip);
              }
            },
          )
        ],
      ),
    );
  }
}
// Custom Painter to draw a simulated perspective road vector background
class _VectorHighwayPainter extends CustomPainter {
  final double laneOffset;

  const _VectorHighwayPainter({required this.laneOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF070B14);
    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, size.width, size.height), bgPaint);

    final horizonY = size.height * 0.48;
    
    // Horizon center shifts slightly with lane drift
    final horizonX = (size.width / 2.0) - (laneOffset * 25.0);

    // 1. Draw horizon sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF0F172A), Color(0xFF070B14)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0.0, 0.0, size.width, horizonY));
    canvas.drawRect(Rect.fromLTRB(0.0, 0.0, size.width, horizonY), skyPaint);

    // 2. Draw cyber highway grids (perspective lines)
    final gridPaint = Paint()
      ..color = const Color(0x0AFFFFFF) // 4% white opacity
      ..strokeWidth = 0.5;

    for (int i = -8; i <= 8; i++) {
      // Bottom start of grid lines shifts more due to proximity perspective
      double startX = (size.width / 2.0) + (i * size.width * 0.15) - (laneOffset * size.width * 0.5);
      canvas.drawLine(
        Offset(startX, size.height),
        Offset(horizonX, horizonY),
        gridPaint,
      );
    }

    // Horizontal grid guidelines
    for (double y = horizonY; y < size.height; y += 30.0) {
      double factor = (y - horizonY) / (size.height - horizonY);
      double offsetFactor = factor * factor; // Warp to perspective
      double targetY = horizonY + offsetFactor * (size.height - horizonY);
      canvas.drawLine(Offset(0.0, targetY), Offset(size.width, targetY), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VectorHighwayPainter oldDelegate) {
    return oldDelegate.laneOffset != laneOffset;
  }
}
