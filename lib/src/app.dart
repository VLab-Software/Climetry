import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/climate/presentation/screens/climate_screen.dart';
import 'features/climate/presentation/state/climate_view_model.dart';
import 'features/climate/data/datasources/geocoding_remote_ds.dart';
import 'features/climate/data/datasources/meteomatics_remote_ds.dart';
import 'features/climate/domain/repositories/location_repository_impl.dart';
import 'features/climate/domain/repositories/weather_repository_impl.dart';
import 'core/network/api_client.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final geocodingDs = GeocodingRemoteDateSource(client: apiClient);
    final meteomaticsDs = MeteomaticsRemoteDateSource(client: apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ClimateViewModel(
            weatherRepository: WeatherRepositoryImpl(remote: meteomaticsDs),
            locationRepository: LocationRepositoryImpl(remote: geocodingDs),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Earth Date Analysis',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const ClimateScreen(),
      ),
    );
  }
}
