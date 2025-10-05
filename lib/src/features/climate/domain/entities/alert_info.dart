class AlertInfo {
  final String title;
  final String message;
  final double probability; // 0..100
  const AlertInfo({
    required this.title,
    required this.message,
    required this.probability,
  });

  static const analyzing = AlertInfo(
    title: 'Analisando dados...',
    message: '',
    probability: 0,
  );
}
