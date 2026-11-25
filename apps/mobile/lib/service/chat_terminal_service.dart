// lib/service/chat_terminal_service.dart
import 'dart:convert';
// ignore: unused_import
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/material.dart';

class ChatTerminalService extends ChangeNotifier {
  static final ChatTerminalService _instance = ChatTerminalService._internal();
  factory ChatTerminalService() => _instance;
  ChatTerminalService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;
  final List<String> _terminalOutput = [];
  String _currentDirectory = '';

  bool get isConnected => _isConnected;
  List<String> get terminalOutput => _terminalOutput;
  String get currentDirectory => _currentDirectory;

  // Connect to terminal WebSocket server
  Future<bool> connectToTerminal(
      {String host = '10.5.29.226', int port = 8765}) async {
    try {
      _channel = IOWebSocketChannel.connect('ws://$host:$port');

      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          _handleTerminalMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
          _isConnected = false;
          notifyListeners();
        },
        onDone: () {
          print('WebSocket connection closed');
          _isConnected = false;
          notifyListeners();
        },
      );

      _isConnected = true;
      notifyListeners();

      // Send initial connection message
      await sendCommand('pwd'); // Get current directory
      return true;
    } catch (e) {
      print('Failed to connect to terminal: $e');
      return false;
    }
  }

  // Send command to terminal
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _channel == null) return;

    final message = {
      'type': 'command',
      'data': command,
      'timestamp': DateTime.now().toIso8601String(),
    };

    _channel!.sink.add(jsonEncode(message));
  }

  // Send chat message to terminal (for logging/display)
  Future<void> sendChatMessage(String message, String sender) async {
    if (!_isConnected || _channel == null) return;

    final terminalMessage = {
      'type': 'chat_message',
      'data': {
        'message': message,
        'sender': sender,
        'timestamp': DateTime.now().toIso8601String(),
      }
    };

    _channel!.sink.add(jsonEncode(terminalMessage));
  }

  // Handle messages from terminal
  void _handleTerminalMessage(Map<String, dynamic> message) {
    switch (message['type']) {
      case 'output':
        _terminalOutput.add(message['data']);
        break;
      case 'error':
        _terminalOutput.add('ERROR: ${message['data']}');
        break;
      case 'directory_change':
        _currentDirectory = message['data'];
        break;
      case 'chat_notification':
        _terminalOutput.add('CHAT: ${message['data']}');
        break;
    }
    notifyListeners();
  }

  // Execute chat-related commands
  Future<void> executeChatCommand(String chatMessage) async {
    // Parse chat message for terminal commands
    if (chatMessage.startsWith('/cmd ')) {
      String command = chatMessage.substring(5);
      await sendCommand(command);
    } else if (chatMessage.startsWith('/cd ')) {
      String directory = chatMessage.substring(4);
      await sendCommand('cd $directory');
    } else {
      // Send as regular chat message for terminal display
      await sendChatMessage(chatMessage, 'patient');
    }
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _terminalOutput.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}
