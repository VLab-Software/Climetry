import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'src/core/auth/auth_wrapper.dart';
import 'src/core/theme/app_theme.dart';
import 'src/core/theme/theme_provider.dart';
import 'src/core/providers/event_refresh_notifier.dart';
import 'src/core/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Carregar variáveis de ambiente do .env
  await dotenv.load(fileName: ".env");
  
  debugPrint('✅ Variáveis de ambiente carregadas');

  // Inicializar Firebase
  try {
    if (kIsWeb) {
      // Configuração Firebase para Web (nasa-climetry)
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: "AIzaSyA4GGNIowmIZTF_MHaJPte0-TzSJ_xNmcs",
          authDomain: "nasa-climetry.firebaseapp.com",
          projectId: "nasa-climetry",
          storageBucket: "nasa-climetry.firebasestorage.app",
          messagingSenderId: "938150925319",
          appId: "1:938150925319:web:d04390d1c8b343f55706a2",
          measurementId: "G-H36QPYN3EY",
        ),
      );
      
      // ✅ FIRESTORE: Cache em memória apenas (não persistente em disco)
      // Isso evita travamentos mas mantém performance razoável
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: false, // Sem disco
        cacheSizeBytes: 100 * 1024 * 1024, // 100MB cache em memória
      );
      
      debugPrint('🔥 Firestore: Cache em memória (não persistente)');
    } else {
      // Para Android e iOS, usa os arquivos de configuração nativos
      await Firebase.initializeApp();
    }
    
    debugPrint('✅ Firebase inicializado com sucesso');
    
    // Inicializar FCM (Notificações Push) - apenas para mobile
    if (!kIsWeb) {
      final fcmService = FCMService();
      await fcmService.initialize();
    }
  } catch (e) {
    // Se Firebase não estiver configurado, continuar sem ele
    debugPrint('⚠️ Firebase não configurado: $e');
  }

  // Inicializar formatação de datas em português
  await initializeDateFormatting('pt_BR', null);

  runApp(
    MultiProvider(
      providers: [
        // ThemeProvider mantido apenas para compatibilidade
        // mas não é mais usado - tema fixo light
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
    // TEMA FIXO LIGHT - SEM CONSUMER, SEM CARREGAMENTO
    return MaterialApp(
      title: 'Climetry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light, // SEMPRE LIGHT - FIXO E IMEDIATO
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en', 'US')],
      locale: const Locale('pt', 'BR'),
      home: const AuthWrapper(),
    );
  }
}
