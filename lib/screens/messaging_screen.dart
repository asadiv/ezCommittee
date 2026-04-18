import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/app_controller.dart';
import '../models/group_message.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({
    super.key,
    required this.committeeId,
    required this.committeeName,
  });

  final String committeeId;
  final String committeeName;

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AppController>();
    return Scaffold(
      appBar: AppBar(title: Text('${widget.committeeName} Chat')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<GroupMessage>>(
              stream: controller.messagesStream(widget.committeeId),
              builder: (context, snapshot) {
                final messages = snapshot.data ?? const <GroupMessage>[];
                if (messages.isEmpty) {
                  return const Center(child: Text('No messages yet.'));
                }
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message.senderName),
                      subtitle: Text(message.body),
                      trailing: Text(
                        TimeOfDay.fromDateTime(
                          message.createdAt,
                        ).format(context),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type your message...',
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final text = _messageController.text.trim();
                  if (text.isEmpty) {
                    return;
                  }
                  await controller.sendMessage(
                    committeeId: widget.committeeId,
                    text: text,
                  );
                  _messageController.clear();
                },
                icon: const Icon(Icons.send),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MessagingScreenArgs {
  const MessagingScreenArgs({
    required this.committeeId,
    required this.committeeName,
  });

  final String committeeId;
  final String committeeName;
}
