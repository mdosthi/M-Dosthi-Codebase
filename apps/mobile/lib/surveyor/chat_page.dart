import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../service/language_service.dart';
import '../login_page.dart';
import '../theme/brand_theme.dart';
import 'package:intl/intl.dart';
import 'dart:convert' show utf8, jsonEncode, jsonDecode;
import '../chat/assistant_speech_player.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final LanguageService languageService = LanguageService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  late final AssistantSpeechPlayer _speechPlayer;

  List<ChatMessage> messages = [];
  String? currentSessionId;
  String sessionLanguage = 'en';
  bool isLoading = false;
  bool isSessionActive = false;
  bool canStartChat = false;
  bool isEnrolledInRCT = false;
  Map<String, dynamic>? chatControls;
  String? errorMessage;
  int currentDailyUsage = 0;
  bool isTyping = false;
  bool _speechInitialized = false;
  bool _isListening = false;
  bool _isStartingSpeech = false;
  String _speechDraftPrefix = '';

  // New variable for Bengali translation mode
  bool isBengaliModeEnabled = false;

  // Session duration monitoring variables
  Timer? _durationCheckTimer;
  int? maxSessionDuration;
  int? currentSessionDuration;
  double? durationPercentage;
  // New variables for 30-second warning
  bool hasShown30SecondWarning = false;
  bool isShowingWarningDialog = false;
  String? pendingUserMessage; // Store message if user was typing during timeout

  @override
  void initState() {
    super.initState();
    _speechPlayer = AssistantSpeechPlayer();
    _initializeChat();
  }

  Future<void> _toggleSpeechInput() async {
    if (_isStartingSpeech) return;

    if (_speechToText.isListening || _isListening) {
      await _speechToText.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    setState(() {
      _isStartingSpeech = true;
      _speechDraftPrefix = _messageController.text.trimRight();
    });

    try {
      if (!_speechInitialized) {
        _speechInitialized = await _speechToText.initialize(
          onStatus: _onSpeechStatus,
          onError: _onSpeechError,
        );
      }

      if (!_speechInitialized) {
        if (mounted) {
          setState(() => _isStartingSpeech = false);
          _showSpeechMessage(
            'Speech recognition is unavailable. Try a supported browser or device.',
          );
        }
        return;
      }

      await _speechToText.listen(
        onResult: _onSpeechResult,
        listenOptions: stt.SpeechListenOptions(
          partialResults: true,
          cancelOnError: true,
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(minutes: 1),
          pauseFor: const Duration(seconds: 5),
          localeId: sessionLanguage.toLowerCase().startsWith('bn')
              ? 'bn-BD'
              : 'en-US',
        ),
      );
      if (mounted) setState(() => _isStartingSpeech = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isStartingSpeech = false;
        _isListening = false;
      });
      _showSpeechMessage(
        'Could not start speech recognition. Check microphone permissions and try again.',
      );
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognizedWords = result.recognizedWords.trim();
    if (!mounted || recognizedWords.isEmpty) return;

    final text = _speechDraftPrefix.isEmpty
        ? recognizedWords
        : '$_speechDraftPrefix $recognizedWords';
    _messageController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;
    setState(() {
      _isListening = status == stt.SpeechToText.listeningStatus;
      if (!_isListening) _isStartingSpeech = false;
    });
  }

  void _onSpeechError(SpeechRecognitionError error) {
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _isStartingSpeech = false;
    });

    final message = switch (error.errorMsg) {
      'error_permission' =>
        'Allow microphone and speech-recognition access in your device or browser settings.',
      'error_language_unavailable' ||
      'error_language_not_supported' =>
        'Speech recognition is not available for this language on your device.',
      'error_network' ||
      'error_network_timeout' =>
        'Speech recognition needs a working network connection.',
      'error_no_match' ||
      'error_speech_timeout' =>
        'No speech was recognized. Try speaking again.',
      _ => 'Speech recognition failed. Please try again.',
    };
    _showSpeechMessage(message);
  }

  void _showSpeechMessage(String message) {
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _initializeChat() async {
    setState(() => isLoading = true);

    try {
      // First check RCT enrollment
      await _checkRCTEnrollment();

      if (!isEnrolledInRCT) {
        setState(() {
          errorMessage =
              'You are not enrolled in the RCT study. Chat feature is not available.';
          isLoading = false;
        });
        return;
      }

      await _loadChatControls();
      await _loadCurrentUsage();
      await _checkActiveSession();
      setState(() => canStartChat = true);
    } catch (e) {
      setState(() => errorMessage = e.toString());
      print('Error initializing chat: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _checkRCTEnrollment() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/check-rct-enrollment";

      print('Checking RCT enrollment for patient: ${LoginPage.patid}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      print('RCT enrollment response status: ${response.statusCode}');
      print('RCT enrollment response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            isEnrolledInRCT = jsonResponse['is_enrolled'] ?? false;
          });
          print('RCT enrollment status: $isEnrolledInRCT');
        } else {
          print('RCT enrollment API error: ${jsonResponse['message']}');
          setState(() => isEnrolledInRCT = false);
        }
      } else {
        print('RCT enrollment HTTP error: ${response.statusCode}');
        setState(() => isEnrolledInRCT = false);
      }
    } catch (e) {
      print('Error checking RCT enrollment: $e');
      setState(() => isEnrolledInRCT = false);
    }
  }

  Future<void> _loadChatControls() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-chat-controls";

      print('Loading chat controls for patient: ${LoginPage.patid}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({'pat_id': LoginPage.patid}),
      );

      print('Chat controls response status: ${response.statusCode}');
      print('Chat controls response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            chatControls = jsonResponse['controls'];
          });
          print('Chat controls loaded successfully: $chatControls');
        } else {
          print('Chat controls API error: ${jsonResponse['message']}');
        }
      } else {
        print('Chat controls HTTP error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading chat controls: $e');
      setState(() {
        chatControls = {
          'daily_chat_limit': 3,
          'max_session_duration': 1800,
          'min_session_interval': 3600,
        };
      });
    }
  }

  Future<void> _loadCurrentUsage() async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-chat-sessions";

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

      print('Current usage response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          final sessions = jsonResponse['sessions'] as List;
          final today = DateTime.now();
          final todayString = DateFormat('yyyy-MM-dd').format(today);

          final todaysSessions = sessions.where((session) {
            final sessionDate = session['session_date'] as String;
            return sessionDate == todayString;
          }).length;

          setState(() {
            currentDailyUsage = todaysSessions;
          });
          print('Current daily usage: $currentDailyUsage');
        }
      }
    } catch (e) {
      print('Error loading current usage: $e');
      setState(() {
        currentDailyUsage = 0;
      });
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

      print('Active session response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success' &&
            jsonResponse['session'] != null) {
          final nextSessionId = jsonResponse['session']['session_id'];
          if (currentSessionId != null && currentSessionId != nextSessionId) {
            await _speechPlayer.stop();
          }
          setState(() {
            currentSessionId = nextSessionId;
            sessionLanguage =
                jsonResponse['session']['language_preference'] ?? 'en';
            isSessionActive = true;
          });
          print('Active session found: $currentSessionId');

          // Start duration monitoring for existing session
          _startDurationMonitoring();

          await _loadMessages();
        } else {
          print('No active session found');
        }
      }
    } catch (e) {
      print('Error checking active session: $e');
    }
  }

  Future<void> _startChatSession() async {
    if (!isEnrolledInRCT) {
      _showErrorDialog(
          'You are not enrolled in the RCT study. Chat feature is not available.');
      return;
    }

    final dailyLimit = chatControls?['daily_chat_limit'] ?? 3;

    if (currentDailyUsage >= dailyLimit) {
      _showErrorDialog(
          'You have reached your daily chat limit. Please try again tomorrow.');
      return;
    }

    await _speechPlayer.stop();
    setState(() => isLoading = true);

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/start-chat-session";

      print('Starting chat session for patient: ${LoginPage.patid}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'pat_id': LoginPage.patid,
          'language_preference': languageService.isBengali ? 'bn' : 'en',
        }),
      );

      print('Start session response status: ${response.statusCode}');
      print('Start session response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            currentSessionId = jsonResponse['session_id'];
            sessionLanguage = languageService.isBengali ? 'bn' : 'en';
            isSessionActive = true;
            messages = [];
            currentDailyUsage += 1;
            hasShown30SecondWarning =
                false; // Reset warning flag for new session
            pendingUserMessage = null; // Clear any pending message
          });

          print('Chat session started successfully: $currentSessionId');

          // Start duration monitoring timer
          _startDurationMonitoring();

          await _sendWelcomeMessage();
        } else {
          // Handle specific RCT enrollment error
          if (jsonResponse['error_code'] == 'NOT_ENROLLED_IN_RCT') {
            _showErrorDialog(
                'You are not enrolled in the RCT study. Chat feature is not available.');
          } else {
            _showErrorDialog(
                jsonResponse['message'] ?? 'Failed to start chat session');
          }
        }
      } else {
        _showErrorDialog('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error starting chat session: $e');
      _showErrorDialog('Error starting chat: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _startDurationMonitoring() {
    // Cancel existing timer if any
    _durationCheckTimer?.cancel();

    // Reset warning flag for new session
    hasShown30SecondWarning = false;

    // Start new timer to check duration every 30 seconds
    _durationCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkSessionDurationWithWarning(); // Use the enhanced method
    });

    // Also check immediately
    _checkSessionDurationWithWarning(); // Use the enhanced method
  }

  Future<void> _checkSessionDurationWithWarning() async {
    if (!isSessionActive) return;

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/check-session-duration";

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
          if (jsonResponse['session_active'] == false) {
            // Session has been ended due to duration limit
            await _speechPlayer.stop();
            setState(() {
              isSessionActive = false;
              currentSessionId = null;
              messages = [];
              maxSessionDuration = null;
              currentSessionDuration = null;
              durationPercentage = null;
              hasShown30SecondWarning = false; // Reset warning flag
            });

            _durationCheckTimer?.cancel();

            if (jsonResponse['session_expired'] == true) {
              _showSessionExpiredDialog();
            }
          } else {
            // Update duration information
            setState(() {
              maxSessionDuration = jsonResponse['max_duration_seconds'];
              currentSessionDuration = jsonResponse['duration_seconds'];
              durationPercentage =
                  jsonResponse['duration_percentage']?.toDouble();
            });

            // Check for 30-second warning
            final remainingSeconds = jsonResponse['remaining_seconds'] as int?;
            if (remainingSeconds != null &&
                remainingSeconds <= 30 &&
                remainingSeconds > 0 &&
                !hasShown30SecondWarning &&
                !isShowingWarningDialog) {
              _show30SecondWarning();
            }
          }
        }
      }
    } catch (e) {
      print('Error checking session duration: $e');
    }
  }

  void _show30SecondWarning() {
    setState(() {
      hasShown30SecondWarning = true;
      isShowingWarningDialog = true;
      // Save any message the user might be typing
      if (_messageController.text.trim().isNotEmpty) {
        pendingUserMessage = _messageController.text.trim();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.orange, size: 24),
              const SizedBox(width: 8),
              const Text('Session Ending Soon'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your chat session will end in less than 30 seconds.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              const Text(
                'Do you want to continue the conversation in a new session?',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              if (pendingUserMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your message will be saved:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '"$pendingUserMessage"',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  isShowingWarningDialog = false;
                  pendingUserMessage = null;
                });
                Navigator.of(context).pop();
              },
              child: const Text('No, End Session'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  isShowingWarningDialog = false;
                });
                Navigator.of(context).pop();
                _continueInNewSession();
              },
              child: const Text('Yes, Continue'),
            ),
          ],
        );
      },
    ).then((_) {
      // Ensure flag is reset if dialog is dismissed in any other way
      setState(() {
        isShowingWarningDialog = false;
      });
    });
  }

  void _showSessionExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.red, size: 24),
              const SizedBox(width: 8),
              const Text('Session Expired'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your chat session has ended because it exceeded the maximum duration limit.',
              ),
              if (pendingUserMessage != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Would you like to start a new session with your previous message?',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ],
          ),
          actions: [
            if (pendingUserMessage != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    pendingUserMessage = null;
                  });
                  Navigator.of(context).pop();
                },
                child: const Text('No'),
              ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (pendingUserMessage != null) {
                  _continueInNewSession();
                }
              },
              child:
                  Text(pendingUserMessage != null ? 'Start New Session' : 'OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _continueInNewSession() async {
    try {
      // Store the pending message
      final messageToSend = pendingUserMessage;

      // Reset states
      setState(() {
        hasShown30SecondWarning = false;
        isShowingWarningDialog = false;
      });

      // Wait a moment for the old session to properly end
      await Future.delayed(const Duration(milliseconds: 500));

      // Start a new session
      await _startChatSession();

      // If there was a pending message, restore it to the input field
      if (messageToSend != null) {
        setState(() {
          _messageController.text = messageToSend;
          pendingUserMessage = null;
        });

        // Show a helpful message to the user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'New session started. Your message has been restored.'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Send',
              textColor: Colors.white,
              onPressed: _sendMessage,
            ),
          ),
        );
      }
    } catch (e) {
      print('Error continuing in new session: $e');
      _showErrorDialog('Failed to start new session. Please try again.');
    }
  }

  Future<void> _sendWelcomeMessage() async {
    final welcomeText = '''Welcome to mDosthi!
    ''';

    await _sendSystemMessage(welcomeText);
  }

  Future<void> _sendSystemMessage(String message) async {
    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/send-chat-message";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'session_id': currentSessionId,
          'sender_type': 'system',
          'message_content': message,
        }),
      );

      if (response.statusCode == 200) {
        await _loadMessages();
      }
    } catch (e) {
      print('Error sending system message: $e');
    }
  }

  Future<void> _loadMessages() async {
    if (currentSessionId == null) return;

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/get-chat-messages";

      final requestBody = {
        'session_id': currentSessionId,
        'limit': 100,
        'offset': 0,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: utf8.encode(jsonEncode(requestBody)),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            messages = (jsonResponse['messages'] as List)
                .map((msg) => ChatMessage.fromJson(msg))
                .toList();
          });
          _scrollToBottom();
        }
      }
    } catch (e) {
      print('Error loading messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
    }
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || currentSessionId == null) return;

    _messageController.clear();
    setState(() => isTyping = true);

    try {
      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/send-chat-message";

      final requestBody = {
        'session_id': currentSessionId,
        'sender_type': 'patient',
        'message_content': messageText,
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
          'Accept': 'application/json; charset=UTF-8',
        },
        body: utf8.encode(jsonEncode(requestBody)),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          await _loadMessages();
          _pollForAIResponse();
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() => isTyping = false);
    }
  }

  Future<void> _pollForAIResponse() async {
    int pollCount = 0;
    const maxPolls = 30;

    while (pollCount < maxPolls && isTyping) {
      await Future.delayed(const Duration(seconds: 1));

      final previousMessageCount = messages.length;
      await _loadMessages();

      if (messages.length > previousMessageCount) {
        final lastMessage = messages.last;
        if (lastMessage.senderType == 'bot') {
          setState(() => isTyping = false);
          return;
        }
      }

      pollCount++;
    }

    setState(() => isTyping = false);
  }

  Future<void> _endChatSession() async {
    if (currentSessionId == null) return;

    setState(() => isLoading = true);

    try {
      await _speechPlayer.stop();
      _durationCheckTimer?.cancel(); // Cancel the timer

      final url =
          "${LoginPage.protocol}://${LoginPage.domainName}/api/user/end-chat-session";

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${LoginPage.jwtToken}',
        },
        body: jsonEncode({
          'session_id': currentSessionId,
          'session_notes': 'Session ended by user',
        }),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['status'] == 'success') {
          setState(() {
            currentSessionId = null;
            isSessionActive = false;
            messages = [];
            maxSessionDuration = null;
            currentSessionDuration = null;
            durationPercentage = null;
          });
        }
      }
    } catch (e) {
      print('Error ending session: $e');
    } finally {
      setState(() => isLoading = false);
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
          title: const Text('Notice'),
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

  // New method to toggle Bengali mode
  // void _toggleBengaliMode() {
  //   setState(() {
  //     isBengaliModeEnabled = !isBengaliModeEnabled;
  //   });

  //   // Show a snackbar to indicate the mode change
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text(isBengaliModeEnabled
  //           ? 'Bengali translation mode enabled'
  //           : 'Bengali translation mode disabled'),
  //       duration: const Duration(seconds: 2),
  //       backgroundColor: isBengaliModeEnabled ? Colors.green : Colors.grey,
  //     ),
  //   );
  // }

  Widget _buildLimitRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: BrandColors.navy.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatControls() {
    if (chatControls == null) return Container();

    final dailyLimit = chatControls!['daily_chat_limit'] ?? 3;
    final maxDurationSeconds = chatControls!['max_session_duration'] ?? 1800;
    final minIntervalSeconds = chatControls!['min_session_interval'] ?? 3600;
    final blackoutStart = chatControls!['blackout_start_time'];
    final blackoutEnd = chatControls!['blackout_end_time'];
    final blackoutDays = chatControls!['blackout_days'];

    final maxDurationMinutes = (maxDurationSeconds / 60).round();
    final minIntervalMinutes = (minIntervalSeconds / 60).round();

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: BrandColors.ice,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: BrandColors.navy, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  languageService.isBengali
                      ? 'চ্যাট সেশনের নিয়মাবলী'
                      : 'Your Chat Limits',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: BrandColors.navy,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: currentDailyUsage >= dailyLimit
                      ? Colors.red.shade100
                      : BrandColors.teal.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: currentDailyUsage >= dailyLimit
                        ? Colors.red.shade300
                        : BrandColors.green,
                  ),
                ),
                child: Text(
                  '$currentDailyUsage/$dailyLimit ${languageService.isBengali ? "আজ" : "Today"}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: currentDailyUsage >= dailyLimit
                        ? Colors.red.shade700
                        : BrandColors.navy,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (dailyLimit > 0) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: currentDailyUsage / dailyLimit,
                backgroundColor: BrandColors.borderSubtle.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  currentDailyUsage >= dailyLimit
                      ? Colors.red
                      : BrandColors.tealDark,
                ),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 12),
          ],
          _buildLimitRow(
            icon: Icons.today_rounded,
            label: languageService.isBengali
                ? 'দৈনিক চ্যাট সেশন সীমা'
                : 'Daily Chat Sessions',
            value: dailyLimit.toString(),
          ),
          _buildLimitRow(
            icon: Icons.timer_rounded,
            label: languageService.isBengali
                ? 'সর্বোচ্চ সেশন সময়সীমা'
                : 'Max Session Duration',
            value: languageService.isBengali
                ? '$maxDurationMinutes মিনিট'
                : '$maxDurationMinutes minutes',
          ),
          if (minIntervalSeconds > 0)
            _buildLimitRow(
              icon: Icons.schedule_rounded,
              label: languageService.isBengali
                  ? 'পরবর্তী সেশনের ব্যবধান'
                  : 'Min Wait Between Sessions',
              value: minIntervalMinutes > 60
                  ? (languageService.isBengali
                      ? '${(minIntervalMinutes / 60).round()} ঘণ্টা'
                      : '${(minIntervalMinutes / 60).round()} hours')
                  : (languageService.isBengali
                      ? '$minIntervalMinutes মিনিট'
                      : '$minIntervalMinutes minutes'),
            ),
          if (blackoutStart != null && blackoutEnd != null)
            _buildLimitRow(
              icon: Icons.block_rounded,
              label: languageService.isBengali
                  ? 'বন্ধ থাকার সময়'
                  : 'Restricted Hours',
              value: '$blackoutStart - $blackoutEnd',
            ),
          if (blackoutDays != null && blackoutDays.isNotEmpty)
            _buildLimitRow(
              icon: Icons.calendar_month,
              label: 'Restricted Days',
              value: blackoutDays,
            ),
        ],
      ),
    );
  }

  Widget _buildSessionDurationIndicator() {
    if (!isSessionActive ||
        maxSessionDuration == null ||
        currentSessionDuration == null) {
      return Container();
    }

    final remainingMinutes =
        ((maxSessionDuration! - currentSessionDuration!) / 60).ceil();
    final totalMinutes = (maxSessionDuration! / 60).ceil();
    final progress = currentSessionDuration! / maxSessionDuration!;

    Color progressColor;
    if (progress < 0.7) {
      progressColor = BrandColors.tealDark;
    } else if (progress < 0.9) {
      progressColor = Colors.orange;
    } else {
      progressColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: BrandColors.pageBg,
      child: Row(
        children: [
          Icon(Icons.timer_rounded, size: 16, color: progressColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  languageService.isBengali
                      ? 'সেশন সময়সীমা: আর $remainingMinutes মিনিট বাকি আছে'
                      : 'Session Time: ${remainingMinutes}min remaining',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // New widget to build Bengali translation button
  // Widget _buildBengaliButton() {
  //   if (!isSessionActive) return Container();

  //   return Container(
  //     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //     color: Colors.amber.shade50,
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.center,
  //       children: [
  //         Icon(Icons.translate,
  //             size: 16,
  //             color: isBengaliModeEnabled
  //                 ? Colors.green.shade700
  //                 : Colors.grey.shade600),
  //         const SizedBox(width: 8),
  //         GestureDetector(
  //           onTap: _toggleBengaliMode,
  //           child: Container(
  //             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  //             decoration: BoxDecoration(
  //               color: isBengaliModeEnabled
  //                   ? Colors.green.shade100
  //                   : Colors.grey.shade200,
  //               borderRadius: BorderRadius.circular(16),
  //               border: Border.all(
  //                 color: isBengaliModeEnabled
  //                     ? Colors.green.shade400
  //                     : Colors.grey.shade400,
  //                 width: 1,
  //               ),
  //             ),
  //             child: Row(
  //               mainAxisSize: MainAxisSize.min,
  //               children: [
  //                 Text(
  //                   'বাংলা',
  //                   style: TextStyle(
  //                     fontSize: 14,
  //                     fontWeight: FontWeight.w600,
  //                     color: isBengaliModeEnabled
  //                         ? Colors.green.shade700
  //                         : Colors.grey.shade700,
  //                   ),
  //                 ),
  //                 const SizedBox(width: 6),
  //                 Icon(
  //                   isBengaliModeEnabled ? Icons.toggle_on : Icons.toggle_off,
  //                   size: 20,
  //                   color: isBengaliModeEnabled
  //                       ? Colors.green.shade700
  //                       : Colors.grey.shade500,
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //         const SizedBox(width: 8),
  //         Text(
  //           isBengaliModeEnabled ? 'Translation ON' : 'Translation OFF',
  //           style: TextStyle(
  //             fontSize: 12,
  //             color: isBengaliModeEnabled
  //                 ? Colors.green.shade700
  //                 : Colors.grey.shade600,
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.senderType == 'patient';
    final isSystem = message.senderType == 'system';
    final isBot = message.senderType == 'bot';

    bool hasCodeBlock = message.messageContent.contains('```');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: isSystem
                  ? Colors.amber
                  : isBot
                      ? BrandColors.teal
                      : Colors.grey,
              child: Icon(
                isSystem
                    ? Icons.info_outline_rounded
                    : isBot
                        ? (hasCodeBlock
                            ? Icons.terminal_rounded
                            : Icons.smart_toy_rounded)
                        : Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser
                    ? BrandColors.navy
                    : isSystem
                        ? Colors.amber.shade50
                        : hasCodeBlock
                            ? Colors.grey.shade900
                            : BrandColors.pageBg,
                borderRadius: isUser
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(4),
                      )
                    : const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(16),
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMessageContent(
                      message.messageContent, isUser, hasCodeBlock),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('HH:mm').format(message.timestamp),
                    style: GoogleFonts.poppins(
                      color: isUser
                          ? Colors.white70
                          : hasCodeBlock
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
                  if (isBot)
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
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 18,
              backgroundColor: BrandColors.navy,
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(String content, bool isUser, bool hasCodeBlock) {
    if (!hasCodeBlock) {
      return Text(
        content,
        style: GoogleFonts.poppins(
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 15,
        ),
      );
    }

    List<Widget> widgets = [];
    List<String> parts = content.split('```');

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        if (parts[i].trim().isNotEmpty) {
          widgets.add(
            Text(
              parts[i].trim(),
              style: TextStyle(
                color: isUser ? Colors.white : Colors.white,
                fontSize: 16,
              ),
            ),
          );
          if (i < parts.length - 1) {
            widgets.add(const SizedBox(height: 8));
          }
        }
      } else {
        widgets.add(
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade600),
            ),
            child: SelectableText(
              parts[i],
              style: const TextStyle(
                fontFamily: 'Courier',
                color: Colors.green,
                fontSize: 14,
              ),
            ),
          ),
        );
        if (i < parts.length - 1) {
          widgets.add(const SizedBox(height: 8));
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue,
            child: const Icon(
              Icons.smart_toy,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'mDosthi is thinking...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEnrolledView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.block,
              size: 80,
              color: Colors.orange.shade400,
            ),
            const SizedBox(height: 20),
            Text(
              'Chat Feature Not Available',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'The mDosthi chat feature is currently available only to participants enrolled in our research study.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'If you believe you should have access, please contact your healthcare provider.',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
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
            backgroundColor: BrandColors.navy,
            foregroundColor: Colors.white,
            elevation: 1,
            title: Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage('assets/icons/mdosthi-favicon.png'),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    languageService.isBengali
                        ? 'এম-দোস্তির সাথে চ্যাট'
                        : 'Chat with mDosthi',
                    overflow: TextOverflow.ellipsis,
                    style: BrandTypography.heading(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 19,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (isSessionActive && isEnrolledInRCT)
                TextButton.icon(
                  onPressed: _endChatSession,
                  icon: const Icon(Icons.stop_circle_rounded,
                      color: Colors.white),
                  label: Text(
                    languageService.isBengali ? 'সেশন শেষ' : 'End Chat',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          body: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: BrandColors.navy))
              : !isEnrolledInRCT
                  ? _buildNotEnrolledView()
                  : errorMessage != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.error_outline_rounded,
                                    size: 64, color: Colors.red),
                                const SizedBox(height: 16),
                                Text(
                                  languageService.isBengali
                                      ? 'ত্রুটি ঘটেছে'
                                      : 'Chat Error',
                                  style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 8),
                                Text(errorMessage!,
                                    textAlign: TextAlign.center),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _initializeChat,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: BrandColors.navy,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(languageService.isBengali
                                      ? 'পুনরায় চেষ্টা করুন'
                                      : 'Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : !isSessionActive
                          ? Column(
                              children: [
                                _buildChatControls(),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(
                                              color: BrandColors.navy
                                                  .withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.smart_toy_rounded,
                                              size: 80,
                                              color: BrandColors.navy,
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Text(
                                            languageService.isBengali
                                                ? 'mDosthi এর সাথে বার্তালাপ শুরু করুন'
                                                : 'Start a conversation with mDosthi',
                                            style: GoogleFonts.poppins(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey.shade800,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            languageService.isBengali
                                                ? 'আপনার যেকোনো স্বাস্থ্য জিজ্ঞাসার জন্য সাহায্য ও উত্তর পান'
                                                : 'Get support and answers to your health questions',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 32),
                                          ElevatedButton.icon(
                                            onPressed: canStartChat
                                                ? _startChatSession
                                                : null,
                                            icon:
                                                const Icon(Icons.bolt_rounded),
                                            label: Text(
                                              languageService.isBengali
                                                  ? 'আলাপ শুরু করুন'
                                                  : 'Start Chat',
                                              style: GoogleFonts.poppins(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  BrandColors.navy,
                                              foregroundColor: Colors.white,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 32,
                                                vertical: 16,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              elevation: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                // Chat header with session info
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 10),
                                  color: BrandColors.ice,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.circle,
                                          color: BrandColors.tealDark, size: 10),
                                      const SizedBox(width: 8),
                                      Text(
                                        languageService.isBengali
                                            ? 'চ্যাট সক্রিয় রয়েছে'
                                            : 'Chat Active',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                          color: BrandColors.navy,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        'ID: ${currentSessionId?.substring(0, 8) ?? ''}',
                                        style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ),
                                // Session duration indicator
                                _buildSessionDurationIndicator(),
                                // Bengali translation button (NEW)
                                //_buildBengaliButton(),
                                // Messages list
                                Expanded(
                                  child: ListView.builder(
                                    controller: _scrollController,
                                    itemCount:
                                        messages.length + (isTyping ? 1 : 0),
                                    itemBuilder: (context, index) {
                                      if (index == messages.length &&
                                          isTyping) {
                                        return _buildTypingIndicator();
                                      }
                                      return _buildMessageBubble(
                                          messages[index]);
                                    },
                                  ),
                                ),
                                // Message input
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.shade300,
                                        blurRadius: 4,
                                        offset: const Offset(0, -2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _messageController,
                                          decoration: InputDecoration(
                                            hintText: 'Type a message...',
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(24),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 8,
                                            ),
                                          ),
                                          maxLines: null,
                                          textInputAction: TextInputAction.send,
                                          onSubmitted: (_) => _sendMessage(),
                                          enabled: !isTyping,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        tooltip: _isListening
                                            ? 'Stop voice input'
                                            : 'Dictate a message (speech may use an online recognition service)',
                                        onPressed: isTyping || _isStartingSpeech
                                            ? null
                                            : _toggleSpeechInput,
                                        color: _isListening
                                            ? Colors.red
                                            : Colors.green.shade800,
                                        icon: _isStartingSpeech
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : Icon(
                                                _isListening
                                                    ? Icons.stop_circle
                                                    : Icons.mic,
                                              ),
                                      ),
                                      FloatingActionButton(
                                        onPressed:
                                            isTyping ? null : _sendMessage,
                                        mini: true,
                                        child: const Icon(Icons.send),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
        );
      },
    );
  }

  @override
  void dispose() {
    if (_speechToText.isListening) {
      unawaited(_speechToText.stop());
    }
    _speechPlayer.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _durationCheckTimer?.cancel(); // Cancel the timer

    // Clean up new state variables
    hasShown30SecondWarning = false;
    isShowingWarningDialog = false;
    pendingUserMessage = null;
    super.dispose();
  }
}

class ChatMessage {
  final String messageId;
  final String sessionId;
  final int messageSequence;
  final String senderType;
  final String messageContent;
  final DateTime timestamp;
  final bool isRead;

  ChatMessage({
    required this.messageId,
    required this.sessionId,
    required this.messageSequence,
    required this.senderType,
    required this.messageContent,
    required this.timestamp,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      messageId: json['message_id'],
      sessionId: json['session_id'],
      messageSequence: json['message_sequence'],
      senderType: json['sender_type'],
      messageContent: json['message_content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'] ?? false,
    );
  }
}
