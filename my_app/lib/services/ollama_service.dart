import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants.dart';

class OllamaService {
  static const String _baseUrl = 'http://$kOllamaHost:11434/api/chat';

  Future<String> chat(String userMessage, {String? pdfContext}) async {
    final List<Map<String, String>> messages = [];

    if (pdfContext != null) {
      // For small models: put PDF content in a USER message (not system prompt)
      // because many small models ignore or poorly follow long system prompts.
      // The pattern: user sends the PDF → assistant acknowledges → user asks question.
      messages.add({
        'role': 'system',
        'content':
            'أنت مساعد تعليمي ذكي. أجب دائماً بالعربية. كن مختصراً وواضحاً. '
            'لا تستخدم رموز التنسيق.',
      });
      messages.add({
        'role': 'user',
        'content': 'هذا محتوى الدرس الذي سأسألك عنه:\n\n$pdfContext',
      });
      messages.add({
        'role': 'assistant',
        'content':
            'حسناً، قرأت محتوى الدرس. يمكنك الآن سؤالي عن أي جزء منه وسأشرحه.',
      });
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
    } else {
      messages.add({
        'role': 'system',
        'content':
            'أنت مساعد صوتي للمعلم. أجب بالعربية بشكل مختصر ومباشر. '
            'لا تستخدم رموز التنسيق.',
      });
      messages.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    final body = {
      'model': kOllamaModel,
      'messages': messages,
      'stream': false,
      'options': {
        // Force Ollama to use a larger context window so PDF text is not cut off
        'num_ctx': 4096,
        // Lower temperature for more factual/educational responses
        'temperature': 0.3,
      },
    };

    debugPrint('--- Ollama request ---');
    debugPrint('PDF context length: ${pdfContext?.length ?? 0} chars');
    debugPrint('User message: $userMessage');

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final reply = data['message']['content']?.toString().trim() ?? '';
      debugPrint('Ollama reply: $reply');
      return reply.isEmpty ? 'لم يتم إنشاء استجابة.' : reply;
    } else {
      debugPrint('Ollama error: ${response.statusCode} — ${response.body}');
      throw Exception('خطأ من الخادم: ${response.statusCode}');
    }
  }

  Future<String> summarizeTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return 'لا يوجد نص للتلخيص.';

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({
        'model': kOllamaModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'أنت مساعد تعليمي. لخص نص حصة دراسية بالعربية بوضوح. '
                'تضمن: الموضوع الرئيسي، النقاط الأساسية، والأمثلة. '
                'لا تستخدم رموز التنسيق.',
          },
          {
            'role': 'user',
            'content': 'لخص هذا النص:\n\n$transcript',
          },
        ],
        'stream': false,
        'options': {
          'num_ctx': 4096,
          'temperature': 0.3,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['message']['content']?.toString().trim() ??
          'لم يتم إنشاء ملخص.';
    } else {
      throw Exception('Ollama summarize error: ${response.statusCode}');
    }
  }
}