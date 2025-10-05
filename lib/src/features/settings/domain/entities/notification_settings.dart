class NotificationSettings {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final Map<String, bool> disasterTypes;
  final double monitoringRadius; // em km

  NotificationSettings({
    this.pushNotifications = true,
    this.emailNotifications = false,
    this.smsNotifications = false,
    Map<String, bool>? disasterTypes,
    this.monitoringRadius = 30.0,
  }) : disasterTypes =
           disasterTypes ??
           {
             'flood': false,
             'severeStorm': false,
             'frost': false,
             'wildfire': false,
           };

  NotificationSettings copyWith({
    bool? pushNotifications,
    bool? emailNotifications,
    bool? smsNotifications,
    Map<String, bool>? disasterTypes,
    double? monitoringRadius,
  }) {
    return NotificationSettings(
      pushNotifications: pushNotifications ?? this.pushNotifications,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      disasterTypes: disasterTypes ?? this.disasterTypes,
      monitoringRadius: monitoringRadius ?? this.monitoringRadius,
    );
  }
}
