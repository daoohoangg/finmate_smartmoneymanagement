import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../shared/widgets/finmate_bottom_nav.dart';
import 'services/gemini_chat_service.dart';

class AiCoachChatScreen extends StatefulWidget {
  const AiCoachChatScreen({super.key, this.initialMessage});

  static const String routeName = '/ai-coach/chat';

  final String? initialMessage;

  @override
  State<AiCoachChatScreen> createState() => _AiCoachChatScreenState();
}

class _AiCoachChatScreenState extends State<AiCoachChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GeminiChatService _chatService = GeminiChatService();

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        isUser: false,
        text:
            'Hi, I am your AI Financial Coach. Ask me about budgeting, overspending, savings, or debt payoff.',
        sentAt: DateTime.now(),
      ),
    );
    final prefill = widget.initialMessage?.trim();
    if (prefill != null && prefill.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _submitMessage(prefill);
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _send() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;
    _inputController.clear();
    _submitMessage(text);
  }

  Future<void> _submitMessage(String text) async {
    setState(() {
      _messages.add(
        _ChatMessage(isUser: true, text: text, sentAt: DateTime.now()),
      );
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final history = _messages
          .where((message) => message.text.trim().isNotEmpty)
          .map(
            (message) => GeminiTurn(isUser: message.isUser, text: message.text),
          )
          .toList();
      final reply = await _chatService.sendMessage(
        userMessage: text,
        history: history.take(history.length - 1).toList(),
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          _ChatMessage(isUser: false, text: reply, sentAt: DateTime.now()),
        );
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString());
      setState(() {
        _messages.add(
          _ChatMessage(
            isUser: false,
            text:
                'I could not reach Gemini right now. Please check API key/network and try again.',
            sentAt: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _sendQuickAction(String text) {
    if (_isSending) return;
    _submitMessage(text);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.border,
              child: Icon(
                Icons.smart_toy,
                size: 18,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Financial Coach',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  _isSending ? 'Thinking...' : 'Online',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _isSending ? AppColors.textMuted : AppColors.success,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const FinMateBottomNav(
        active: FinMateNavItem.aiChatbot,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.separated(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              separatorBuilder: (_, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Coach is thinking...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                final message = _messages[index];
                final time = _formatTime(message.sentAt);
                if (message.isUser) {
                  return _UserBubble(message: message.text, time: time);
                }
                return _CoachBubble(message: message.text, time: time);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSending
                            ? null
                            : () => _sendQuickAction(
                                'Please help me reassign 25 dollars to cover my overspending.',
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Reassign \$25'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSending
                            ? null
                            : () => _sendQuickAction(
                                'Show me a simple summary of my funds and what I should do next.',
                              ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text('Show my funds'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.message,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: TextField(
                          controller: _inputController,
                          enabled: !_isSending,
                          decoration: const InputDecoration(
                            hintText: 'Ask a follow-up...',
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _send(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 44,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _isSending ? null : _send,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.isUser,
    required this.text,
    required this.sentAt,
  });

  final bool isUser;
  final String text;
  final DateTime sentAt;
}

class _UserBubble extends StatelessWidget {
  const _UserBubble({required this.message, required this.time});

  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(message, style: const TextStyle(color: Colors.white)),
        ),
        const SizedBox(height: 6),
        Text(
          time,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}

class _CoachBubble extends StatelessWidget {
  const _CoachBubble({required this.message, required this.time});

  final String message;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CircleAvatar(
          radius: 16,
          backgroundColor: AppColors.border,
          child: Icon(Icons.smart_toy, size: 18, color: AppColors.textMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                time,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
