import 'dart:convert';

class Attachment {
  final String id;
  final String filename;
  final int size;
  final String mimeType;
  final String? remoteUrl;

  Attachment({
    required this.id,
    required this.filename,
    required this.size,
    required this.mimeType,
    this.remoteUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'filename': filename,
      'size': size,
      'mimeType': mimeType,
      'remoteUrl': remoteUrl,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      filename: map['filename'] as String,
      size: map['size'] as int,
      mimeType: map['mimeType'] as String,
      remoteUrl: map['remoteUrl'] as String?,
    );
  }
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
      name: map['name'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
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
      'attachments': attachments.map((x) => x.toMap()).toList(),
      'labels': labels.map((x) => x.toMap()).toList(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      attachments: map['attachments'] != null
          ? List<Attachment>.from(map['attachments']?.map((x) => Attachment.fromMap(x)))
          : [],
      labels: map['labels'] != null
          ? List<Label>.from(map['labels']?.map((x) => Label.fromMap(x)))
          : [],
    );
  }

  String toJson() => json.encode(toMap());

  factory Note.fromJson(String source) => Note.fromMap(json.decode(source));
}
