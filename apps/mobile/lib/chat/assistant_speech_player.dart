import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart' as ap;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class AssistantSpeechPlayer extends ChangeNotifier {
  final ap.AudioPlayer _audioPlayer = ap.AudioPlayer();
  late final StreamSubscription<ap.PlayerState> _stateSubscription;
  String? activeMessageId;
  Uint8List? _audio;
  bool isLoading = false;
  bool isPlaying = false;
  bool isPaused = false;
  bool isCompleted = false;
  String? error;
  double volume = 1;
  int _requestId = 0;
  bool _isDisposed = false;

  AssistantSpeechPlayer() {
    _stateSubscription = _audioPlayer.onPlayerStateChanged.listen((state) {
      if (state == ap.PlayerState.playing) {
        isPlaying = true;
        isPaused = false;
        isCompleted = false;
      } else if (state == ap.PlayerState.paused) {
        isPlaying = false;
        isPaused = true;
      } else if (state == ap.PlayerState.completed) {
        isPlaying = false;
        isPaused = false;
        isCompleted = true;
      }
      _notifyListeners();
    });
  }

  bool get hasAudio => _audio != null;

  Future<void> toggle({
    required String messageId,
    required String endpoint,
    required String token,
  }) async {
    if (activeMessageId == messageId) {
      if (isLoading) return;
      if (isPlaying) {
        await pause();
        return;
      }
      if (isPaused) {
        await resume();
        return;
      }
      if (_audio != null) {
        await replay(messageId);
        return;
      }
    }

    final requestId = ++_requestId;
    _audio = null;
    activeMessageId = messageId;
    isLoading = true;
    isPlaying = false;
    isPaused = false;
    isCompleted = false;
    error = null;
    _notifyListeners();

    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      if (requestId != _requestId) return;

      final response = await http
          .post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message_id': messageId}),
          )
          .timeout(const Duration(seconds: 90));

      if (requestId != _requestId) return;
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw _speechErrorMessage(response);
      }

      _audio = response.bodyBytes;
      await _audioPlayer.setVolume(volume);
      await _audioPlayer.play(ap.BytesSource(_audio!));
      isPlaying = true;
    } catch (exception) {
      if (requestId == _requestId) {
        error = exception is String
            ? exception
            : 'Speech is unavailable right now. Your written response is unchanged.';
      }
    } finally {
      if (requestId == _requestId) {
        isLoading = false;
        _notifyListeners();
      }
    }
  }

  String _speechErrorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic> && body['message'] is String) {
        return body['message'] as String;
      }
    } on FormatException {
      // Use the generic message for non-JSON API responses.
    }
    return 'Speech is unavailable right now. Your written response is unchanged.';
  }

  Future<void> pause() async {
    await _audioPlayer.pause();
    isPlaying = false;
    isPaused = true;
    _notifyListeners();
  }

  Future<void> resume() async {
    await _audioPlayer.resume();
    isPlaying = true;
    isPaused = false;
    _notifyListeners();
  }

  Future<void> replay(String messageId) async {
    if (activeMessageId != messageId || _audio == null) return;
    await _audioPlayer.stop();
    await _audioPlayer.release();
    await _audioPlayer.setVolume(volume);
    await _audioPlayer.play(ap.BytesSource(_audio!));
    isPlaying = true;
    isPaused = false;
    isCompleted = false;
    error = null;
    _notifyListeners();
  }

  Future<void> stop() async {
    if (_isDisposed) return;
    ++_requestId;
    await _audioPlayer.stop();
    await _audioPlayer.release();
    isLoading = false;
    isPlaying = false;
    isPaused = false;
    isCompleted = false;
    error = null;
    _notifyListeners();
  }

  Future<void> setPlaybackVolume(double value) async {
    volume = value.clamp(0.0, 1.0).toDouble();
    await _audioPlayer.setVolume(volume);
    _notifyListeners();
  }

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    ++_requestId;
    unawaited(_stateSubscription.cancel());
    unawaited(_audioPlayer.dispose());
    super.dispose();
  }
}

class AssistantSpeechControl extends StatelessWidget {
  final String messageId;
  final String endpoint;
  final String token;
  final AssistantSpeechPlayer player;

  const AssistantSpeechControl({
    super.key,
    required this.messageId,
    required this.endpoint,
    required this.token,
    required this.player,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: player,
      builder: (context, _) {
        final isCurrent = player.activeMessageId == messageId;
        final isLoading = isCurrent && player.isLoading;
        final hasAudio = isCurrent && player.hasAudio;
        final buttonText = !isCurrent
            ? 'Listen'
            : player.isPlaying
                ? 'Pause'
                : player.isPaused
                    ? 'Resume'
                    : player.isCompleted || hasAudio
                        ? 'Replay'
                        : 'Listen';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 2,
              children: [
                Tooltip(
                  message: 'Listen using a synthetic English voice',
                  child: TextButton.icon(
                    onPressed: player.isLoading
                        ? null
                        : () => player.toggle(
                              messageId: messageId,
                              endpoint: endpoint,
                              token: token,
                            ),
                    icon: isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isCurrent && player.isPlaying
                                ? Icons.pause
                                : Icons.volume_up,
                            size: 18,
                          ),
                    label:
                        Text(isLoading ? 'Generating speech...' : buttonText),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                    ),
                  ),
                ),
                if (isCurrent) ...[
                  if (hasAudio)
                    IconButton(
                      tooltip: 'Replay response',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => player.replay(messageId),
                      icon: const Icon(Icons.replay, size: 19),
                    ),
                  if (hasAudio)
                    SizedBox(
                      width: 108,
                      child: Slider(
                        value: player.volume,
                        min: 0,
                        max: 1,
                        divisions: 10,
                        label: 'Volume ${(player.volume * 100).round()}%',
                        onChanged: player.setPlaybackVolume,
                      ),
                    ),
                ],
              ],
            ),
            if (isCurrent && player.error != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  player.error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ),
          ],
        );
      },
    );
  }
}
