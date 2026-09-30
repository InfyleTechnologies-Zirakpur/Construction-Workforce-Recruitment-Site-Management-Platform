import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/skeleton/smart_skeleton.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/worker_repository.dart';

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
        if (conversations.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  Text('No conversations yet', style: textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'When an employer reviews your application and sends a remark, a conversation will appear here.',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }

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
          ).then((_) {
            // Refresh conversations when returning from chat
            if (context.mounted) {
              context.read<MessagesCubit>().load();
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                radius: context.w(24),
                backgroundColor: AppColors.dark,
                child: Text(
                  conversation.company.isNotEmpty ? conversation.company[0].toUpperCase() : 'C',
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
  const ChatScreen({super.key, required this.conversation, this.isCompany = false});
  final Conversation conversation;
  final bool isCompany;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _repo = WorkerRepository();
  List<ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isCandidate = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
    _loadMessages();
    _markRead();
  }

  Future<void> _checkRole() async {
    if (widget.isCompany) {
      if (mounted) setState(() => _isCandidate = false);
      return;
    }
    const storage = FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
    final role = await storage.read(key: 'role');
    if (mounted) {
      setState(() {
        _isCandidate = (role != 'company');
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _repo.fetchMessages(widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // ignore: avoid_print
        print('⚠️ [ChatScreen] Failed to load messages: $e');
      }
    }
  }

  Future<void> _markRead() async {
    try {
      await _repo.markConversationRead(widget.conversation.id);
    } catch (_) {}
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    // First message restriction: candidate cannot initiate first message
    if (_isCandidate && _messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only the company can initiate the conversation after reviewing your application.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(id: 'local_${DateTime.now().millisecondsSinceEpoch}', text: text, isMine: true, time: 'Now'));
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await _repo.sendMessage(widget.conversation.id, text);
      // Reload messages to get the server-assigned ID and timestamp
      await _loadMessages();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh messages',
            onPressed: () {
              setState(() => _isLoading = true);
              _loadMessages();
            },
          ),
        ],
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _isCandidate ? Icons.lock_clock_outlined : Icons.chat_bubble_outline,
                                  size: 48,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _isCandidate
                                      ? 'Waiting for contractor to send the first message'
                                      : 'No messages yet. Send the first message to the candidate!',
                                  style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
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
    // If candidate and conversation has no messages yet -> Candidate cannot send first message!
    if (_isCandidate && _messages.isEmpty) {
      final textTheme = Theme.of(context).textTheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            const Icon(Icons.lock_outline, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Only the company can initiate the conversation after reviewing your application.',
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

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
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.time,
                  style: textTheme.labelSmall?.copyWith(
                    color: message.isMine ? Colors.white70 : Colors.black45,
                  ),
                ),
                if (message.isMine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.white : Colors.white70,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
