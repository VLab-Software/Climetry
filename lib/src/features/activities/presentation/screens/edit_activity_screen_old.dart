import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../../core/widgets/location_autocomplete_field.dart';
import '../../../../core/services/user_data_service.dart';
import '../../../../core/services/custom_alerts_service.dart';
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

class _EditActivityScreenState extends State<EditActivityScreen> {
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
  late Map<String, CustomAlert> _customAlerts;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Pré-preencher com dados existentes
    _titleController = TextEditingController(text: widget.activity.title);
    _locationController = TextEditingController(text: widget.activity.location);
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
    _customAlerts = Map.from(widget.activity.customAlerts);

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
        );

        await _userDataService.updateActivity(updatedActivity);

        if (mounted) {
          // Notificar que o evento foi atualizado
          Provider.of<EventRefreshNotifier>(
            context,
            listen: false,
          ).notifyEventsChanged();

          Navigator.pop(context, updatedActivity);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Evento atualizado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao atualizar evento: $e'),
              backgroundColor: Colors.red,
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
    return Scaffold(
      backgroundColor: const Color(0xFF1E2A3A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2A3A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar Evento'),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _updateActivity,
              tooltip: 'Salvar alterações',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                controller: _titleController,
                label: 'Título do Evento',
                hint: 'Ex: Reunião com cliente',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, insira um título';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTypePicker(),
              const SizedBox(height: 16),

              _buildPriorityPicker(),
              const SizedBox(height: 16),

              _buildRecurrencePicker(),
              const SizedBox(height: 16),

              _buildDatePicker(),
              const SizedBox(height: 16),

              _buildTimePickers(),
              const SizedBox(height: 16),

              _buildLocationField(),
              const SizedBox(height: 16),

              _buildWeatherConditionsPicker(),
              const SizedBox(height: 16),

              _buildTagsField(),
              const SizedBox(height: 16),

              _buildTextField(
                controller: _descriptionController,
                label: 'Descrição (Opcional)',
                hint: 'Adicione detalhes sobre o evento',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: const Color(0xFF2A3A4D),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTypePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tipo de Atividade',
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
            color: const Color(0xFF2A3A4D),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButton<ActivityType>(
            value: _selectedType,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: const Color(0xFF2A3A4D),
            style: const TextStyle(color: Colors.white, fontSize: 16),
            icon: const Icon(Icons.arrow_drop_down, color: Colors.white60),
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

  Widget _buildDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
            );
            if (picked != null) {
              setState(() => _selectedDate = picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2A3A4D),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white60),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePickers() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Início',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _startTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _startTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3A4D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white60),
                      const SizedBox(width: 8),
                      Text(
                        _startTime?.format(context) ?? '--:--',
                        style: const TextStyle(
                          color: Colors.white,
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
                  color: Colors.grey[400],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _endTime ?? TimeOfDay.now(),
                  );
                  if (picked != null) {
                    setState(() => _endTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3A4D),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white60),
                      const SizedBox(width: 8),
                      Text(
                        _endTime?.format(context) ?? '--:--',
                        style: const TextStyle(
                          color: Colors.white,
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

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Localização',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
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

  Widget _buildWeatherConditionsPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monitorar Condições Climáticas',
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
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                checkColor: Colors.black,
                activeColor: Colors.blue,
                side: const BorderSide(color: Colors.white24),
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
