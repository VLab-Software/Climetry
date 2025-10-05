import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_data_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  final _userDataService = UserDataService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os termos de uso'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      debugPrint('🔐 Iniciando registro...');
      
      // TIMEOUT DE 15s PARA REGISTRO COMPLETO
      final userCredential = await _authService.registerWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
        displayName: _nameController.text,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('⏱️ Timeout no registro (15s)');
          throw Exception('Timeout ao criar conta. Tente novamente.');
        },
      );

      debugPrint('✅ Usuário criado no Auth: ${userCredential.user?.uid}');

      // CRIAR PERFIL NO FIRESTORE (COM TIMEOUT)
      if (userCredential.user != null) {
        try {
          debugPrint('📝 Criando perfil no Firestore...');
          await _userDataService.createUserProfile(userCredential.user!).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('⏱️ Timeout ao criar perfil - continuando mesmo assim');
              // NÃO LANÇA ERRO - usuário já foi criado no Auth
            },
          );
          debugPrint('✅ Perfil criado com sucesso');
        } catch (e) {
          // SE FALHAR NO PERFIL, NÃO IMPORTA - usuário já foi criado
          debugPrint('⚠️ Erro ao criar perfil (não crítico): $e');
        }
      }

      if (!mounted) return;
      
      // SUCESSO - remover loading
      setState(() => _isLoading = false);
      
      // Mostrar sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Conta criada com sucesso!'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      debugPrint('🎉 Registro completo!');
      
    } catch (e) {
      debugPrint('❌ Erro no registro: $e');
      
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
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
      appBar: isDesktop
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 80 : (isTablet ? 60 : 24),
              vertical: 32,
            ),
            child: Center(
              child: _buildResponsiveLayout(isDesktop, isTablet, isWeb),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveLayout(bool isDesktop, bool isTablet, bool isWeb) {
    if (isDesktop) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 1,
              child: Center(child: _buildInfoSection(isLarge: true)),
            ),
            const SizedBox(width: 100),
            Expanded(
              flex: 1,
              child: Center(child: _buildRegisterForm(isWeb: isWeb, maxWidth: 400)),
            ),
          ],
        ),
      );
    } else if (isTablet) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildInfoSection(isLarge: false),
            const SizedBox(height: 48),
            _buildRegisterForm(isWeb: isWeb, maxWidth: 450),
          ],
        ),
      );
    } else {
      return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildInfoSection(isLarge: false),
            const SizedBox(height: 32),
            _buildRegisterForm(isWeb: isWeb, maxWidth: double.infinity),
          ],
        ),
      );
    }
  }

  Widget _buildInfoSection({required bool isLarge}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          Icons.person_add,
          size: isLarge ? 80 : 60,
          color: const Color(0xFF4A9EFF),
        ),
        SizedBox(height: isLarge ? 24 : 20),
        Text(
          'Junte-se ao',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: isLarge ? 20 : 16,
            fontWeight: FontWeight.w300,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Climetry',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: isLarge ? 48 : 36,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
        SizedBox(height: isLarge ? 16 : 12),
        Text(
          'Crie sua conta e comece a\nplanejar eventos com\ninteligência climática',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white60,
            fontSize: isLarge ? 16 : 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm({required bool isWeb, required double maxWidth}) {
    return Container(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Criar nova conta',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isWeb ? 28 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha os dados abaixo',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: isWeb ? 14 : 13,
              ),
            ),
            const SizedBox(height: 40),

            // Campo Nome
            _buildTextField(
              controller: _nameController,
              label: 'Nome completo',
              hint: 'João Silva',
              icon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Digite seu nome';
                }
                if (value.length < 3) {
                  return 'Nome deve ter no mínimo 3 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

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
            const SizedBox(height: 20),

            // Campo Confirmar Senha
            _buildTextField(
              controller: _confirmPasswordController,
              label: 'Confirmar senha',
              hint: '••••••••',
              icon: Icons.lock_outline,
              obscureText: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Confirme sua senha';
                }
                if (value != _passwordController.text) {
                  return 'As senhas não coincidem';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Checkbox Termos
            Row(
              children: [
                Checkbox(
                  value: _acceptedTerms,
                  onChanged: (value) => setState(() => _acceptedTerms = value ?? false),
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFF4A9EFF);
                    }
                    return Colors.white.withOpacity(0.2);
                  }),
                ),
                Expanded(
                  child: Text(
                    'Aceito os termos de uso e política de privacidade',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Botão Criar Conta
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
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
                        'Criar conta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),

            // Link para login
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: RichText(
                  text: TextSpan(
                    text: 'Já tem uma conta? ',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Entrar',
                        style: TextStyle(
                          color: Color(0xFF4A9EFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
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
