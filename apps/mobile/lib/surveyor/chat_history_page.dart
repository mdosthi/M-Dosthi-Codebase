//##############################################################################
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../service/language_service.dart';
import '../login_page.dart';
import 'package:intl/intl.dart';
import '../chat/assistant_speech_player.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  final LanguageService languageService = LanguageService();
  List<ChatSession> chatSessions = [];
  bool isLoading = true;
  String? errorMessage;
  late final AssistantSpeechPlayer _speechPlayer;

  @override
  void initState() {
    super.initState();
    _speechPlayer = AssistantSpeechPlayer();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _speechPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-chat-sessions";

      print('Loading chat history for patient: ${LoginPage.patid}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'pat_id': LoginPage.patid,
          'limit': 50,
          'offset': 0,
        }),
      );

      print('Chat history response status: ${response.statusCode}');
      print('Chat history response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            chatSessions = (jsonResponse['sessions'] as List)
                .map((session) => ChatSession.fromJson(session))
                .toList();
          });
        } else {
          setState(() {
            errorMessage =
                jsonResponse['message'] ?? 'Failed to load chat history';
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
      setState(() {
        errorMessage = 'Error loading chat history: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _viewChatSession(ChatSession session) async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-chat-messages";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'session_id': session.sessionId,
          'limit': 100,
          'offset': 0,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final messages = (jsonResponse['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg))
              .toList();

          _showChatSessionDialog(session, messages);
        } else {
          _showErrorMessage('Failed to load messages');
        }
      } else {
        _showErrorMessage('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading messages: $e');
      _showErrorMessage('Error loading messages: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showChatSessionDialog(ChatSession session, List<ChatMessage> messages) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.height * 0.8,
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${languageService.getText('chat_session')} ${session.sessionId.substring(5, 13)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              DateFormat('yyyy-MM-dd HH:mm')
                                  .format(session.startTime),
                              style: const TextStyle(color: Colors.grey),
                            ),
                            if (session.duration != null)
                              Text(
                                '${languageService.getText('duration')}: ${_formatDuration(session.duration!)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                // Messages
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildHistoryMessageBubble(messages[index]);
                    },
                  ),
                ),
                // Footer
                if (session.sessionNotes != null &&
                    session.sessionNotes!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.note, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.sessionNotes!,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() => _speechPlayer.stop());
  }

  Widget _buildHistoryMessageBubble(ChatMessage message) {
    final isUser = message.senderType == 'patient';
    final isSystem = message.senderType == 'system';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: isSystem ? Colors.orange : Colors.green.shade700,
              child: Icon(
                isSystem ? Icons.info : Icons.smart_toy,
                size: 12,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isUser
                    ? Colors.green.shade500
                    : isSystem
                        ? Colors.orange.shade100
                        : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.messageContent,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: TextStyle(
                      color: isUser ? Colors.white70 : Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                  if (!isUser && !isSystem)
                    AssistantSpeechControl(
                      messageId: message.messageId,
                      endpoint:
                          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/speech",
                      token: LoginPage.jwtToken,
                      player: _speechPlayer,
                    ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 6),
            CircleAvatar(
              radius: 12,
              backgroundColor: Colors.green,
              child: const Icon(
                Icons.person,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final secs = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.green.shade700;
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.circle;
      case 'completed':
        return Icons.check_circle;
      case 'canceled':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  Widget _buildSessionCard(ChatSession session) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => _viewChatSession(session),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getStatusIcon(session.sessionStatus),
                    color: _getStatusColor(session.sessionStatus),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${languageService.getText('session')} ${session.sessionId.substring(5, 13)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(session.sessionStatus)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _getStatusColor(session.sessionStatus)
                            .withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      languageService.getText(
                          'session_${session.sessionStatus.toLowerCase()}'),
                      style: TextStyle(
                        color: _getStatusColor(session.sessionStatus),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('yyyy-MM-dd').format(session.sessionDate),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('HH:mm').format(session.startTime),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  if (session.endTime != null) ...[
                    Text(
                      ' - ${DateFormat('HH:mm').format(session.endTime!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ],
              ),
              if (session.duration != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.timer, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${languageService.getText('duration')}: ${_formatDuration(session.duration!)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ],
              if (session.sessionNotes != null &&
                  session.sessionNotes!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.note, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        session.sessionNotes!,
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    languageService.getText('tap_to_view_messages'),
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.green.shade600,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: languageService,
      builder: (context, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(languageService.getText('chat_history')),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _loadChatHistory,
                tooltip: languageService.getText('refresh'),
              ),
            ],
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            languageService.getText('error'),
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(errorMessage!),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadChatHistory,
                            child: Text(languageService.getText('retry')),
                          ),
                        ],
                      ),
                    )
                  : chatSessions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.chat_bubble_outline,
                                size: 80,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                languageService.getText('no_chat_history'),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                languageService.getText('start_first_chat'),
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChatHistory,
                          child: ListView.builder(
                            itemCount: chatSessions.length,
                            itemBuilder: (context, index) {
                              return _buildSessionCard(chatSessions[index]);
                            },
                          ),
                        ),
        );
      },
    );
  }
}

class ChatSession {
  final String sessionId;
  final String patId;
  final DateTime sessionDate;
  final DateTime startTime;
  final DateTime? endTime;
  final int? duration;
  final String? sessionNotes;
  final String sessionStatus;

  ChatSession({
    required this.sessionId,
    required this.patId,
    required this.sessionDate,
    required this.startTime,
    this.endTime,
    this.duration,
    this.sessionNotes,
    required this.sessionStatus,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      sessionId: json['session_id'],
      patId: json['pat_id'],
      sessionDate: DateTime.parse(json['session_date']),
      startTime: DateTime.parse(json['start_time']),
      endTime:
          json['end_time'] != null ? DateTime.parse(json['end_time']) : null,
      duration: json['duration'],
      sessionNotes: json['session_notes'],
      sessionStatus: json['session_status'],
    );
  }
}

class ChatMessage {
  final String messageId;
  final String sessionId;
  final int messageSequence;
  final String senderType;
  final String messageContent;
  final DateTime timestamp;

  ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.messageSequence,
    required this.senderType,
    required this.messageContent,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      sessionId: json['session_id'],
      messageSequence: json['message_sequence'],
      senderType: json['sender_type'],
      messageContent: json['message_content'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
