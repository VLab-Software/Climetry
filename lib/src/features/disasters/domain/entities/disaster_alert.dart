enum DisasterType {
  flood,
  severeStorm,
  frost,
  wildfire;

  String get label {
    switch (this) {
      case DisasterType.flood:
        return 'Inundações';
      case DisasterType.severeStorm:
        return 'Tempestades Severas';
      case DisasterType.frost:
        return 'Geada';
      case DisasterType.wildfire:
        return 'Incêndios Florestais';
    }
  }

  String get icon {
    switch (this) {
      case DisasterType.flood:
        return '🌊';
      case DisasterType.severeStorm:
        return '⛈️';
      case DisasterType.frost:
        return '❄️';
      case DisasterType.wildfire:
        return '🔥';
    }
  }
}

enum AlertSeverity {
  info,
  warning,
  severe;

  String get label {
    switch (this) {
      case AlertSeverity.info:
        return 'Informativo';
      case AlertSeverity.warning:
        return 'Aviso';
      case AlertSeverity.severe:
        return 'Severo';
    }
  }
}

class DisasterAlert {
  final String id;
  final DisasterType type;
  final AlertSeverity severity;
  final String title;
  final String message;
  final DateTime timestamp;
  final String? location;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  DisasterAlert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    required this.timestamp,
    this.location,
    this.latitude,
    this.longitude,
    this.isActive = true,
  });
}
