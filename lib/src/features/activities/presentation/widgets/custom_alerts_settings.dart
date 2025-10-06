import 'package:flutter/material.dart';

class CustomAlertsSettings extends StatefulWidget {
  final Map<String, dynamic> currentSettings;
  final bool isAdmin; // Admins can set defaults for all participants
  final Function(Map<String, dynamic> settings) onSave;

  const CustomAlertsSettings({
    super.key,
    required this.currentSettings,
    required this.isAdmin,
    required this.onSave,
  });

  @override
  State<CustomAlertsSettings> createState() => _CustomAlertsSettingsState();
}

class _CustomAlertsSettingsState extends State<CustomAlertsSettings> {
  late Map<String, dynamic> _settings;
  bool _applyToAll = false;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.currentSettings);
    
    _settings.putIfAbsent('temperatureMin', () => 10.0);
    _settings.putIfAbsent('temperatureMax', () => 35.0);
    _settings.putIfAbsent('rainThreshold', () => 50.0);
    _settings.putIfAbsent('windThreshold', () => 30.0);
    _settings.putIfAbsent('humidityMin', () => 30.0);
    _settings.putIfAbsent('humidityMax', () => 90.0);
    _settings.putIfAbsent('enableRainAlerts', () => true);
    _settings.putIfAbsent('enableTemperatureAlerts', () => true);
    _settings.putIfAbsent('enableWindAlerts', () => true);
    _settings.putIfAbsent('enableHumidityAlerts', () => false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Icon(
                  Icons.tune,
                  color: Color(0xFF3B82F6),
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alertas Personalizados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Configure your alert limits',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          Divider(height: 1),

          Expanded(
            child: ListView(
              padding: EdgeInsets.all(20),
              children: [
                _buildToggleSection(
                  isDark: isDark,
                  icon: Icons.thermostat,
                  iconColor: Color(0xFFEF4444),
                  title: 'Alertas de Temperature',
                  enabled: _settings['enableTemperatureAlerts'] ?? true,
                  onToggle: (value) {
                    setState(() {
                      _settings['enableTemperatureAlerts'] = value;
                    });
                  },
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Temperature Mínima',
                        value: _settings['temperatureMin'] ?? 10.0,
                        min: -10,
                        max: 30,
                        unit: '°F',
                        onChanged: (value) {
                          setState(() {
                            _settings['temperatureMin'] = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Temperature Máxima',
                        value: _settings['temperatureMax'] ?? 35.0,
                        min: 20,
                        max: 50,
                        unit: '°F',
                        onChanged: (value) {
                          setState(() {
                            _settings['temperatureMax'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                _buildToggleSection(
                  isDark: isDark,
                  icon: Icons.water_drop,
                  iconColor: Color(0xFF3B82F6),
                  title: 'Alertas de Rain',
                  enabled: _settings['enableRainAlerts'] ?? true,
                  onToggle: (value) {
                    setState(() {
                      _settings['enableRainAlerts'] = value;
                    });
                  },
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Limite de Precipitation',
                        value: _settings['rainThreshold'] ?? 50.0,
                        min: 0,
                        max: 100,
                        unit: '%',
                        onChanged: (value) {
                          setState(() {
                            _settings['rainThreshold'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                _buildToggleSection(
                  isDark: isDark,
                  icon: Icons.air,
                  iconColor: Color(0xFF10B981),
                  title: 'Alertas de Wind',
                  enabled: _settings['enableWindAlerts'] ?? true,
                  onToggle: (value) {
                    setState(() {
                      _settings['enableWindAlerts'] = value;
                    });
                  },
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Velocidade Máxima do Wind',
                        value: _settings['windThreshold'] ?? 30.0,
                        min: 0,
                        max: 100,
                        unit: 'km/h',
                        onChanged: (value) {
                          setState(() {
                            _settings['windThreshold'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20),

                _buildToggleSection(
                  isDark: isDark,
                  icon: Icons.opacity,
                  iconColor: Color(0xFF8B5CF6),
                  title: 'Alertas de Humidity',
                  enabled: _settings['enableHumidityAlerts'] ?? false,
                  onToggle: (value) {
                    setState(() {
                      _settings['enableHumidityAlerts'] = value;
                    });
                  },
                  child: Column(
                    children: [
                      SizedBox(height: 12),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Humidity Mínima',
                        value: _settings['humidityMin'] ?? 30.0,
                        min: 0,
                        max: 70,
                        unit: '%',
                        onChanged: (value) {
                          setState(() {
                            _settings['humidityMin'] = value;
                          });
                        },
                      ),
                      SizedBox(height: 16),
                      _buildSlider(
                        isDark: isDark,
                        label: 'Humidity Máxima',
                        value: _settings['humidityMax'] ?? 90.0,
                        min: 50,
                        max: 100,
                        unit: '%',
                        onChanged: (value) {
                          setState(() {
                            _settings['humidityMax'] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                if (widget.isAdmin) ...[
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Color(0xFFF59E0B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Color(0xFFF59E0B).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.admin_panel_settings,
                          color: Color(0xFFF59E0B),
                          size: 20,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Apply to All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'As admin, you can set these settings as default for all participants',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _applyToAll,
                          onChanged: (value) {
                            setState(() {
                              _applyToAll = value;
                            });
                          },
                          activeColor: Color(0xFFF59E0B),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF111827) : Color(0xFFF8FAFC),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white10 : Colors.black12,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _settings['applyToAll'] = _applyToAll;
                      widget.onSave(_settings);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleSection({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool enabled,
    required ValueChanged<bool> onToggle,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF111827) : Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                onChanged: onToggle,
                activeColor: iconColor,
              ),
            ],
          ),
          if (enabled) child,
        ],
      ),
    );
  }

  Widget _buildSlider({
    required bool isDark,
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              '${value.round()}$unit',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Color(0xFF3B82F6),
            inactiveTrackColor: Color(0xFF3B82F6).withOpacity(0.2),
            thumbColor: Color(0xFF3B82F6),
            overlayColor: Color(0xFF3B82F6).withOpacity(0.2),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
