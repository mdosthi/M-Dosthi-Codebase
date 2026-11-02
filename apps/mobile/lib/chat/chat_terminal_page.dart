// // lib/chat/chat_terminal_page.dart
// import 'package:flutter/material.dart';
// import 'package:mdosthi_app/service/chat_terminal_service.dart';
// import 'package:mdosthi_app/login_page.dart';

// class ChatTerminalPage extends StatefulWidget {
//   const ChatTerminalPage({Key? key}) : super(key: key);

//   @override
//   _ChatTerminalPageState createState() => _ChatTerminalPageState();
// }

// class _ChatTerminalPageState extends State<ChatTerminalPage> {
//   final ChatTerminalService _terminalService = ChatTerminalService();
//   final TextEditingController _messageController = TextEditingController();
//   final TextEditingController _commandController = TextEditingController();
//   final ScrollController _chatScrollController = ScrollController();
//   final ScrollController _terminalScrollController = ScrollController();

//   List<ChatMessage> _chatMessages = [];
//   bool _isConnecting = false;

//   @override
//   void initState() {
//     super.initState();
//     _terminalService.addListener(_onTerminalUpdate);
//     _connectToTerminal();
//   }

//   @override
//   void dispose() {
//     _terminalService.removeListener(_onTerminalUpdate);
//     _messageController.dispose();
//     _commandController.dispose();
//     _chatScrollController.dispose();
//     _terminalScrollController.dispose();
//     super.dispose();
//   }

//   void _onTerminalUpdate() {
//     setState(() {});
//     // Auto scroll to bottom when new terminal output arrives
//     if (_terminalScrollController.hasClients) {
//       _terminalScrollController.animateTo(
//         _terminalScrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Future<void> _connectToTerminal() async {
//     setState(() => _isConnecting = true);

//     try {
//       bool connected = await _terminalService.connectToTerminal();
//       if (connected) {
//         _showSnackBar('Connected to terminal successfully', Colors.green);
//       } else {
//         _showSnackBar('Failed to connect to terminal', Colors.red);
//       }
//     } catch (e) {
//       _showSnackBar('Error connecting: $e', Colors.red);
//     } finally {
//       setState(() => _isConnecting = false);
//     }
//   }

//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: color,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   void _sendChatMessage() {
//     final message = _messageController.text.trim();
//     if (message.isEmpty) return;

//     setState(() {
//       _chatMessages.add(ChatMessage(
//         content: message,
//         sender: 'You',
//         timestamp: DateTime.now(),
//       ));
//     });

//     // Send to terminal service
//     _terminalService.sendChatMessage(message, LoginPage.username);

//     // Handle special terminal commands
//     if (message.startsWith('/')) {
//       _terminalService.executeChatCommand(message);
//     }

//     _messageController.clear();
//     _scrollChatToBottom();
//   }

//   void _sendTerminalCommand() {
//     final command = _commandController.text.trim();
//     if (command.isEmpty) return;

//     _terminalService.sendCommand(command);
//     _commandController.clear();
//   }

//   void _scrollChatToBottom() {
//     if (_chatScrollController.hasClients) {
//       _chatScrollController.animateTo(
//         _chatScrollController.position.maxScrollExtent,
//         duration: const Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }

//   Widget _buildConnectionStatus() {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       decoration: BoxDecoration(
//         color:
//             _terminalService.isConnected ? Colors.green[100] : Colors.red[100],
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(
//             _terminalService.isConnected ? Icons.link : Icons.link_off,
//             color: _terminalService.isConnected ? Colors.green : Colors.red,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             _terminalService.isConnected ? 'Connected' : 'Disconnected',
//             style: TextStyle(
//               color: _terminalService.isConnected
//                   ? Colors.green[800]
//                   : Colors.red[800],
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           if (_isConnecting) ...[
//             const SizedBox(width: 8),
//             const SizedBox(
//               width: 12,
//               height: 12,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _buildChatSection() {
//     return Expanded(
//       flex: 1,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: Colors.blue[50],
//               border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.chat, color: Colors.blue),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Chat Messages',
//                   style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                 ),
//                 const Spacer(),
//                 _buildConnectionStatus(),
//               ],
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               controller: _chatScrollController,
//               padding: const EdgeInsets.all(8.0),
//               itemCount: _chatMessages.length,
//               itemBuilder: (context, index) {
//                 final message = _chatMessages[index];
//                 return _buildChatBubble(message);
//               },
//             ),
//           ),
//           _buildChatInput(),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatBubble(ChatMessage message) {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           CircleAvatar(
//             radius: 16,
//             backgroundColor: Colors.blue,
//             child: Text(
//               message.sender[0].toUpperCase(),
//               style: const TextStyle(color: Colors.white, fontSize: 12),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Text(
//                       message.sender,
//                       style: const TextStyle(fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       _formatTime(message.timestamp),
//                       style: TextStyle(color: Colors.grey[600], fontSize: 12),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Container(
//                   padding: const EdgeInsets.all(12.0),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[100],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Text(message.content),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildChatInput() {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       decoration: BoxDecoration(
//         border: Border(top: BorderSide(color: Colors.grey[300]!)),
//       ),
//       child: Row(
//         children: [
//           Expanded(
//             child: TextField(
//               controller: _messageController,
//               decoration: const InputDecoration(
//                 hintText: 'Type a message (use /cmd for terminal commands)...',
//                 border: OutlineInputBorder(),
//                 contentPadding:
//                     EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//               ),
//               onSubmitted: (_) => _sendChatMessage(),
//             ),
//           ),
//           const SizedBox(width: 8),
//           ElevatedButton(
//             onPressed: _sendChatMessage,
//             child: const Icon(Icons.send),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildTerminalSection() {
//     return Expanded(
//       flex: 1,
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(8.0),
//             decoration: BoxDecoration(
//               color: Colors.grey[900],
//               border: Border(bottom: BorderSide(color: Colors.grey[700]!)),
//             ),
//             child: Row(
//               children: [
//                 const Icon(Icons.terminal, color: Colors.green),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Terminal Output',
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   _terminalService.currentDirectory,
//                   style: TextStyle(color: Colors.green[300], fontSize: 12),
//                 ),
//               ],
//             ),
//           ),
//           Expanded(
//             child: Container(
//               color: Colors.black,
//               child: ListView.builder(
//                 controller: _terminalScrollController,
//                 padding: const EdgeInsets.all(8.0),
//                 itemCount: _terminalService.terminalOutput.length,
//                 itemBuilder: (context, index) {
//                   final output = _terminalService.terminalOutput[index];
//                   return Text(
//                     output,
//                     style: const TextStyle(
//                       color: Colors.green,
//                       fontFamily: 'monospace',
//                       fontSize: 12,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ),
//           _buildTerminalInput(),
//         ],
//       ),
//     );
//   }

//   Widget _buildTerminalInput() {
//     return Container(
//       padding: const EdgeInsets.all(8.0),
//       decoration: BoxDecoration(
//         color: Colors.grey[900],
//         border: Border(top: BorderSide(color: Colors.grey[700]!)),
//       ),
//       child: Row(
//         children: [
//           Text(
//             '${_terminalService.currentDirectory}\$ ',
//             style:
//                 const TextStyle(color: Colors.green, fontFamily: 'monospace'),
//           ),
//           Expanded(
//             child: TextField(
//               controller: _commandController,
//               style:
//                   const TextStyle(color: Colors.green, fontFamily: 'monospace'),
//               decoration: const InputDecoration(
//                 border: InputBorder.none,
//                 hintText: 'Enter command...',
//                 hintStyle: TextStyle(color: Colors.grey),
//               ),
//               onSubmitted: (_) => _sendTerminalCommand(),
//             ),
//           ),
//           IconButton(
//             onPressed: _sendTerminalCommand,
//             icon: const Icon(Icons.play_arrow, color: Colors.green),
//           ),
//         ],
//       ),
//     );
//   }

//   String _formatTime(DateTime time) {
//     return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Chat Terminal'),
//         actions: [
//           IconButton(
//             onPressed: _connectToTerminal,
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Reconnect',
//           ),
//           IconButton(
//             onPressed: () {
//               _terminalService.disconnect();
//               Navigator.pop(context);
//             },
//             icon: const Icon(Icons.close),
//             tooltip: 'Disconnect and Close',
//           ),
//         ],
//       ),
//       body: Row(
//         children: [
//           _buildChatSection(),
//           const VerticalDivider(width: 1),
//           _buildTerminalSection(),
//         ],
//       ),
//     );
//   }
// }

// class ChatMessage {
//   final String content;
//   final String sender;
//   final DateTime timestamp;

//   ChatMessage({
//     required this.content,
//     required this.sender,
//     required this.timestamp,
//   });
// }
//###############################################################################################################################################
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../service/language_service.dart';
import '../login_page.dart';
import 'package:intl/intl.dart';

class ChatTerminalPage extends StatefulWidget {
  // ignore: use_super_parameters
  const ChatTerminalPage({Key? key}) : super(key: key);

  @override
  State<ChatTerminalPage> createState() => _ChatTerminalPageState();
}

class _ChatTerminalPageState extends State<ChatTerminalPage> {
  final LanguageService languageService = LanguageService();
  final TextEditingController _commandController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<TerminalMessage> messages = [];
  String? currentSessionId;
  bool isLoading = false;
  bool isSessionActive = false;
  bool isExecuting = false;

  @override
  void initState() {
    super.initState();
    _initializeTerminal();
  }

  Future<void> _initializeTerminal() async {
    setState(() => isLoading = true);

    try {
      await _checkActiveSession();
      if (!isSessionActive) {
        await _startChatSession();
      }
      await _loadTerminalHistory();
    } catch (e) {
      _showErrorDialog('Error initializing terminal: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkActiveSession() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-active-session";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['session'] != null) {
          setState(() {
            currentSessionId = jsonResponse['session']['session_id'];
            isSessionActive = true;
          });
        }
      }
    } catch (e) {
      print('Error checking active session: $e');
    }
  }

  Future<void> _startChatSession() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/start-chat-session";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            currentSessionId = jsonResponse['session_id'];
            isSessionActive = true;
          });

          // Add welcome message
          _addWelcomeMessage();
        } else {
          throw Exception(jsonResponse['message'] ?? 'Failed to start session');
        }
      }
    } catch (e) {
      throw Exception('Error starting session: $e');
    }
  }

  void _addWelcomeMessage() {
    setState(() {
      messages.add(TerminalMessage(
        type: TerminalMessageType.system,
        content:
            'Terminal session started. Type commands to execute on the server.',
        timestamp: DateTime.now(),
      ));
      messages.add(TerminalMessage(
        type: TerminalMessageType.system,
        content:
            'Available commands: ls, pwd, date, whoami, uname, df, free, uptime, ps, top, netstat, ifconfig, ping, curl, wget, cat, head, tail, grep, find, which, echo',
        timestamp: DateTime.now(),
      ));
    });
    _scrollToBottom();
  }

  Future<void> _loadTerminalHistory() async {
    if (currentSessionId == null) return;

    // For now, we'll start fresh. You can implement history loading later
    // by adding a get-terminal-history endpoint
  }

  Future<void> _executeCommand() async {
    final command = _commandController.text.trim();
    if (command.isEmpty || currentSessionId == null) return;

    // Add user command to display
    setState(() {
      messages.add(TerminalMessage(
        type: TerminalMessageType.command,
        content: command,
        timestamp: DateTime.now(),
      ));
      isExecuting = true;
    });

    _commandController.clear();
    _scrollToBottom();

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/execute-terminal-command";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'session_id': currentSessionId,
          'command': command,
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);

        if (jsonResponse['status'] == 'success') {
          setState(() {
            messages.add(TerminalMessage(
              type: TerminalMessageType.output,
              content:
                  jsonResponse['output'] ?? 'Command executed successfully',
              timestamp: DateTime.now(),
            ));
          });
        } else {
          setState(() {
            messages.add(TerminalMessage(
              type: TerminalMessageType.error,
              content: 'Error: ${jsonResponse['message'] ?? 'Unknown error'}',
              timestamp: DateTime.now(),
            ));
          });
        }
      } else {
        setState(() {
          messages.add(TerminalMessage(
            type: TerminalMessageType.error,
            content: 'Server error: ${response.statusCode}',
            timestamp: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        messages.add(TerminalMessage(
          type: TerminalMessageType.error,
          content: 'Network error: $e',
          timestamp: DateTime.now(),
        ));
      });
    } finally {
      setState(() => isExecuting = false);
      _scrollToBottom();
    }
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTerminalMessage(TerminalMessage message) {
    Color textColor;
    Color backgroundColor;
    String prefix;

    switch (message.type) {
      case TerminalMessageType.command:
        textColor = Colors.green.shade300;
        backgroundColor = Colors.black;
        prefix = '${LoginPage.userId}@mdosthi:\$ ';
        break;
      case TerminalMessageType.output:
        textColor = Colors.white;
        backgroundColor = Colors.black;
        prefix = '';
        break;
      case TerminalMessageType.error:
        textColor = Colors.red.shade300;
        backgroundColor = Colors.black;
        prefix = 'ERROR: ';
        break;
      case TerminalMessageType.system:
        textColor = Colors.yellow.shade300;
        backgroundColor = Colors.black;
        prefix = '# ';
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: backgroundColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (prefix.isNotEmpty)
            Text(
              prefix,
              style: TextStyle(
                fontFamily: 'Courier',
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          Expanded(
            child: SelectableText(
              message.content,
              style: TextStyle(
                fontFamily: 'Courier',
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm:ss').format(message.timestamp),
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.grey.shade500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromptLine() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Text(
            '${LoginPage.userId}@mdosthi:\$ ',
            style: TextStyle(
              fontFamily: 'Courier',
              color: Colors.green.shade300,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: TextField(
              controller: _commandController,
              enabled: !isExecuting && isSessionActive,
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.white,
                fontSize: 14,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onSubmitted: (_) => _executeCommand(),
              autofocus: true,
            ),
          ),
          if (isExecuting)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Terminal Chat'),
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: () {
              setState(() {
                messages.clear();
              });
              _addWelcomeMessage();
            },
            tooltip: 'Clear Terminal',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.green),
            )
          : Column(
              children: [
                // Terminal header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  color: Colors.grey.shade900,
                  child: Text(
                    'Session: ${currentSessionId?.substring(5, 13) ?? 'None'} | Status: ${isSessionActive ? 'Active' : 'Inactive'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
                // Messages area
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _buildTerminalMessage(messages[index]);
                    },
                  ),
                ),
                // Command prompt
                _buildPromptLine(),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

enum TerminalMessageType {
  command,
  output,
  error,
  system,
}

class TerminalMessage {
  final TerminalMessageType type;
  final String content;
  final DateTime timestamp;

  TerminalMessage({
    required this.type,
    required this.content,
    required this.timestamp,
  });
}
