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

class Label {
  final String id;
  final String name;
  final DateTime createdAt;

  Label({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Label.fromMap(Map<String, dynamic> map) {
    return Label(
      id: map['id'] as String,
      name: _toUtf8String(map['name']),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Label copyWith({String? name}) {
    return Label(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Attachment> attachments;
  final List<Label> labels;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.attachments = const [],
    this.labels = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map, {List<Attachment> attachments = const [], List<Label> labels = const []}) {
    return Note(
      id: map['id'] as String,
      title: _toUtf8String(map['title']),
      content: _toUtf8String(map['content']),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attachments: attachments,
      labels: labels,
    );
  }

  Note copyWith({
    String? title,
    String? content,
    DateTime? updatedAt,
    List<Attachment>? attachments,
    List<Label>? labels,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attachments: attachments ?? this.attachments,

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
