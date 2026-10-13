import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/models.dart';
import '../../core/utils/responsive.dart';
import '../../features/bloc/worker_blocs.dart';
import '../../features/repositories/worker_repository.dart';

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
    _checkUserRole();
    _loadMessages();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await _repo.markConversationRead(widget.conversation.id);
    } catch (_) {}
    if (mounted) {
      try {
        context.read<MessagesCubit>().markAsRead(widget.conversation.id);
      } catch (_) {}
    }
  }

  Future<void> _checkUserRole() async {
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    final role = await storage.read(key: 'role');
    if (mounted) {
      setState(() {
        _isCandidate = role == 'job_seeker' || role == 'worker';
      });
    }
  }

  Future<void> _loadMessages({bool isPullToRefresh = false}) async {
    try {
      final messages = await _repo.fetchMessages(widget.conversation.id);
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
        if (!isPullToRefresh) {
          _scrollToBottom();
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    if (_isCandidate && _messages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contractors must initiate the conversation first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
      _messages.add(ChatMessage(
        id: 'local_${DateTime.now().millisecondsSinceEpoch}',
        text: text,
        isMine: true,
        time: 'Now',
      ));
      _messageController.clear();
    });
    _scrollToBottom();

    try {
      await _repo.sendMessage(widget.conversation.id, text);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.card,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.dark),
          tooltip: 'Back',
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.company,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.dark,
              ),
            ),
            Text(
              widget.conversation.jobTitle,
              style: textTheme.labelSmall?.copyWith(color: AppColors.textSecondary),
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
                color: AppColors.peachBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.peachBorder, width: 0.8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Discuss job details only. Never share OTPs or banking PINs.',
                      style: textTheme.bodySmall?.copyWith(color: AppColors.dark),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _loadMessages(isPullToRefresh: true),
                      child: _messages.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                                Center(
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
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: AppColors.textSecondary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.symmetric(
                                horizontal: context.w(16),
                                vertical: context.h(10),
                              ),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) => MessageBubble(message: _messages[index]),
                            ),
                    ),
            ),
            _composer(),
          ],
        ),
      ),
    );
  }

  Widget _composer() {
    if (_isCandidate && _messages.isEmpty) {
      final textTheme = Theme.of(context).textTheme;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          color: AppColors.card,
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
        color: AppColors.card,
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
          color: message.isMine ? AppColors.primary : AppColors.card,
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
