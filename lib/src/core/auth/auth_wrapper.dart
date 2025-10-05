import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../app_new.dart';

/// Widget que gerencia o estado de autenticação
/// Redireciona para Welcome se não autenticado, ou para Home se autenticado
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Carregando
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF1E2A3A),
            body: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4A9EFF)),
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
                  const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 60,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        // Verificar autenticação
        final user = snapshot.data;

        // Se estiver autenticado, mostrar app principal
        if (user != null) {
          return const MainScaffold();
        }

        // Se não estiver autenticado, mostrar tela de boas-vindas
        return const WelcomeScreen();
      },
    );
  }
}
