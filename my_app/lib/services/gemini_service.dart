import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants.dart';

class GeminiService {
  // Use gemini-1.5-flash for speed/cost or gemini-1.5-pro for complex reasoning
   GenerativeModel _modelInit(String systemInstruction) {
    return GenerativeModel(
      model: 'gemini-1.5-flash', 
      apiKey: kGeminiApiKey, // Define this in your constants.dart
      systemInstruction: Content.system(systemInstruction),
    );
  }

  /// Chat with optional PDF context injected into the system prompt.
  Future<String> chat(String userMessage, {String? pdfContext}) async {
    final systemPrompt = pdfContext != null
        ? '''أنت مساعد تعليمي ذكي للمعلم. يمكنك شرح محتوى الدرس للطلاب بطريقة واضحة وبسيطة.
لديك المستند التالي كمرجع للإجابة على الأسئلة:

$pdfContext

قواعد مهمة:
- أجب دائماً بالعربية الفصيحة المحكية بشكل طبيعي
- اشرح المفاهيم بأسلوب مبسط مناسب للطلاب
- استند إلى محتوى المستند عند الإجابة
- كن موجزاً ودقيقاً
- لا تستخدم رموز التنسيق كالنجوم أو الشرطات'''
        : '''أنت مساعد صوتي للمعلم داخل الفصل.
أجب دائماً بالعربية الفصيحة بشكل طبيعي ومختصر ومباشر.
لا تستخدم رموز التنسيق.''';

    try {
      final model = _modelInit(systemPrompt);
      final response = await model.generateContent([Content.text(userMessage)]);
      
      return response.text?.trim() ?? 'لم يتم إنشاء استجابة.';
    } catch (e) {
      throw Exception('Gemini Error: $e');
    }
  }

  /// Summarize a class transcript.
  Future<String> summarizeTranscript(String transcript) async {
    if (transcript.trim().isEmpty) return 'لا يوجد نص للتلخيص.';

    const systemPrompt =
        'أنت مساعد تعليمي. ستتلقى نص تسجيل صوتي لحصة دراسية. '
        'قم بإنشاء ملخص واضح ومنظم بالعربية يتضمن: '
        '١) الموضوع الرئيسي، '
        '٢) النقاط والمفاهيم الأساسية، '
        '٣) أي أمثلة أو تمارين ذُكرت. '
        'اكتب بأسلوب واضح دون رموز تنسيق.';

    try {
      final model = _modelInit(systemPrompt);
      final response = await model.generateContent([
        Content.text('لخص هذا النص:\n\n$transcript')
      ]);

      return response.text?.trim() ?? 'لم يتم إنشاء ملخص.';
    } catch (e) {
      throw Exception('Gemini Summarize Error: $e');
    }
  }
}