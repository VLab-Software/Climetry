import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../app_new.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        debugPrint('🔄 Auth state changed: ${user?.email ?? "null"} (uid: ${user?.uid ?? "null"})');
        setState(() {});
      }
    });
    
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
        
        if (user != null) {
          debugPrint('✅ User detected, loading MainScaffold');
          return const MainScaffold(key: ValueKey('main'));
        }
        
        if (connectionState == ConnectionState.waiting && user == null) {
          debugPrint('⏳ Aguardando autenticação inicial...');
          return const Scaffold(
            backgroundColor: Color(0xFF1E2A3A),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
                    'Error loading',
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

        final currentUser = snapshot.data;
        if (currentUser != null) {
          debugPrint('✅ User detected: ${currentUser.email}');
          return const MainScaffold(key: ValueKey('main'));
        }

        debugPrint('🚪 No user, mostrando WelcomeScreen');
        return const WelcomeScreen(key: ValueKey('welcome'));
      },
    );
  }
}
