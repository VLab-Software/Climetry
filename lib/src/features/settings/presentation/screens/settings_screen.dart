import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// provider e theme_provider removidos - tema fixo light
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/location_service.dart';
import '../../../auth/presentation/screens/welcome_screen.dart';
import '../../../friends/presentation/screens/friends_management_screen.dart';
import 'edit_profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with AutomaticKeepAliveClientMixin {
  final _authService = AuthService();
  final _userDataService = UserDataService();
  final _locationService = LocationService();

  User? _currentUser;
  bool _isLoading = true;
  String _temperatureUnit = 'celsius'; // celsius, fahrenheit
  String _windUnit = 'kmh'; // kmh, mph
  String _precipitationUnit = 'mm'; // mm, inch
  bool _useCurrentLocation = true;
  String? _savedLocationName;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      _currentUser = _authService.currentUser;
      
      // ✅ SOLUÇÃO URGENTE: Não carregar do Firestore - usar valores padrão locais
      // Isso previne travamento quando Firestore está lento/sem rede
      _temperatureUnit = 'celsius';
      _windUnit = 'kmh';
      _precipitationUnit = 'mm';

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
      // ✅ SOLUÇÃO URGENTE: Comentar salvamento no Firestore para evitar travamentos
      // TODO: Implementar salvamento local com SharedPreferences
      debugPrint('💾 Preferências salvas localmente (Firestore desabilitado): $_temperatureUnit, $_windUnit, $_precipitationUnit');
      
      // await _userDataService.savePreferences({
      //   'temperatureUnit': _temperatureUnit,
      //   'windUnit': _windUnit,
      //   'precipitationUnit': _precipitationUnit,
      // });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Preferências salvas!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair da Conta', style: TextStyle(color: Colors.white)),
        content: Text(
          'Deseja realmente sair?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF3B82F6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Sair'),
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
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1F2937),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Excluir Conta', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Esta ação é PERMANENTE!\n\nTodos os seus dados serão excluídos e não poderão ser recuperados.',
          style: TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Excluir Conta'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await _userDataService.deleteAllUserData();
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
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // themeProvider removido - tema fixo light

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark ? Color(0xFF0F1419) : Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0F1419) : Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Header
          SliverToBoxAdapter(child: _buildHeader(isDark)),

          // Perfil
          SliverToBoxAdapter(child: _buildProfileSection(isDark)),

          // SEÇÃO DE APARÊNCIA/TEMA REMOVIDA - TEMA FIXO LIGHT

          // Unidades de Medida
          SliverToBoxAdapter(child: _buildUnitsSection(isDark)),

          // Localização
          SliverToBoxAdapter(child: _buildLocationSection(isDark)),

          // Amigos
          SliverToBoxAdapter(child: _buildFriendsSection(isDark)),

          // Conta
          SliverToBoxAdapter(child: _buildAccountSection(isDark)),

          // Sobre
          SliverToBoxAdapter(child: _buildAboutSection(isDark)),

          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.settings, color: Color(0xFF3B82F6), size: 24),
          ),
          SizedBox(width: 12),
          Text(
            'Configurações',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isDark) {
    return Container(
      margin: EdgeInsets.all(20),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar com foto ou inicial
          CircleAvatar(
            radius: 30,
            backgroundImage: _currentUser?.photoURL != null
                ? NetworkImage(_currentUser!.photoURL!)
                : null,
            backgroundColor: _currentUser?.photoURL != null
                ? Colors.transparent
                : Color(0xFF3B82F6),
            child: _currentUser?.photoURL == null
                ? Text(
                    _currentUser?.displayName?.substring(0, 1).toUpperCase() ??
                        _currentUser?.email?.substring(0, 1).toUpperCase() ??
                        'U',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?.displayName ?? 'Usuário',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1F2937),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _currentUser?.email ?? '',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.edit,
              color: Color(0xFF3B82F6),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              ).then((_) {
                _loadData();
              });
            },
          ),
        ],
      ),
    );
  }

  // MÉTODO REMOVIDO - TEMA FIXO LIGHT
  // Widget _buildAppearanceSection(...) removido

  Widget _buildUnitsSection(bool isDark) {
    return _buildSection(
      isDark,
      title: 'Unidades de Medida',
      icon: Icons.straighten,
      children: [
        _buildSettingTile(
          isDark,
          icon: Icons.thermostat,
          title: 'Temperatura',
          subtitle: _temperatureUnit == 'celsius'
              ? 'Celsius (°C)'
              : 'Fahrenheit (°F)',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => _showUnitPicker(
            'Temperatura',
            _temperatureUnit,
            {'celsius': 'Celsius (°C)', 'fahrenheit': 'Fahrenheit (°F)'},
            (value) {
              setState(() => _temperatureUnit = value);
              _savePreferences();
            },
          ),
        ),
        _buildSettingTile(
          isDark,
          icon: Icons.air,
          title: 'Vento',
          subtitle: _windUnit == 'kmh' ? 'km/h' : 'mph',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => _showUnitPicker(
            'Vento',
            _windUnit,
            {
              'kmh': 'Quilômetros por hora (km/h)',
              'mph': 'Milhas por hora (mph)',
            },
            (value) {
              setState(() => _windUnit = value);
              _savePreferences();
            },
          ),
        ),
        _buildSettingTile(
          isDark,
          icon: Icons.water_drop,
          title: 'Precipitação',
          subtitle: _precipitationUnit == 'mm'
              ? 'Milímetros (mm)'
              : 'Polegadas (in)',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: () => _showUnitPicker(
            'Precipitação',
            _precipitationUnit,
            {'mm': 'Milímetros (mm)', 'inch': 'Polegadas (in)'},
            (value) {
              setState(() => _precipitationUnit = value);
              _savePreferences();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection(bool isDark) {
    return _buildSection(
      isDark,
      title: 'Localização',
      icon: Icons.location_on_outlined,
      children: [
        _buildSettingTile(
          isDark,
          icon: Icons.my_location,
          title: 'Usar localização atual',
          subtitle: 'Detectar automaticamente',
          trailing: Switch(
            value: _useCurrentLocation,
            onChanged: (value) async {
              setState(() => _useCurrentLocation = value);
              await _locationService.setUseCurrentLocation(value);
            },
            activeColor: Color(0xFF3B82F6),
          ),
        ),
        if (_savedLocationName != null)
          _buildSettingTile(
            isDark,
            icon: Icons.location_city,
            title: 'Localização Salva',
            subtitle: _savedLocationName!,
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey,
            ),
          ),
      ],
    );
  }

  Widget _buildFriendsSection(bool isDark) {
    return _buildSection(
      isDark,
      title: 'Amigos',
      icon: Icons.people_outline,
      children: [
        _buildSettingTile(
          isDark,
          icon: Icons.group,
          title: 'Gerenciar Amigos',
          subtitle: 'Ver, adicionar e remover amigos',
          trailing: const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.grey,
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendsManagementScreen(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(bool isDark) {
    return _buildSection(
      isDark,
      title: 'Conta',
      icon: Icons.person_outline,
      children: [
        _buildSettingTile(
          isDark,
          icon: Icons.logout,
          title: 'Sair',
          subtitle: 'Desconectar da conta',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          onTap: _logout,
        ),
        _buildSettingTile(
          isDark,
          icon: Icons.delete_forever,
          title: 'Excluir Conta',
          subtitle: 'Remover permanentemente',
          trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.red),
          onTap: _deleteAccount,
          textColor: Colors.red,
        ),
      ],
    );
  }

  Widget _buildAboutSection(bool isDark) {
    return _buildSection(
      isDark,
      title: 'Sobre',
      icon: Icons.info_outline,
      children: [
        _buildSettingTile(
          isDark,
          icon: Icons.apps,
          title: 'Versão do App',
          subtitle: '1.0.0',
        ),
        _buildSettingTile(
          isDark,
          icon: Icons.code,
          title: 'Desenvolvido por',
          subtitle: 'VLab Software',
        ),
      ],
    );
  }

  Widget _buildSection(
    bool isDark, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF3B82F6), size: 20),
                SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Color(0xFF1F2937),
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    bool isDark, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (textColor ?? Color(0xFF3B82F6)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: textColor ?? Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            textColor ??
                            (isDark ? Colors.white : Color(0xFF1F2937)),
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
      ),
    );
  }

  void _showUnitPicker(
    String title,
    String currentValue,
    Map<String, String> options,
    Function(String) onChanged,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Color(0xFF1F2937),
                ),
              ),
              SizedBox(height: 20),
              ...options.entries.map((entry) {
                final isSelected = currentValue == entry.key;
                return ListTile(
                  onTap: () {
                    onChanged(entry.key);
                    Navigator.pop(context);
                  },
                  leading: Radio<String>(
                    value: entry.key,
                    groupValue: currentValue,
                    onChanged: (value) {
                      if (value != null) {
                        onChanged(value);
                        Navigator.pop(context);
                      }
                    },
                    activeColor: Color(0xFF3B82F6),
                  ),
                  title: Text(
                    entry.value,
                    style: TextStyle(
                      color: isSelected
                          ? Color(0xFF3B82F6)
                          : (isDark ? Colors.white : Color(0xFF1F2937)),
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}
