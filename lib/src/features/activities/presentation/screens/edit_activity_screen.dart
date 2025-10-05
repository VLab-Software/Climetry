import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/widgets/location_autocomplete_field.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/providers/event_refresh_notifier.dart';
import '../../../../core/theme/theme_provider.dart';
import '../widgets/event_participants_selector.dart';
import '../widgets/custom_alerts_settings.dart';
import '../../data/services/event_notification_service.dart';
import '../../../friends/domain/entities/friend.dart';

class EditActivityScreen extends StatefulWidget {
  final Activity activity;

  const EditActivityScreen({super.key, required this.activity});

  @override
  State<EditActivityScreen> createState() => _EditActivityScreenState();
}

class _EditActivityScreenState extends State<EditActivityScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _userDataService = UserDataService();
  final _notificationService = EventNotificationService();

  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  late TextEditingController _tagsController;

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  late LatLng _selectedCoordinates;
  late ActivityType _selectedType;
  late ActivityPriority _selectedPriority;
  late RecurrenceType _selectedRecurrence;
  late List<String> _tags;
  late List<WeatherCondition> _monitoredConditions;
  late List<EventParticipant> _participants;

  bool _isLoading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Pré-preencher com dados existentes
    _titleController = TextEditingController(text: widget.activity.title);
    _locationController =
        TextEditingController(text: widget.activity.location);
    _descriptionController = TextEditingController(
      text: widget.activity.description ?? '',
    );
    _tagsController = TextEditingController();

    _selectedDate = widget.activity.date;
    _selectedCoordinates = widget.activity.coordinates;
    _selectedType = widget.activity.type;
    _selectedPriority = widget.activity.priority;
    _selectedRecurrence = widget.activity.recurrence;
    _tags = List.from(widget.activity.tags);
    _monitoredConditions = List.from(widget.activity.monitoredConditions);
    _participants = List.from(widget.activity.participants);

    // Converter startTime string para TimeOfDay
    if (widget.activity.startTime != null) {
      try {
        final parts = widget.activity.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        _startTime = null;
      }
    }

    // Converter endTime string para TimeOfDay
    if (widget.activity.endTime != null) {
      try {
        final parts = widget.activity.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      } catch (e) {
        _endTime = null;
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _updateActivity() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        // Combinar data com horário de início
        DateTime finalDateTime = _selectedDate;
        if (_startTime != null) {
          finalDateTime = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _startTime!.hour,
            _startTime!.minute,
          );
        }

        final updatedActivity = widget.activity.copyWith(
          title: _titleController.text,
          location: _locationController.text,
          coordinates: _selectedCoordinates,
          date: finalDateTime,
          startTime: _startTime?.format(context),
          endTime: _endTime?.format(context),
          type: _selectedType,
          description: _descriptionController.text.isNotEmpty
              ? _descriptionController.text
              : null,
          priority: _selectedPriority,
          tags: _tags,
          recurrence: _selectedRecurrence,
          monitoredConditions: _monitoredConditions,
          participants: _participants,
        );

        await _userDataService.updateActivity(updatedActivity);

        // Notificar participantes sobre a atualização
        try {
          await _notificationService.notifyEventUpdate(updatedActivity);
        } catch (e) {
          debugPrint('Erro ao enviar notificações: $e');
        }

        if (mounted) {
          // Notificar que o evento foi atualizado
          Provider.of<EventRefreshNotifier>(
            context,
            listen: false,
          ).notifyEventsChanged();

          Navigator.pop(context, updatedActivity);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Evento atualizado com sucesso!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro ao atualizar evento: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final backgroundColor =
        isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Editar Evento',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(Icons.check, color: Colors.blue[700]),
              onPressed: _updateActivity,
              tooltip: 'Salvar alterações',
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue[700],
          unselectedLabelColor: secondaryTextColor,
          indicatorColor: Colors.blue[700],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
          tabs: const [
            Tab(icon: Icon(Icons.info_outline, size: 20), text: 'Geral'),
            Tab(
                icon: Icon(Icons.people_outline, size: 20),
                text: 'Participantes'),
            Tab(
                icon: Icon(Icons.notifications_outlined, size: 20),
                text: 'Alertas'),
            Tab(
                icon: Icon(Icons.settings_outlined, size: 20),
                text: 'Avançado'),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            // ABA 1: GERAL
            _buildGeneralTab(cardColor, textColor, secondaryTextColor, isDark),

            // ABA 2: PARTICIPANTES
            _buildParticipantsTab(
                cardColor, textColor, secondaryTextColor, isDark),

            // ABA 3: ALERTAS CUSTOMIZADOS
            _buildAlertsTab(cardColor, textColor, secondaryTextColor, isDark),

            // ABA 4: AVANÇADO
            _buildAdvancedTab(
                cardColor, textColor, secondaryTextColor, isDark),
          ],
        ),
      ),
    );
  }

  // ===== ABA 1: GERAL =====
  Widget _buildGeneralTab(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card de Informações Básicas
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Informações Básicas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _titleController,
                  label: 'Título do Evento',
                  hint: 'Ex: Reunião com cliente',
                  icon: Icons.title,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  isDark: isDark,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um título';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _descriptionController,
                  label: 'Descrição (Opcional)',
                  hint: 'Adicione detalhes sobre o evento',
                  icon: Icons.description,
                  maxLines: 4,
                  cardColor: cardColor,
                  textColor: textColor,
                  secondaryTextColor: secondaryTextColor,
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card de Tipo e Prioridade
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category_outlined,
                        color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Categoria e Prioridade',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTypePicker(cardColor, textColor, secondaryTextColor),
                const SizedBox(height: 16),
                _buildPriorityPicker(cardColor, textColor, secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card de Data e Hora
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Data e Horário',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildDatePicker(cardColor, textColor, secondaryTextColor),
                const SizedBox(height: 16),
                _buildTimePickers(cardColor, textColor, secondaryTextColor),
                const SizedBox(height: 16),
                _buildRecurrencePicker(cardColor, textColor, secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Card de Localização
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Localização',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildLocationField(cardColor, textColor, secondaryTextColor),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ===== ABA 2: PARTICIPANTES =====
  Widget _buildParticipantsTab(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Gerenciar Participantes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                EventParticipantsSelector(
                  selectedParticipants: _participants,
                  onParticipantsChanged: (participants) {
                    setState(() => _participants = participants);
                  },
                  activityId: widget.activity.id,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== ABA 3: ALERTAS CUSTOMIZADOS =====
  Widget _buildAlertsTab(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return Center(
        child: Text(
          'Erro: usuário não autenticado',
          style: TextStyle(color: textColor),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.notifications_active,
                        color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Meus Alertas Personalizados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Configure alertas personalizados para ser notificado quando as condições climáticas atingirem seus limites',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                CustomAlertsSettings(
                  activity: widget.activity,
                  userId: currentUserId,
                  onSettingsChanged: (settings) {
                    // Atualizar as configurações do participante atual
                    setState(() {
                      final index = _participants
                          .indexWhere((p) => p.userId == currentUserId);
                      if (index != -1) {
                        _participants[index] = _participants[index]
                            .copyWith(customAlertSettings: settings);
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===== ABA 4: AVANÇADO =====
  Widget _buildAdvancedTab(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Monitoramento de Condições Climáticas
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.wb_sunny_outlined,
                        color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Monitoramento Climático',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Selecione quais condições climáticas você deseja monitorar',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _buildWeatherConditionsPicker(
                    cardColor, textColor, secondaryTextColor, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Tags
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.label_outline, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Adicione tags para organizar seus eventos',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTagsField(cardColor, textColor, secondaryTextColor, isDark),
              ],
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  // ===== WIDGETS DE FORMULÁRIO =====

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required bool isDark,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(color: textColor),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
            prefixIcon: Icon(icon, color: Colors.blue[700]),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2A2A2A)
                : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypePicker(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Atividade',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButton<ActivityType>(
            value: _selectedType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: cardColor,
            style: TextStyle(color: textColor, fontSize: 16),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
            items: ActivityType.values.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Row(
                  children: [
                    Text(type.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(type.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedType = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityPicker(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButton<ActivityPriority>(
            value: _selectedPriority,
            isExpanded: true,
            dropdownColor: cardColor,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: 16),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
            items: ActivityPriority.values.map((priority) {
              return DropdownMenuItem(
                value: priority,
                child: Row(
                  children: [
                    Text(priority.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(priority.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedPriority = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecurrencePicker(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repetir',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: DropdownButton<RecurrenceType>(
            value: _selectedRecurrence,
            isExpanded: true,
            dropdownColor: cardColor,
            underline: const SizedBox(),
            style: TextStyle(color: textColor, fontSize: 16),
            icon: Icon(Icons.arrow_drop_down, color: Colors.blue[700]),
            items: RecurrenceType.values.map((recurrence) {
              return DropdownMenuItem(
                value: recurrence,
                child: Row(
                  children: [
                    Text(recurrence.icon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(recurrence.label),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRecurrence = value);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDatePicker(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: ColorScheme.light(
                      primary: Colors.blue[700]!,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickers(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Início',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.blue[700]!,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        _startTime?.format(context) ?? '--:--',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fim (Opcional)',
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? TimeOfDay.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Colors.blue[700]!,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() => _endTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Text(
                        _endTime?.format(context) ?? '--:--',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField(
      Color cardColor, Color textColor, Color secondaryTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localização',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LocationAutocompleteField(
          controller: _locationController,
          onLocationSelected: (suggestion) {
            setState(() {
              _selectedCoordinates = suggestion.coordinates;
            });
          },
        ),
      ],
    );
  }

  Widget _buildWeatherConditionsPicker(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: WeatherCondition.values.map((condition) {
        final isSelected = _monitoredConditions.contains(condition);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? Colors.blue[700]!
                  : Colors.grey.withOpacity(0.2),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: CheckboxListTile(
            value: isSelected,
            onChanged: (checked) {
              setState(() {
                if (checked == true) {
                  _monitoredConditions.add(condition);
                } else {
                  _monitoredConditions.remove(condition);
                }
              });
            },
            title: Row(
              children: [
                Text(condition.icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Text(
                  condition.label,
                  style: TextStyle(color: textColor, fontSize: 16),
                ),
              ],
            ),
            checkColor: Colors.white,
            activeColor: Colors.blue[700],
            side: BorderSide.none,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTagsField(
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _tagsController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Digite uma tag e pressione Enter',
            hintStyle: TextStyle(color: secondaryTextColor.withOpacity(0.5)),
            filled: true,
            fillColor: isDark
                ? const Color(0xFF2A2A2A)
                : Colors.grey.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.add, color: Colors.blue[700]),
              onPressed: () {
                final tag = _tagsController.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                    _tagsController.clear();
                  });
                }
              },
            ),
          ),
          onSubmitted: (value) {
            final tag = value.trim();
            if (tag.isNotEmpty && !_tags.contains(tag)) {
              setState(() {
                _tags.add(tag);
                _tagsController.clear();
              });
            }
          },
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                labelStyle: const TextStyle(color: Colors.white),
                backgroundColor: Colors.blue[700],
                deleteIcon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Colors.white,
                ),
                onDeleted: () {
                  setState(() => _tags.remove(tag));
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
