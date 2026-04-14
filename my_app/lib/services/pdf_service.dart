import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PdfService {
  Future<PdfResult?> pickAndExtract() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return null;

      final pickedFile = result.files.first;
      final fileName = pickedFile.name;

      Uint8List bytes;
      if (pickedFile.bytes != null) {
        bytes = pickedFile.bytes!;
      } else if (pickedFile.path != null) {
        bytes = await File(pickedFile.path!).readAsBytes();
      } else {
        throw Exception('تعذّر قراءة الملف.');
      }

      final text = await _extractText(bytes);

      if (text.trim().isEmpty) {
        throw Exception('لم يتم العثور على نص في هذا الملف. قد يكون مسحاً ضوئياً.');
      }

      return PdfResult(fileName: fileName, text: text.trim());
    } catch (e) {
      debugPrint('PDF extraction error: $e');
      rethrow;
    }
  }

  Future<String> _extractText(Uint8List bytes) async {
    return await compute(_extractInIsolate, bytes);
  }

  static String _extractInIsolate(Uint8List bytes) {
    final document = PdfDocument(inputBytes: bytes);
    final extractor = PdfTextExtractor(document);
    final buffer = StringBuffer();

    for (int i = 0; i < document.pages.count; i++) {
      final pageText = extractor.extractText(startPageIndex: i, endPageIndex: i);
      if (pageText.trim().isNotEmpty) {
        buffer.writeln('--- صفحة ${i + 1} ---');
        buffer.writeln(pageText.trim());
        buffer.writeln();
      }
    }

    document.dispose();
    return buffer.toString();
  }
}

class PdfResult {
  final String fileName;
  final String text;

  const PdfResult({required this.fileName, required this.text});

  int get pageCount => text.split('--- صفحة').length - 1;
  int get charCount => text.length;

  /// qwen2:1.5b default context = 2048 tokens ≈ ~1200 Arabic chars safe limit.
  /// We tell Ollama to use num_ctx:4096, giving us ~2500 chars for PDF content.
  /// For larger models (qwen2:7b, llama3 etc.) you can raise this.
  String contextFor({int maxChars = 2500}) {
    if (text.length <= maxChars) return text;
    // Take the first portion — usually the most important part of a lesson PDF
    return '${text.substring(0, maxChars)}\n\n'
        '[ملاحظة: تم اقتصار النص على أول $maxChars حرف من أصل ${text.length} حرف. '
        'يمكنك سؤالي عن صفحة محددة وسأركز عليها.]';
  }
}