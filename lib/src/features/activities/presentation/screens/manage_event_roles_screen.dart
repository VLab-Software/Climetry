import 'package:flutter/material.dart';
import '../../../activities/domain/entities/activity.dart';
import '../../../activities/data/repositories/activity_repository.dart';
import '../../../friends/domain/entities/friend.dart';

/// Tela para o DONO do evento gerenciar permissões dos participantes
/// Permite promover participantes a Admin ou Moderator
class ManageEventRolesScreen extends StatefulWidget {
  final Activity activity;

  const ManageEventRolesScreen({super.key, required this.activity});

  @override
  State<ManageEventRolesScreen> createState() => _ManageEventRolesScreenState();
}

class _ManageEventRolesScreenState extends State<ManageEventRolesScreen> {
  final _activityRepository = ActivityRepository();
  late List<EventParticipant> _participants;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _participants = List.from(widget.activity.participants);
  }

  Future<void> _updateParticipantRole(
    EventParticipant participant,
    EventRole newRole,
  ) async {
    setState(() => _isLoading = true);

    try {
      // Atualizar role do participante
      final updatedParticipant = participant.copyWith(role: newRole);
      
      // Substituir na lista
      final updatedParticipants = _participants.map((p) {
        return p.userId == participant.userId ? updatedParticipant : p;
      }).toList();

      // Atualizar atividade
      final updatedActivity = widget.activity.copyWith(
        participants: updatedParticipants,
      );

      await _activityRepository.update(updatedActivity);

      setState(() {
        _participants = updatedParticipants;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${participant.name} agora é ${newRole.label}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar permissão: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.grey[50],
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E2A3A) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Gerenciar Permissões',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _participants.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum participante',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Convide amigos para o evento',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Informações
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF3B82F6).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Defina quem pode editar e gerenciar este evento',
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Lista de participantes
                    ..._participants.map((participant) {
                      return _buildParticipantCard(participant, isDark);
                    }).toList(),
                  ],
                ),
    );
  }

  Widget _buildParticipantCard(EventParticipant participant, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A3A4D) : const Color(0xFF2D3E50),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com foto e nome
          Row(
            children: [
              // Foto do usuário
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF3B82F6),
                backgroundImage: participant.photoUrl != null
                    ? NetworkImage(participant.photoUrl!)
                    : null,
                child: participant.photoUrl == null
                    ? Text(
                        participant.name[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Nome e status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      participant.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildRoleBadge(participant.role),
                        const SizedBox(width: 8),
                        Text(
                          '• ${participant.status.label}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Botões de ação (se não for owner)
          if (participant.role != EventRole.owner) ...[
            const SizedBox(height: 16),
            const Divider(color: Colors.white24, height: 1),
            const SizedBox(height: 16),

            // Opções de permissão
            const Text(
              'Alterar permissão:',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildRoleButton(
                  participant,
                  EventRole.admin,
                  'Administrador',
                  'Pode editar e convidar',
                  Icons.admin_panel_settings,
                ),
                _buildRoleButton(
                  participant,
                  EventRole.moderator,
                  'Moderador',
                  'Pode convidar pessoas',
                  Icons.shield_outlined,
                ),
                _buildRoleButton(
                  participant,
                  EventRole.participant,
                  'Participante',
                  'Apenas participa',
                  Icons.person_outline,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleBadge(EventRole role) {
    Color color;
    IconData icon;

    switch (role) {
      case EventRole.owner:
        color = const Color(0xFFFFD700); // Dourado
        icon = Icons.stars;
        break;
      case EventRole.admin:
        color = const Color(0xFFFF6B6B); // Vermelho
        icon = Icons.admin_panel_settings;
        break;
      case EventRole.moderator:
        color = const Color(0xFF4ECDC4); // Turquesa
        icon = Icons.shield;
        break;
      case EventRole.participant:
        color = Colors.grey;
        icon = Icons.person;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(
    EventParticipant participant,
    EventRole role,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = participant.role == role;

    return InkWell(
      onTap: isSelected ? null : () => _updateParticipantRole(participant, role),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6).withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? const Color(0xFF3B82F6) : Colors.white70,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: isSelected
                        ? const Color(0xFF3B82F6).withOpacity(0.8)
                        : Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
