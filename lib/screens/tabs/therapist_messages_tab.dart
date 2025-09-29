import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class TherapistMessagesTab extends StatefulWidget {
  const TherapistMessagesTab({super.key});

  @override
  State<TherapistMessagesTab> createState() => _TherapistMessagesTabState();
}

class _TherapistMessagesTabState extends State<TherapistMessagesTab> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filteredConversations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    // Mock data - replace with real API calls
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _conversations = [
        {
          'id': '1',
          'patientName': 'John Doe',
          'patientAvatar': null,
          'lastMessage': 'Thank you for today\'s session. I felt much better.',
          'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
          'unreadCount': 2,
          'isOnline': true,
          'messages': [
            {
              'id': '1',
              'sender': 'patient',
              'message':
                  'Hi Dr. Smith, I wanted to follow up on our session today.',
              'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
              'isRead': true,
            },
            {
              'id': '2',
              'sender': 'therapist',
              'message':
                  'Hello John! I\'m glad you reached out. How are you feeling after our discussion about coping strategies?',
              'timestamp': DateTime.now().subtract(
                const Duration(hours: 1, minutes: 45),
              ),
              'isRead': true,
            },
            {
              'id': '3',
              'sender': 'patient',
              'message': 'Thank you for today\'s session. I felt much better.',
              'timestamp': DateTime.now().subtract(const Duration(minutes: 15)),
              'isRead': false,
            },
          ],
        },
        {
          'id': '2',
          'patientName': 'Sarah Smith',
          'patientAvatar': null,
          'lastMessage': 'I have a question about the homework you gave me.',
          'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
          'unreadCount': 1,
          'isOnline': false,
          'messages': [
            {
              'id': '1',
              'sender': 'patient',
              'message': 'I have a question about the homework you gave me.',
              'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
              'isRead': false,
            },
          ],
        },
        {
          'id': '3',
          'patientName': 'Emily Davis',
          'patientAvatar': null,
          'lastMessage': 'See you next Tuesday!',
          'timestamp': DateTime.now().subtract(const Duration(days: 1)),
          'unreadCount': 0,
          'isOnline': false,
          'messages': [
            {
              'id': '1',
              'sender': 'therapist',
              'message':
                  'Great progress in today\'s session! Keep practicing the breathing exercises.',
              'timestamp': DateTime.now().subtract(
                const Duration(days: 1, hours: 2),
              ),
              'isRead': true,
            },
            {
              'id': '2',
              'sender': 'patient',
              'message': 'Thank you! I will. See you next Tuesday!',
              'timestamp': DateTime.now().subtract(const Duration(days: 1)),
              'isRead': true,
            },
          ],
        },
        {
          'id': '4',
          'patientName': 'Mike Johnson',
          'patientAvatar': null,
          'lastMessage': 'I need to reschedule our appointment.',
          'timestamp': DateTime.now().subtract(const Duration(days: 2)),
          'unreadCount': 0,
          'isOnline': false,
          'messages': [
            {
              'id': '1',
              'sender': 'patient',
              'message': 'I need to reschedule our appointment.',
              'timestamp': DateTime.now().subtract(const Duration(days: 2)),
              'isRead': true,
            },
          ],
        },
      ];
      _filteredConversations = _conversations;
      _isLoading = false;
    });
  }

  void _filterConversations(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredConversations = _conversations;
      } else {
        _filteredConversations = _conversations
            .where(
              (conversation) =>
                  conversation['patientName'].toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  conversation['lastMessage'].toLowerCase().contains(
                    query.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Create new message
            },
            icon: const Icon(Icons.edit, color: Colors.white),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryGreen),
            )
          : Column(
              children: [
                _buildSearchBar(),
                _buildUnreadCount(),
                Expanded(child: _buildConversationsList()),
              ],
            ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: TextField(
        controller: _searchController,
        onChanged: _filterConversations,
        decoration: InputDecoration(
          hintText: 'Search messages...',
          hintStyle: const TextStyle(color: AppTheme.secondaryText),
          prefixIcon: const Icon(Icons.search, color: AppTheme.secondaryText),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _filterConversations('');
                  },
                  icon: const Icon(Icons.clear, color: AppTheme.secondaryText),
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF9FAFB),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
              color: AppTheme.primaryGreen,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnreadCount() {
    final unreadTotal = _conversations
        .map((c) => c['unreadCount'] as int)
        .fold(0, (sum, count) => sum + count);

    if (unreadTotal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mark_chat_unread,
                  size: 16,
                  color: Color(0xFFEF4444),
                ),
                const SizedBox(width: 6),
                Text(
                  '$unreadTotal unread message${unreadTotal > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList() {
    if (_filteredConversations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppTheme.secondaryText,
            ),
            SizedBox(height: 16),
            Text(
              'No conversations found',
              style: TextStyle(fontSize: 18, color: AppTheme.secondaryText),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadConversations,
      child: ListView.builder(
        itemCount: _filteredConversations.length,
        itemBuilder: (context, index) {
          final conversation = _filteredConversations[index];
          return _buildConversationItem(conversation);
        },
      ),
    );
  }

  Widget _buildConversationItem(Map<String, dynamic> conversation) {
    final unreadCount = conversation['unreadCount'] as int;
    final isOnline = conversation['isOnline'] as bool;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[200]!, width: 1)),
      ),
      child: InkWell(
        onTap: () => _openChatScreen(conversation),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppTheme.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    backgroundImage: conversation['patientAvatar'] != null
                        ? NetworkImage(conversation['patientAvatar'])
                        : null,
                    child: conversation['patientAvatar'] == null
                        ? const Icon(
                            Icons.person,
                            color: AppTheme.primaryGreen,
                            size: 26,
                          )
                        : null,
                  ),
                  if (isOnline)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
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
                            conversation['patientName'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: AppTheme.primaryText,
                            ),
                          ),
                        ),
                        Text(
                          _formatMessageTime(conversation['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: unreadCount > 0
                                ? AppTheme.primaryGreen
                                : AppTheme.secondaryText,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation['lastMessage'],
                            style: TextStyle(
                              fontSize: 14,
                              color: unreadCount > 0
                                  ? AppTheme.primaryText
                                  : AppTheme.secondaryText,
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (unreadCount > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGreen,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              unreadCount.toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  void _openChatScreen(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(conversation: conversation),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic> conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late List<Map<String, dynamic>> _messages;

  @override
  void initState() {
    super.initState();
    _messages = List.from(widget.conversation['messages'] ?? []);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final newMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender': 'therapist',
      'message': _messageController.text.trim(),
      'timestamp': DateTime.now(),
      'isRead': true,
    };

    setState(() {
      _messages.add(newMessage);
    });

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation['patientName'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    widget.conversation['isOnline'] ? 'Online' : 'Offline',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Video call
            },
            icon: const Icon(Icons.videocam, color: Colors.white),
          ),
          IconButton(
            onPressed: () {
              // TODO: Voice call
            },
            icon: const Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isFromTherapist = message['sender'] == 'therapist';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isFromTherapist
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isFromTherapist) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: const Icon(
                Icons.person,
                color: AppTheme.primaryGreen,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isFromTherapist
                    ? AppTheme.primaryGreen
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'],
                    style: TextStyle(
                      fontSize: 14,
                      color: isFromTherapist
                          ? Colors.white
                          : AppTheme.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatMessageTime(message['timestamp']),
                    style: TextStyle(
                      fontSize: 10,
                      color: isFromTherapist
                          ? Colors.white.withValues(alpha: 0.7)
                          : AppTheme.secondaryText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isFromTherapist) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 14,
              backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
              child: const Icon(
                Icons.psychology,
                color: AppTheme.primaryGreen,
                size: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: const TextStyle(color: AppTheme.secondaryText),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryGreen,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatMessageTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }
}
