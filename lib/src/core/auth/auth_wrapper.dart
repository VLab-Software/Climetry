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
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Carregando - mostrar splash screen
        if (snapshot.connectionState == ConnectionState.waiting) {
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

        // Verificar autenticação
        final user = snapshot.data;

        // Transição suave entre estados
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: user != null
              ? const MainScaffold(key: ValueKey('main'))
              : const WelcomeScreen(key: ValueKey('welcome')),
        );
      },
    );
  }
}
