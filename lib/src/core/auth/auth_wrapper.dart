import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../app_new.dart';

/// Widget que gerencia o estado de autenticação
/// Redireciona para Welcome se não autenticado, ou para Home se autenticado
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    // ✅ Listener para debug e forçar rebuild
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        debugPrint('🔄 Auth state changed: ${user?.email ?? "null"} (uid: ${user?.uid ?? "null"})');
        setState(() {});
      }
    });
    
    // ✅ Verificar estado inicial imediatamente
    final currentUser = FirebaseAuth.instance.currentUser;
    debugPrint('🔐 Estado inicial: ${currentUser?.email ?? "null"}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        final connectionState = snapshot.connectionState;
        
        debugPrint('📱 AuthWrapper build - State: $connectionState, User: ${user?.email ?? "null"}');
        
        // ✅ Se já temos usuário, mostrar home IMEDIATAMENTE
        if (user != null) {
          debugPrint('✅ Usuário detectado, carregando MainScaffold');
          return const MainScaffold(key: ValueKey('main'));
        }
        
        // Carregando - mostrar splash screen apenas no PRIMEIRO carregamento
        if (connectionState == ConnectionState.waiting && user == null) {
          debugPrint('⏳ Aguardando autenticação inicial...');
          return const Scaffold(
            backgroundColor: Color(0xFF1E2A3A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo ou ícone do app
                  Icon(Icons.cloud, size: 80, color: Color(0xFF4A9EFF)),
                  SizedBox(height: 24),
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF4A9EFF),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Climetry',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Verificar se há erro
        if (snapshot.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFF1E2A3A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 60),
                  const SizedBox(height: 16),
                  const Text(
                    'Erro ao carregar',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      snapshot.error.toString(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9EFF),
                    ),
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          );
        }

        // ✅ Se temos usuário, mostrar home IMEDIATAMENTE (sem verificar connectionState)
        final currentUser = snapshot.data;
        if (currentUser != null) {
          debugPrint('✅ Usuário detectado: ${currentUser.email}');
          return const MainScaffold(key: ValueKey('main'));
        }

        // Sem usuário = mostrar tela de welcome
        debugPrint('🚪 Sem usuário, mostrando WelcomeScreen');
        return const WelcomeScreen(key: ValueKey('welcome'));
      },
    );
  }
}
