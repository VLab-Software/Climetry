import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import '../../../disasters/presentation/widgets/location_picker_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _userDataService = UserDataService();
  final _locationService = LocationService();
  String _appVersion = '1.0.0';
  
  Map<String, dynamic> _preferences = {};
  User? _currentUser;
  bool _isLoading = true;
  bool _useCurrentLocation = true;
  String? _savedLocationName;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _currentUser = _authService.currentUser;
      if (_currentUser != null) {
        _preferences = await _userDataService.getPreferences();
      }
      
      // Carregar configurações de localização
      _useCurrentLocation = await _locationService.shouldUseCurrentLocation();
      final savedLocation = await _locationService.getSavedLocation();
      _savedLocationName = savedLocation?['name'];
    } catch (e) {
      debugPrint('Erro ao carregar dados: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _savePreferences() async {
    try {
      await _userDataService.savePreferences(_preferences);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferências salvas!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A3A4D),
        title: const Text('Sair', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Tem certeza que deseja sair?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao sair: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A3A4D),
        title: const Text('Excluir Conta', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Esta ação é permanente! Todos os seus dados serão excluídos. Deseja continuar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        // Deletar dados do Firestore
        await _userDataService.deleteAllUserData();
        // Deletar conta do Firebase Auth
        await _authService.deleteAccount();
        
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _changePassword() async {
    final controller = TextEditingController();
    
    final newPassword = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A3A4D),
        title: const Text('Nova Senha', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          obscureText: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Nova senha (mín. 6 caracteres)',
            labelStyle: const TextStyle(color: Colors.white70),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A9EFF),
            ),
            child: const Text('Alterar'),
          ),
        ],
      ),
    );

    if (newPassword != null && newPassword.isNotEmpty && mounted) {
      try {
        await _authService.updatePassword(newPassword);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Senha alterada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1E2A3A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF4A9EFF)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        title: const Text('Configurações'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Padding para floating tab bar
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Perfil
            _buildSectionTitle('Perfil'),
            _buildProfileCard(),
            const SizedBox(height: 24),

            // Localização
            _buildSectionTitle('Localização'),
            _buildSwitchCard(
              '📍',
              'Usar Minha Localização',
              _useCurrentLocation,
              _toggleLocationMode,
            ),
            if (_savedLocationName != null)
              _buildSettingCard(
                '🏙️',
                'Localização Salva',
                _savedLocationName!,
                _showLocationOptions,
              )
            else
              _buildSettingCard(
                '➕',
                'Adicionar Localização',
                'Escolha uma localização personalizada',
                _pickLocation,
              ),
            const SizedBox(height: 24),

            // Conta
            _buildSectionTitle('Conta'),
            _buildSettingCard(
              '�',
              'Alterar Senha',
              'Modifique sua senha',
              _changePassword,
            ),
            const SizedBox(height: 24),

            // Unidades
            _buildSectionTitle('Unidades de Medida'),
            _buildSettingCard(
              '🌡️',
              'Temperatura',
              _preferences['temperatureUnit'] ?? 'Celsius (°C)',
              () => _showUnitDialog('Temperatura', 'temperatureUnit', ['Celsius (°C)', 'Fahrenheit (°F)']),
            ),
            _buildSettingCard(
              '💨',
              'Velocidade do Vento',
              _preferences['windSpeedUnit'] ?? 'km/h',
              () => _showUnitDialog('Velocidade do Vento', 'windSpeedUnit', ['km/h', 'm/s', 'mph']),
            ),
            _buildSettingCard(
              '☔',
              'Precipitação',
              _preferences['precipitationUnit'] ?? 'milímetros (mm)',
              () => _showUnitDialog('Precipitação', 'precipitationUnit', ['milímetros (mm)', 'polegadas (in)']),
            ),
            const SizedBox(height: 24),

            // Notificações
            _buildSectionTitle('Notificações'),
            _buildSwitchCard(
              '🔔',
              'Ativar Notificações',
              _preferences['notificationsEnabled'] == true,
              (value) {
                setState(() {
                  _preferences['notificationsEnabled'] = value;
                });
                _savePreferences();
              },
            ),
            _buildSwitchCard(
              '�',
              'Som',
              _preferences['soundEnabled'] == true,
              (value) {
                setState(() {
                  _preferences['soundEnabled'] = value;
                });
                _savePreferences();
              },
            ),
            _buildSwitchCard(
              '�',
              'Vibração',
              _preferences['vibrationEnabled'] == true,
              (value) {
                setState(() {
                  _preferences['vibrationEnabled'] = value;
                });
                _savePreferences();
              },
            ),
            const SizedBox(height: 24),

            // Sobre
            _buildSectionTitle('Sobre'),
            _buildSettingCard(
              '📱',
              'Versão do App',
              _appVersion,
              null,
            ),
            const SizedBox(height: 24),

            // Botões de ação
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: _logout,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A9EFF),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Sair da Conta',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _deleteAccount,
                    child: const Text(
                      'Excluir Conta',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    final userName = _currentUser?.displayName ?? 'Usuário';
    final userEmail = _currentUser?.email ?? 'email@example.com';
    final firstLetter = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: const Color(0xFF4A9EFF),
            child: Text(
              firstLetter,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(
    String icon,
    String title,
    String subtitle,
    VoidCallback? onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchCard(
    String icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A3A4D),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(icon, style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF4A9EFF),
          ),
        ],
      ),
    );
  }

  void _showUnitDialog(String title, String preferenceKey, List<String> options) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2A3A4D),
          title: Text(
            title,
            style: const TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.map((option) {
              return ListTile(
                title: Text(
                  option,
                  style: const TextStyle(color: Colors.white),
                ),
                onTap: () {
                  setState(() {
                    _preferences[preferenceKey] = option;
                  });
                  _savePreferences();
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
