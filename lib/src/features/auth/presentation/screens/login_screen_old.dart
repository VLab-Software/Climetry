import 'package:flutter/material.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_data_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _userDateService = UserDateService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await _authService.signInWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);
      
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
        // ignore: undefined_method
        final userCredential = await _authService.signInWithGoogle();

      if (userCredential.user != null) {
        await _userDateService.createUserProfile(userCredential.user!);
      }

      if (!mounted) return;

      setState(() => _isLoading = false);
      
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                const Text(
                  'Bem-vindo de volta!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Entre para continuar',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 40),

                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                      color: Colors.white60,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A3A4D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Email inválido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                      color: Colors.white60,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.white60,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    filled: true,
                    fillColor: const Color(0xFF2A3A4D),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color(0xFF4A9EFF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signInWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9EFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(color: Colors.white.withOpacity(0.5)),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.white.withOpacity(0.2)),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      width: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.g_mobiledata,
                          color: Colors.white,
                          size: 24,
                        );
                      },
                    ),
                    label: const Text(
                      'Login com Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Do not have an account? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.7)),
                    ),
                    TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                      child: const Text(
                        'Cadastre-se',
                        style: TextStyle(
                          color: Color(0xFF4A9EFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A3A4D),
        title: const Text(
          'Recuperar Password',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email para receber instruções de recuperação',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF1E2A3A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;

              try {
                await _authService.sendPasswordResetEmail(emailController.text);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email de recuperação enviado!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EFF),
            ),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
