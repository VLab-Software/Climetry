import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class ClimateDetailsScreen extends StatelessWidget {
  final String location;
  final String date;
  final LatLng coordinates;
  final Map<String, dynamic> weatherData;

  const ClimateDetailsScreen({
    super.key,
    required this.location,
    required this.date,
    required this.coordinates,
    required this.weatherData,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(location, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(date),
              const SizedBox(height: 16),
              Text(
                'Lat: ${coordinates.latitude}, Lon: ${coordinates.longitude}',
              ),
              const SizedBox(height: 24),
              Text(
                'Raw payload:',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(weatherData.toString()),
            ],
          ),
        ),
      ),
    );
  }
}
