import 'package:flutter/material.dart';
import '../../../friends/domain/entities/friend.dart';
import '../../../friends/data/services/friends_service.dart';

class EventParticipantsSelector extends StatefulWidget {
  final List<EventParticipant> selectedParticipants;
  final Function(List<EventParticipant>) onChanged;
  final String? ownerId; // ID do owner para mostrar badge

  const EventParticipantsSelector({
    super.key,
    required this.selectedParticipants,
    required this.onChanged,
    this.ownerId,
  });

  @override
  State<EventParticipantsSelector> createState() => _EventParticipantsSelectorState();
}

class _EventParticipantsSelectorState extends State<EventParticipantsSelector> {
  final FriendsService _friendsService = FriendsService();
  List<Friend> _friends = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);
    try {
      final friends = await _friendsService.getFriends();
      setState(() {
        _friends = friends;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  bool _isSelected(String friendId) {
    return widget.selectedParticipants.any((p) => p.userId == friendId);
  }

  EventRole? _getRole(String friendId) {
    final participant = widget.selectedParticipants
        .where((p) => p.userId == friendId)
        .firstOrNull;
    return participant?.role;
  }

  void _toggleParticipant(Friend friend) {
    final isSelected = _isSelected(friend.id);
    final updated = List<EventParticipant>.from(widget.selectedParticipants);

    if (isSelected) {
      updated.removeWhere((p) => p.userId == friend.id);
    } else {
      updated.add(EventParticipant(
        userId: friend.id,
        name: friend.name,
        photoUrl: friend.photoUrl,
        role: EventRole.participant,
        joinedAt: DateTime.now(),
        status: ParticipantStatus.pending,
      ));
    }

    widget.onChanged(updated);
  }

  void _changeRole(String friendId, EventRole newRole) {
    final updated = widget.selectedParticipants.map((p) {
      if (p.userId == friendId) {
        return p.copyWith(role: newRole);
      }
      return p;
    }).toList();

    widget.onChanged(updated);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  'Convidar Amigos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
                const Spacer(),
                if (widget.selectedParticipants.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${widget.selectedParticipants.length} selecionado(s)',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Lista de amigos
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF3B82F6),
                    ),
                  )
                : _friends.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhum amigo encontrado',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _friends.length,
                        itemBuilder: (context, index) {
                          final friend = _friends[index];
                          final isSelected = _isSelected(friend.id);
                          final role = _getRole(friend.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: isDark
                                ? const Color(0xFF374151)
                                : const Color(0xFFF9FAFB),
                            elevation: isSelected ? 2 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected
                                    ? const Color(0xFF3B82F6)
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundImage: friend.photoUrl != null
                                        ? NetworkImage(friend.photoUrl!)
                                        : null,
                                    backgroundColor: const Color(0xFF3B82F6),
                                    child: friend.photoUrl == null
                                        ? Text(
                                            friend.name[0].toUpperCase(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          friend.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF1F2937),
                                          ),
                                        ),
                                      ),
                                      // Badge para owner
                                      if (widget.ownerId == friend.id)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFBBF24),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                '👑',
                                                style: TextStyle(fontSize: 10),
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Você',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: isSelected && role != null
                                      ? Padding(
                                          padding: const EdgeInsets.only(top: 4),
                                          child: Text(
                                            role.label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: const Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        )
                                      : null,
                                  trailing: AnimatedScale(
                                    scale: isSelected ? 1.0 : 0.9,
                                    duration: const Duration(milliseconds: 200),
                                    curve: Curves.easeOut,
                                    child: Checkbox(
                                      value: isSelected,
                                      onChanged: (value) => _toggleParticipant(friend),
                                      activeColor: const Color(0xFF3B82F6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                  onTap: () => _toggleParticipant(friend),
                                ),
                                
                                // Seletor de papel (apenas se selecionado)
                                if (isSelected && role != null)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(height: 1),
                                        const SizedBox(height: 12),
                                        Text(
                                          'Permissões:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? Colors.grey[400]
                                                : Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _buildRoleChip(
                                              friend.id,
                                              EventRole.admin,
                                              '👑 Admin',
                                              'Pode editar e gerenciar',
                                              role == EventRole.admin,
                                              isDark,
                                            ),
                                            _buildRoleChip(
                                              friend.id,
                                              EventRole.participant,
                                              '👤 Convidado',
                                              'Apenas visualiza',
                                              role == EventRole.participant,
                                              isDark,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Footer com botão de confirmar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1F2937) : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
              ),
            ),
            child: SafeArea(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  widget.selectedParticipants.isEmpty
                      ? 'Continuar sem convidados'
                      : 'Confirmar ${widget.selectedParticipants.length} convidado(s)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(
    String friendId,
    EventRole role,
    String label,
    String description,
    bool isSelected,
    bool isDark,
  ) {
    return InkWell(
      onTap: () => _changeRole(friendId, role),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF3B82F6)
              : isDark
                  ? const Color(0xFF1F2937)
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF3B82F6)
                : isDark
                    ? Colors.grey[700]!
                    : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white
                        : const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: isSelected
                    ? Colors.white.withOpacity(0.9)
                    : isDark
                        ? Colors.grey[400]
                        : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
