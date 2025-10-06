import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../disasters/presentation/widgets/location_picker_widget.dart';
import '../../../../core/widgets/location_autocomplete_field.dart';
import '../../../../core/providers/event_refresh_notifier.dart';
import '../../../friends/domain/entities/friend.dart';
import '../widgets/event_participants_selector.dart';

class NewActivityScreen extends StatefulWidget {
  const NewActivityScreen({super.key});

  @override
  State<NewActivityScreen> createState() => _NewActivityScreenState();
}

class _NewActivityScreenState extends State<NewActivityScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  ActivityType _selectedType = ActivityType.other;
  ActivityPriority _selectedPriority = ActivityPriority.low;
  RecurrenceType _selectedRecurrence = RecurrenceType.none;
  List<String> _tags = [];
  List<WeatherCondition> _monitoredConditions = [
    WeatherCondition.temperature,
    WeatherCondition.rain,
  ];
  LatLng _selectedCoordinates = const LatLng(-23.5505, -46.6333);
  List<EventParticipant> _selectedParticipants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _selectLocation() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: LocationPickerWidget(
          initialLocation: _selectedCoordinates,
          initialLocationName: _locationController.text,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (result['location'] != null) {
          _selectedCoordinates = result['location'] as LatLng;
        }
        if (result['name'] != null && (result['name'] as String).isNotEmpty) {
          _locationController.text = result['name'] as String;
        }
      });
    }
  }
  
  Future<void> _selectParticipants() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: EventParticipantsSelector(
          selectedParticipants: _selectedParticipants,
          onChanged: (participants) {
            setState(() {
              _selectedParticipants = participants;
            });
          },
        ),
      ),
    );
  }

  void _saveActivity() {
    if (_formKey.currentState!.validate()) {
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

      final activity = Activity(
        id: const Uuid().v4(),
        ownerId: FirebaseAuth.instance.currentUser!.uid,
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
        participants: _selectedParticipants,
      );

      Provider.of<EventRefreshNotifier>(
        context,
        listen: false,
      ).notifyEventsChanged();

      Navigator.pop(context, activity);
    }
  }


  Widget _buildGeneralTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _titleController,
            label: 'Nome da Atividade',
            hint: 'Churrasco com Amigos',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor, insira um nome';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildLocationAutocompleteField(),
          const SizedBox(height: 16),
          _buildDateTimePicker(),
          const SizedBox(height: 16),
          _buildTypePicker(),
          const SizedBox(height: 16),
          _buildPriorityPicker(),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _descriptionController,
            label: 'Descrição (Opcional)',
            hint: 'Adicione mais detalhes...',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Participantes do Evento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Convide amigos para participar deste evento',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildParticipantsSelector(),
        ],
      ),
    );
  }

  Widget _buildAlertsTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Alertas Climáticos',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione as condições climáticas que você deseja monitorar',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          _buildWeatherConditionsPicker(),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildRecurrencePicker(),
          const SizedBox(height: 20),
          _buildTagsField(),
        ],
      ),
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A3A4D) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saveActivity,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text(
              'Criar Evento',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Nova Atividade',
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF4A9EFF),
            unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
            indicatorColor: const Color(0xFF4A9EFF),
            indicatorWeight: 3,
            tabs: const [
              Tab(icon: Icon(Icons.info_outline, size: 24)),
              Tab(icon: Icon(Icons.group_outlined, size: 24)),
              Tab(icon: Icon(Icons.notifications_outlined, size: 24)),
              Tab(icon: Icon(Icons.settings_outlined, size: 24)),
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(isDark),
                  _buildParticipantsTab(isDark),
                  _buildAlertsTab(isDark),
                  _buildAdvancedTab(isDark),
                ],
              ),
            ),
            _buildSaveButton(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? prefixIcon,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          maxLines: maxLines,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white.withOpacity(0.3) : Colors.grey[500],
              fontSize: 15,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isDark ? Colors.white60 : Colors.grey[600],
                  )
                : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: isDark ? const Color(0xFF2A3A4D) : const Color(0xFF2D3E50),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsSelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participantes',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectParticipants,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A3A4D) : const Color(0xFF2D3E50),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedParticipants.isNotEmpty
                    ? const Color(0xFF3B82F6)
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.people,
                  color: _selectedParticipants.isNotEmpty
                      ? const Color(0xFF3B82F6)
                      : (isDark ? Colors.white60 : Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedParticipants.isEmpty
                        ? 'Convidar amigos (opcional)'
                        : '${_selectedParticipants.length} ${_selectedParticipants.length == 1 ? "convidado" : "convidados"}',
                    style: TextStyle(
                      color: _selectedParticipants.isNotEmpty
                          ? Colors.white
                          : Colors.white60,
                      fontSize: 16,
                    ),
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, color: Colors.white60, size: 16),
              ],
            ),
          ),
        ),
        if (_selectedParticipants.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedParticipants.map((participant) {
                return Chip(
                  avatar: CircleAvatar(
                    backgroundImage: participant.photoUrl != null
                        ? NetworkImage(participant.photoUrl!)
                        : null,
                    backgroundColor: const Color(0xFF4A9EFF),
                    child: participant.photoUrl == null
                        ? Text(
                            participant.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          )
                        : null,
                  ),
                  label: Text(
                    '${participant.name} ${participant.role == EventRole.admin ? "👑" : participant.role == EventRole.moderator ? "🎖️" : ""}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: const Color(0xFF2A3A4D),
                  labelStyle: const TextStyle(color: Colors.white),
                  deleteIcon: const Icon(Icons.close, size: 16, color: Colors.white60),
                  onDeleted: () {
                    setState(() {
                      _selectedParticipants.removeWhere((p) => p.userId == participant.userId);
                    });
                  },
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLocationAutocompleteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        LocationAutocompleteField(
          controller: _locationController,
          hintText: 'Digite o nome da cidade...',
          prefixIcon: Icons.search,
          suffixIcon: IconButton(
            icon: const Icon(Icons.map, color: Color(0xFF4A9EFF)),
            onPressed: _selectLocation,
          ),
          onLocationSelected: (suggestion) {
            setState(() {
              _selectedCoordinates = suggestion.coordinates;
              _locationController.text = suggestion.displayName;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Localização selecionada: ${suggestion.displayName}',
                      ),
                    ),
                  ],
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: const Color(0xFF2A3A4D),
              ),
            );
          },
          backgroundColor: const Color(0xFF2A3A4D),
          textColor: Colors.white,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Por favor, insira uma localização';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Data e Horário',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildPickerButton(
                icon: Icons.calendar_today,
                label:
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                onTap: _selectDate,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPickerButton(
                icon: Icons.access_time,
                label: _startTime?.format(context) ?? 'Hora',
                onTap: _selectStartTime,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Atividade',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3A4D) : const Color(0xFF2D3E50),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<ActivityType>(
            value: _selectedType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: isDark ? const Color(0xFF2A3A4D) : const Color(0xFF2D3E50),
            style: TextStyle(
              color: isDark ? Colors.white : Colors.white,
              fontSize: 16,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: isDark ? Colors.white60 : Colors.white70,
            ),
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

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A3A4D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white60, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prioridade',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<ActivityPriority>(
            value: _selectedPriority,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E1E),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
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

  Widget _buildRecurrencePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repetir',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<RecurrenceType>(
            value: _selectedRecurrence,
            isExpanded: true,
            dropdownColor: const Color(0xFF1E1E1E),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
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

  Widget _buildWeatherConditionsPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitorar Condições Climáticas',
          style: TextStyle(
            color: isDark ? Colors.grey[400] : Colors.grey[700],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A3A4D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey[300]!,
            ),
          ),
          child: Column(
            children: WeatherCondition.values.map((condition) {
              final isSelected = _monitoredConditions.contains(condition);
              return CheckboxListTile(
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
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                checkColor: Colors.white,
                activeColor: const Color(0xFF3B82F6),
                side: BorderSide(
                  color: isDark ? Colors.white24 : Colors.grey[400]!,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              TextField(
                controller: _tagsController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Digite uma tag e pressione Enter',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add, color: Colors.blue),
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
              if (_tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _tags.map((tag) {
                      return Chip(
                        label: Text(tag),
                        labelStyle: const TextStyle(color: Colors.white),
                        backgroundColor: Colors.blue.withOpacity(0.3),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white60,
                        ),
                        onDeleted: () {
                          setState(() => _tags.remove(tag));
                        },
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
