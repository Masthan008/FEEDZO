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
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const TopBar(title: 'Chat System', subtitle: 'Manage admin communications'),
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

              return Padding(
                padding: const EdgeInsets.all(24),
                child: ListView.builder(
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
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
