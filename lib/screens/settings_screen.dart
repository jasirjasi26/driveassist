import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);

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
                    const Text('ADAS CONFIGURATION', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                    const SizedBox(width: 48), // spacer balance
                  ],
                ),

                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 16),

                      // 1. GENERAL TOGGLES GROUP
                      _buildSectionTitle('DISPLAY PREFERENCES'),
                      const SizedBox(height: 8),
                      GlassContainer(
                        opacity: 0.05,
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('HUD Windshield Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Mirrors screen layout horizontally for projection.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              value: settings.hudModeEnabled,
                              activeColor: AppTheme.electricTeal,
                              onChanged: settings.setHudModeEnabled,
                            ),
                            const Divider(color: AppTheme.glassBorder, height: 1),
                            SwitchListTile(
                              title: const Text('System Dark Theme', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Reduces screen glare during night drives.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              value: settings.darkModeEnabled,
                              activeColor: AppTheme.electricTeal,
                              onChanged: settings.setDarkModeEnabled,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. AUDIO & ALERTS GROUP
                      _buildSectionTitle('SAFETY ALERTS'),
                      const SizedBox(height: 8),
                      GlassContainer(
                        opacity: 0.05,
                        borderRadius: 20,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Voice Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Professional audio announcements for alerts.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              value: settings.voiceAlertsEnabled,
                              activeColor: AppTheme.electricTeal,
                              onChanged: settings.setVoiceAlertsEnabled,
                            ),
                            const Divider(color: AppTheme.glassBorder, height: 1),
                            SwitchListTile(
                              title: const Text('Lane Drift Warning', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Visual/Audio warnings on lane line drift.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              value: settings.laneDetectionEnabled,
                              activeColor: AppTheme.electricTeal,
                              onChanged: settings.setLaneDetectionEnabled,
                            ),
                            const Divider(color: AppTheme.glassBorder, height: 1),
                            SwitchListTile(
                              title: const Text('Proximity Tailgate Alarm', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                              subtitle: const Text('Triggers warnings when close to lead vehicle.', style: TextStyle(fontSize: 10, color: Colors.white54)),
                              value: settings.distanceAlertsEnabled,
                              activeColor: AppTheme.electricTeal,
                              onChanged: settings.setDistanceAlertsEnabled,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. PARAMETERS LIMIT GROUP
                      _buildSectionTitle('TELEMETRY THRESHOLDS'),
                      const SizedBox(height: 8),
                      GlassContainer(
                        opacity: 0.05,
                        borderRadius: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Speed limit slider
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Speed Warning Limit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                Text('${settings.speedLimit} km/h', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.electricTeal)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Slider(
                              value: settings.speedLimit.toDouble(),
                              min: 40.0,
                              max: 130.0,
                              divisions: 9,
                              label: '${settings.speedLimit} km/h',
                              activeColor: AppTheme.electricTeal,
                              inactiveColor: Colors.white.withOpacity(0.1),
                              onChanged: (val) => settings.setSpeedLimit(val.toInt()),
                            ),
                            const Divider(color: AppTheme.glassBorder, height: 20),

                            // Sensitivity selector
                            const Text('Sensor Detection Sensitivity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 2),
                            Text(
                              'Controls the promptness threshold of hard braking and drift alarms.',
                              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.5)),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: ['Low', 'Medium', 'High'].map((s) {
                                final isSelected = settings.sensitivity == s;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isSelected ? AppTheme.electricTeal : Colors.white.withOpacity(0.04),
                                        foregroundColor: isSelected ? Colors.black : Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          side: BorderSide(
                                            color: isSelected ? AppTheme.electricTeal : AppTheme.glassBorder,
                                            width: 0.8,
                                          ),
                                        ),
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                      ),
                                      onPressed: () => settings.setSensitivity(s),
                                      child: Text(s, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(color: AppTheme.glassBorder, height: 24),

                            // Units Selector
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Measurement Units', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                DropdownButton<String>(
                                  value: settings.units,
                                  dropdownColor: AppTheme.darkBlueGray,
                                  underline: const SizedBox(),
                                  style: const TextStyle(color: AppTheme.electricTeal, fontWeight: FontWeight.bold),
                                  items: <String>['Metric', 'Imperial'].map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) settings.setUnits(val);
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),

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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
        color: Colors.white.withOpacity(0.4),
      ),
    );
  }
}
