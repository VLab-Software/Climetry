import 'package:flutter/material.dart';
import '../../../friends/domain/entities/friend.dart';
import '../../../friends/data/services/friends_service.dart';
import '../../domain/entities/activity.dart';

class InviteParticipantsScreen extends StatefulWidget {
  final Activity activity;

  const InviteParticipantsScreen({super.key, required this.activity});

  @override
  State<InviteParticipantsScreen> createState() =>
      _InviteParticipantsScreenState();
}

class _InviteParticipantsScreenState extends State<InviteParticipantsScreen> {
  final FriendsService _friendsService = FriendsService();
  List<Friend> _friends = [];
  final Map<String, EventRole> _selectedFriends = {};
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    setState(() => _isLoading = true);

    try {
      final friends = await _friendsService.getFriends();

      final existingParticipantIds = widget.activity.participants
          .map((p) => p.userId)
          .toSet();

      setState(() {
        _friends = friends
            .where((f) => !existingParticipantIds.contains(f.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading amigos: $e')));
      }
    }
  }

  List<Friend> get _filteredFriends {
    if (_searchQuery.isEmpty) return _friends;

    final query = _searchQuery.toLowerCase();
    return _friends.where((friend) {
      return friend.name.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleFriend(Friend friend) {
    setState(() {
      if (_selectedFriends.containsKey(friend.id)) {
        _selectedFriends.remove(friend.id);
      } else {
        _selectedFriends[friend.id] = EventRole.participant;
      }
    });
  }

  void _changeRole(String friendId, EventRole role) {
    setState(() {
      _selectedFriends[friendId] = role;
    });
  }

  Future<void> _sendInvites() async {
    if (_selectedFriends.isEmpty) return;

    try {
      Navigator.pop(context, _selectedFriends);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error ao enviar convites: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Convidar Participants'),
        actions: [
          if (_selectedFriends.isNotEmpty)
            TextButton.icon(
              onPressed: _sendInvites,
              icon: const Icon(Icons.send, color: Colors.white),
              label: Text(
                'Enviar (${_selectedFriends.length})',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search amigos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredFriends.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No friends available'
                              : 'No friends found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredFriends.length,
                    itemBuilder: (context, index) {
                      final friend = _filteredFriends[index];
                      final isSelected = _selectedFriends.containsKey(
                        friend.id,
                      );
                      final role = _selectedFriends[friend.id];

                      return _buildFriendCard(friend, isSelected, role);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendCard(Friend friend, bool isSelected, EventRole? role) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: friend.photoUrl != null
              ? NetworkImage(friend.photoUrl!)
              : null,
          child: friend.photoUrl == null
              ? Text(
                  friend.name.isNotEmpty ? friend.name[0].toUpperCase() : '?',
                )
              : null,
        ),
        title: Text(friend.name),
        subtitle: isSelected ? _buildRoleSelector(friend.id, role!) : null,
        trailing: Checkbox(
          value: isSelected,
          onChanged: (value) => _toggleFriend(friend),
        ),
        onTap: () => _toggleFriend(friend),
      ),
    );
  }

  Widget _buildRoleSelector(String friendId, EventRole currentRole) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<EventRole>(
        value: currentRole,
        isExpanded: true,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        style: TextStyle(
          fontSize: 14,
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
        ),
        items: [
          DropdownMenuItem(
            value: EventRole.participant,
            child: Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text('Participante'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: EventRole.moderator,
            child: Row(
              children: [
                Icon(Icons.shield, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                const Text('Moderador'),
              ],
            ),
          ),
          DropdownMenuItem(
            value: EventRole.admin,
            child: Row(
              children: [
                Icon(
                  Icons.admin_panel_settings,
                  size: 16,
                  color: Colors.red[700],
                ),
                const SizedBox(width: 8),
                const Text('Administrador'),
              ],
            ),
          ),
        ],
        onChanged: (EventRole? newRole) {
          if (newRole != null) {
            _changeRole(friendId, newRole);
          }
        },
      ),
    );
  }
}
