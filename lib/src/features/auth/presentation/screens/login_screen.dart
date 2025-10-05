import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/services/auth_service.dart';
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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb;
    final isDesktop = size.width > 900;
    final isTablet = size.width > 600 && size.width <= 900;

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 0 : (isTablet ? 40 : 24),
              vertical: 32,
            ),
            child: _buildResponsiveLayout(isDesktop, isTablet, isWeb),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(bool isDesktop, bool isTablet, bool isWeb) {
    if (isDesktop) {
      // Layout Desktop (2 colunas)
      return Container(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildWelcomeSection(isLarge: true),
            ),
            const SizedBox(width: 80),
            Expanded(
              flex: 1,
              child: _buildLoginForm(isWeb: isWeb, maxWidth: 450),
            ),
          ],
        ),
      );
    } else if (isTablet) {
      // Layout Tablet (single column, mais espaçoso)
      return Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Column(
          children: [
            _buildWelcomeSection(isLarge: false),
            const SizedBox(height: 48),
            _buildLoginForm(isWeb: isWeb, maxWidth: 500),
          ],
        ),
      );
    } else {
      // Layout Mobile (compact)
      return Column(
        children: [
          _buildWelcomeSection(isLarge: false),
          const SizedBox(height: 32),
          _buildLoginForm(isWeb: isWeb, maxWidth: double.infinity),
        ],
      );
    }
  }

  Widget _buildWelcomeSection({required bool isLarge}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.cloud,
          size: isLarge ? 80 : 60,
          color: const Color(0xFF4A9EFF),
        ),
        SizedBox(height: isLarge ? 32 : 24),
        Text(
          'Bem-vindo ao',
          style: TextStyle(
            color: Colors.white70,
            fontSize: isLarge ? 24 : 18,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Climetry',
          style: TextStyle(
            color: Colors.white,
            fontSize: isLarge ? 56 : 42,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: isLarge ? 24 : 16),
        Text(
          'Análise climática inteligente\npara seus eventos',
          style: TextStyle(
            color: Colors.white60,
            fontSize: isLarge ? 18 : 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm({required bool isWeb, required double maxWidth}) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título do formulário
            Text(
              'Entrar na conta',
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 32 : 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Acesse sua conta para continuar',
              style: TextStyle(
                color: Colors.white60,
                fontSize: isWeb ? 16 : 14,
              ),
            ),
            const SizedBox(height: 40),

            // Campo Email
            _buildTextField(
              controller: _emailController,
              label: 'Email',
              hint: 'seu@email.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite seu email';
                }
                if (!value.contains('@')) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Campo Senha
            _buildTextField(
              controller: _passwordController,
              label: 'Senha',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscurePassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite sua senha';
                }
                if (value.length < 6) {
                  return 'Senha deve ter no mínimo 6 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // Botão Entrar
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _signInWithEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A9EFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Entrar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Divisor
            Row(
              children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'ou',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.2))),
              ],
            ),
            const SizedBox(height: 24),

            // Botão Criar Conta
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Criar nova conta',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
            prefixIcon: Icon(icon, color: Colors.white54),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF4A9EFF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
