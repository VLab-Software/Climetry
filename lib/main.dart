import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'src/core/auth/auth_wrapper.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/core/providers/event_refresh_notifier.dart';
import 'src/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  try {
    await Firebase.initializeApp();
    debugPrint('✅ Firebase inicializado com sucesso');
    
    // Inicializar FCM (Notificações Push)
    final fcmService = FCMService();
    await fcmService.initialize();
  } catch (e) {
    // Se Firebase não estiver configurado, continuar sem ele
    debugPrint('⚠️ Firebase não configurado: $e');
  }

  // Inicializar formatação de datas em português
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => EventRefreshNotifier()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Climetry',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
          locale: const Locale('pt', 'BR'),
          home: const AuthWrapper(),
        );
      },
    );
  }
}
