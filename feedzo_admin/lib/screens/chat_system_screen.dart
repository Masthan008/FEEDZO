import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/theme.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../widgets/topbar.dart';

class ChatSystemScreen extends StatefulWidget {
  const ChatSystemScreen({super.key});

  @override
  State<ChatSystemScreen> createState() => _ChatSystemScreenState();
}

class _ChatSystemScreenState extends State<ChatSystemScreen> {
  String? _selectedUserId;
  String? _selectedUserName;
  String? _selectedUserType;
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedUserId == null) {
      return _buildUserSelectionScreen();
    }
    return _buildChatScreen();
  }

  Widget _buildUserSelectionScreen() {
    return Column(
      children: [
        const TopBar(title: 'Chat System', subtitle: 'Select a user to chat with'),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Conversations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<ChatMessageModel>>(
                    stream: ChatService.watchAllChats(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      final messages = snapshot.data ?? [];

                      if (messages.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No chat messages yet', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(message.senderName[0]),
                              ),
                              title: Text(message.senderName),
                              subtitle: Text(
                                '${message.senderType.toUpperCase()} → ${message.recipientType.toUpperCase()}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (!message.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.blue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 18),
                                    onPressed: () async {
                                      await ChatService.deleteMessage(message.id);
                                    },
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                              onTap: () {
                                setState(() {
                                  _selectedUserId = message.senderId;
                                  _selectedUserName = message.senderName;
                                  _selectedUserType = message.senderType;
                                });
                              },
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const Divider(height: 32),
                const Text(
                  'Start New Chat',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _buildUserList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserList() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data?.docs ?? [];

          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final name = userData['name'] ?? userData['email'] ?? 'Unknown';
              final role = userData['role'] ?? 'customer';

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(name[0].toUpperCase()),
                  ),
                  title: Text(name),
                  subtitle: Text(role.toUpperCase()),
                  trailing: const Icon(Icons.chat, color: AppColors.primary),
                  onTap: () {
                    setState(() {
                      _selectedUserId = user.id;
                      _selectedUserName = name;
                      _selectedUserType = role;
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildChatScreen() {
    return Column(
      children: [
        TopBar(
          title: 'Chat with $_selectedUserName',
          subtitle: 'Type: ${_selectedUserType?.toUpperCase()}',
          actions: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() {
                  _selectedUserId = null;
                  _selectedUserName = null;
                  _selectedUserType = null;
                });
              },
            ),
          ],
        ),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<ChatMessageModel>>(
                  stream: ChatService.watchChatBetweenUsers(
                    'admin',
                    _selectedUserId!,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final messages = snapshot.data ?? [];

                    if (messages.isEmpty) {
                      return const Center(
                        child: Text('No messages yet. Start the conversation!'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isFromAdmin = message.senderId == 'admin';

                        return Align(
                          alignment: isFromAdmin ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isFromAdmin ? AppColors.primary : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.message,
                                  style: TextStyle(
                                    color: isFromAdmin ? Colors.white : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatTime(message.createdAt),
                                  style: TextStyle(
                                    color: isFromAdmin ? Colors.white70 : Colors.black54,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          filled: true,
                          fillColor: AppColors.surfaceVariant,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.send, color: AppColors.primary),
                      onPressed: _sendMessage,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedUserId == null) return;

    try {
      await ChatService.sendMessage(
        senderId: 'admin',
        senderName: 'Admin',
        senderType: 'admin',
        recipientId: _selectedUserId!,
        recipientName: _selectedUserName ?? 'User',
        recipientType: _selectedUserType ?? 'customer',
        message: message,
      );

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
