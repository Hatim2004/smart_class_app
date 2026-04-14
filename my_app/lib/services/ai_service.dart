abstract class AIService {
  Future<String> chat(String userMessage, {String? pdfContext});
  Future<String> summarizeTranscript(String transcript);
}