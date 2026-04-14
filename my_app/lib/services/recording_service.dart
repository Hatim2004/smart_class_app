import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../constants.dart';

class RecordingService {
  final FlutterSoundRecorder _recorder = FlutterSoundRecorder();

  bool _isRecording = false;
  bool _isInitialized = false;
  String? _filePath;

  bool get isRecording => _isRecording;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<bool> _ensureInitialized() async {
    if (_isInitialized) return true;
    final status = await Permission.microphone.request();
    if (!status.isGranted) return false;
    await _recorder.openRecorder();
    _isInitialized = true;
    return true;
  }

  // ── Recording ──────────────────────────────────────────────────────────────

  Future<bool> startRecording() async {
    try {
      if (!await _ensureInitialized()) return false;

      // Save to app's documents directory so the file persists permanently
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory('${dir.path}/recordings');
      if (!await folder.exists()) await folder.create(recursive: true);

      _filePath =
          '${folder.path}/class_${DateTime.now().millisecondsSinceEpoch}.mp4';

      await _recorder.startRecorder(
        toFile: _filePath,
        codec: Codec.aacMP4,
        bitRate: 64000,
        sampleRate: 16000,
        numChannels: 1,
      );

      _isRecording = true;
      return true;
    } catch (e) {
      debugPrint('Recording start error: $e');
      return false;
    }
  }

  /// Stops the recorder and returns the saved file path.
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    try {
      final path = await _recorder.stopRecorder();
      _isRecording = false;
      debugPrint('Audio saved to: $path');
      return path;
    } catch (e) {
      debugPrint('Recording stop error: $e');
      _isRecording = false;
      return null;
    }
  }

  // ── Whisper Transcription ──────────────────────────────────────────────────

  Future<String> transcribeFile(
    String filePath, {
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('جاري التحقق من الملف...');

    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('الملف الصوتي غير موجود في: $filePath');
    }

    final sizeMB = await file.length() / (1024 * 1024);
    debugPrint('Audio size: ${sizeMB.toStringAsFixed(2)} MB');

    if (sizeMB > 24) {
      throw Exception(
          'الملف كبير جداً (${sizeMB.toStringAsFixed(1)} MB). '
          'الحد الأقصى 25 MB.');
    }

    onProgress?.call('جاري رفع الملف إلى Whisper...');

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('https://api.openai.com/v1/audio/transcriptions'),
    );

    request.headers['Authorization'] = 'Bearer $kOpenAiApiKey';
    request.fields['model'] = 'whisper-1';
    request.fields['language'] = 'ar';
    request.fields['response_format'] = 'text';
    request.files.add(await http.MultipartFile.fromPath('file', filePath));

    onProgress?.call('جاري التحويل... قد يستغرق دقيقة أو أكثر');

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode == 200) {
      onProgress?.call('تم التحويل بنجاح ✅');
      return response.body.trim();
    } else {
      debugPrint('Whisper error ${response.statusCode}: ${response.body}');
      throw Exception('خطأ Whisper (${response.statusCode}): ${response.body}');
    }
  }

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  Future<void> dispose() async {
    if (_isInitialized) {
      await _recorder.closeRecorder();
      _isInitialized = false;
    }
  }
}
