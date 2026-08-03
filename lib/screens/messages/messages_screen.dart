import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  void initState() {
    super.initState();
    context.read<MessagesCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<MessagesCubit, LoadState<List<Conversation>>>(
      builder: (context, state) {
        if (state is Idle<List<Conversation>> ||
            state is Loading<List<Conversation>>) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: SmartSkeleton.list(
              itemCount: 4,
              hasLeading: true,
              leadingIsCircle: true,
              hasTags: false,
            ),
          );
        }

        if (state is Failed<List<Conversation>>) {
          return Center(
            child: Text('Unable to load messages', style: textTheme.titleMedium),
          );
        }

        final conversations = (state as Loaded<List<Conversation>>).data;
        return RefreshIndicator(
          onRefresh: () => context.read<MessagesCubit>().load(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  context.w(20),
                  context.h(18),
                  context.w(20),
                  context.h(32),
                ),
                children: [
                  Text(
                    'Messages',
                    style: textTheme.headlineSmall?.copyWith(color: AppColors.dark),
                  ),
                  SizedBox(height: context.h(4)),
                  Text(
                    'Stay in touch with contractors about your applications.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: context.h(18)),
                  ...conversations.map(
                    (conversation) => ConversationTile(conversation: conversation),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class ConversationTile extends StatelessWidget {
  const ConversationTile({super.key, required this.conversation});
  final Conversation conversation;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatScreen(conversation: conversation),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.w(24),
                backgroundColor: AppColors.dark,
                child: Text(
                  conversation.company.substring(0, 1),
                  style: textTheme.titleMedium?.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.company,
                            style: textTheme.titleSmall,
                          ),
                        ),
                        Text(conversation.lastMessageAt, style: textTheme.labelSmall),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      conversation.jobTitle,
                      style: textTheme.bodySmall?.copyWith(color: AppColors.primary),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      conversation.lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              if (conversation.unreadCount > 0)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      '${conversation.unreadCount}',
                      style: textTheme.labelSmall?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.conversation});
  final Conversation conversation;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late List<ChatMessage> _messages;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages = List.of(widget.conversation.messages);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(id: 'local', text: text, isMine: true, time: 'Now'));
      _messageController.clear();
    });

    await context.read<MessagesCubit>().send(widget.conversation.id, text);
    if (mounted) setState(() => _isSending = false);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.conversation.company),
            Text(
              widget.conversation.jobTitle,
              style: textTheme.labelSmall?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Discuss job details only. Never share OTPs or banking PINs.',
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(
                  horizontal: context.w(16),
                  vertical: context.h(10),
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) => MessageBubble(message: _messages[index]),
              ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: EdgeInsets.fromLTRB(context.w(16), 10, context.w(16), 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: const InputDecoration(
                hintText: 'Write a message...',
                border: InputBorder.none,
                filled: false,
              ),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: const Icon(Icons.send, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Align(
      alignment: message.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .76),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: message.isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: message.isMine ? null : Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.text,
              style: textTheme.bodyMedium?.copyWith(
                color: message.isMine ? Colors.white : AppColors.dark,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              message.time,
              style: textTheme.labelSmall?.copyWith(
                color: message.isMine ? Colors.white70 : Colors.black45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
