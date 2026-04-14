import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class ElevenLabsService {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  void onSpeakingChanged(void Function(bool) callback) {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isSpeaking = state == PlayerState.playing;
      callback(_isSpeaking);
    });
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    final cleanText = text.replaceAll(RegExp(r'[*#_~]'), '').trim();

    try {
      final response = await http.post(
        Uri.parse(
            'https://api.elevenlabs.io/v1/text-to-speech/$kElevenLabsVoiceId'),
        headers: {
          'xi-api-key': kElevenLabsApiKey,
          'Content-Type': 'application/json',
          'Accept': 'audio/mpeg',
        },
        body: jsonEncode({
          'text': cleanText,
          'model_id': kElevenLabsModelId,
          'voice_settings': {
            'stability': 0.5,
            'similarity_boost': 0.75,
          },
        }),
      );

      if (response.statusCode == 200) {
        await _audioPlayer.stop();
        await _audioPlayer.play(BytesSource(response.bodyBytes));
      } else {
        debugPrint('ElevenLabs ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('ElevenLabs exception: $e');
    }
  }

  Future<void> stop() async {
    await _audioPlayer.stop();
    _isSpeaking = false;
  }

  void dispose() {
    _audioPlayer.dispose();
  }
}