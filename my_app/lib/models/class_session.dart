class ClassSession {
  final String id;
  final DateTime date;
  final String title;
  final Duration duration;
  final String audioFilePath; // path to the saved .mp4 recording
  final String transcript;    // empty until transcribed
  final String summary;       // empty until summarized

  ClassSession({
    required this.id,
    required this.date,
    required this.title,
    required this.duration,
    required this.audioFilePath,
    this.transcript = '',
    this.summary = '',
  });

  bool get hasAudio      => audioFilePath.isNotEmpty;
  bool get hasTranscript => transcript.isNotEmpty;
  bool get hasSummary    => summary.isNotEmpty;

  /// Returns a copy with updated fields
  ClassSession copyWith({
    String? transcript,
    String? summary,
    String? title,
  }) =>
      ClassSession(
        id: id,
        date: date,
        title: title ?? this.title,
        duration: duration,
        audioFilePath: audioFilePath,
        transcript: transcript ?? this.transcript,
        summary: summary ?? this.summary,
      );

  String get transcriptPreview {
    if (transcript.isEmpty) return 'لا يوجد نص بعد.';
    return transcript.length > 120
        ? '${transcript.substring(0, 120)}…'
        : transcript;
  }

  String get formattedDuration {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}س ${m}د ${s}ث' : '${m}:${s}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'title': title,
        'durationSeconds': duration.inSeconds,
        'audioFilePath': audioFilePath,
        'transcript': transcript,
        'summary': summary,
      };

  factory ClassSession.fromJson(Map<String, dynamic> json) => ClassSession(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        title: json['title'] as String? ?? 'حصة',
        duration: Duration(seconds: json['durationSeconds'] as int),
        audioFilePath: json['audioFilePath'] as String? ?? '',
        transcript: json['transcript'] as String? ?? '',
        summary: json['summary'] as String? ?? '',
      );
}
