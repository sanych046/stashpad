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
      id: map['id'],
      filename: map['filename'],
      size: map['size'],
      mimeType: map['mimeType'],
      localPath: map['localPath'],
      remoteUrl: map['remoteUrl'],
    );
  }
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
      id: map['id'],
      title: map['title'],
      content: map['content'],
      category: map['category'] ?? 'General',
      type: map['type'] ?? 'TEXT',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      isPinned: map['isPinned'] == 1,
      color: map['color'] ?? '#FFFFFF',
      attachments: attachments,
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
