import 'package:flutter/material.dart';

/// Badge showing NASA data integration
class NasaPoweredBadge extends StatelessWidget {
  final bool showFull;
  final Color? textColor;

  const NasaPoweredBadge({
    super.key,
    this.showFull = false,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = textColor ?? (isDark ? Colors.grey[400] : Colors.grey[600]);

    if (showFull) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '🛰️',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Powered by',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                Text(
                  'NASA',
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '🛰️',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(width: 4),
        Text(
          'NASA Data',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// Widget showing natural event from NASA EONET
class NasaEventCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final VoidCallback? onTap;

  const NasaEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = event['title'] as String? ?? 'Unknown Event';
    final categories = event['categories'] as List? ?? [];
    final categoryId = categories.isNotEmpty
        ? (categories.first['id'] as String?) ?? 'events'
        : 'events';
    
    final icon = _getCategoryIcon(categoryId);
    final description = event['description'] as String?;
    final link = event['sources'] != null && (event['sources'] as List).isNotEmpty
        ? ((event['sources'] as List).first['url'] as String?)
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: isDark ? Colors.grey[850] : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const NasaPoweredBadge(showFull: false),
                        if (link != null) ...[
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: Colors.grey[400],
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getCategoryIcon(String categoryId) {
    switch (categoryId.toLowerCase()) {
      case 'wildfires':
        return '🔥';
      case 'storms':
      case 'severestorms':
        return '⛈️';
      case 'floods':
        return '🌊';
      case 'volcanoes':
        return '🌋';
      case 'drought':
        return '🏜️';
      case 'dusthaze':
        return '💨';
      case 'earthquakes':
        return '🏚️';
      case 'landslides':
        return '⛰️';
      case 'sealakeice':
        return '🧊';
      case 'snow':
        return '❄️';
      case 'temperatureextremes':
        return '🌡️';
      case 'manmade':
        return '🏭';
      case 'watercolor':
        return '💧';
      default:
        return '🌍';
    }
  }
}
