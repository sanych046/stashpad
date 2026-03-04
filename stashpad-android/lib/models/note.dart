import 'dart:convert';

class Attachment {
  final String id;
  final String filename;
  final int size;
  final String mimeType;
  final String? localPath;
  final String? remoteUrl;

  Attachment({
    required this.id,
    required this.filename,
    required this.size,
    required this.mimeType,
    this.localPath,
    this.remoteUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'localPath': localPath,
      'remoteUrl': remoteUrl,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: _toUtf8String(map['id']),
      filename: _toUtf8String(map['filename']),
      size: map['size'] as int,
      mimeType: _toUtf8String(map['mimeType']),
      localPath: _toUtf8String(map['localPath']),
      remoteUrl: _toUtf8String(map['remoteUrl']),
    );
  }
}

String _toUtf8String(dynamic value) {
  if (value == null) return '';
  if (value is String) return value;
  if (value is List<int>) return utf8.decode(value);
  return value.toString();
}

class Note {
  final String id;
  final String title;
  final String content;
  final String category;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPinned;
  final String color;
  final List<Attachment> attachments;

  Note({
    required this.id,
    required this.title,
    required this.content,
    this.category = 'General',
    this.type = 'TEXT',
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
    this.color = '#FFFFFF',
    this.attachments = const [],
  });

  Note copyWith({
    String? title,
    String? content,
    String? category,
    String? type,
    DateTime? updatedAt,
    bool? isPinned,
    String? color,
    List<Attachment>? attachments,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      type: type ?? this.type,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
      color: color ?? this.color,
      attachments: attachments ?? this.attachments,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPinned': isPinned ? 1 : 0,
      'color': color,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, {List<Attachment> attachments = const []}) {
    return Note(
      id: _toUtf8String(map['id']),
      title: _toUtf8String(map['title']),
      content: _toUtf8String(map['content']),
      category: _toUtf8String(map['category'] ?? 'General'),
      type: _toUtf8String(map['type'] ?? 'TEXT'),
      createdAt: DateTime.parse(_toUtf8String(map['createdAt'])),
      updatedAt: DateTime.parse(_toUtf8String(map['updatedAt'])),
      isPinned: map['isPinned'] == 1,
      color: _toUtf8String(map['color'] ?? '#FFFFFF'),
      attachments: attachments,
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
