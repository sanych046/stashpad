import 'dart:async';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../models/note.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'stashpad_secure.db');
    const String password = 'temporary_secure_key_stashpad';

    return await openDatabase(
      path,
      version: 3,
      password: password,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON;");
        await db.execute("PRAGMA encoding = 'UTF-8';");
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute("PRAGMA encoding = 'UTF-8';");
    await db.execute('''
      CREATE TABLE notes(
        id TEXT PRIMARY KEY,
        title TEXT,
        content TEXT,
        createdAt TEXT,
        updatedAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE attachments(
        id TEXT PRIMARY KEY,
        noteId TEXT,
        filename TEXT,
        size INTEGER,
        mimeType TEXT,
        localPath TEXT,
        FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE labels(
        id TEXT PRIMARY KEY,
        name TEXT UNIQUE,
        createdAt TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE note_labels(
        note_id TEXT,
        label_id TEXT,
        PRIMARY KEY (note_id, label_id),
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE,
        FOREIGN KEY (label_id) REFERENCES labels (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Version 2 introduced foreign keys and Cascading deletes if not already present
      // But we mostly need the new tables now.
    }
    if (oldVersion < 3) {
      // Version 3 adds labels and note_labels
      await db.execute('''
        CREATE TABLE IF NOT EXISTS labels(
          id TEXT PRIMARY KEY,
          name TEXT UNIQUE,
          createdAt TEXT
        )
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS note_labels(
          note_id TEXT,
          label_id TEXT,
          PRIMARY KEY (note_id, label_id),
          FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE,
          FOREIGN KEY (label_id) REFERENCES labels (id) ON DELETE CASCADE
        )
      ''');
    }
  }

  // Note CRUD operations
  Future<void> insertNote(Note note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        'notes',
        note.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      
      for (var attachment in note.attachments) {
        final attachmentMap = attachment.toMap();
        attachmentMap['noteId'] = note.id; // Ensure noteId is set for attachment
        await txn.insert(
          'attachments',
          attachmentMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      for (var label in note.labels) {
        await txn.insert('note_labels', {
          'note_id': note.id,
          'label_id': label.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<List<Note>> getNotes({String? labelId}) async {
    final db = await database;
    String query = 'SELECT * FROM notes';
    List<dynamic> params = [];

    if (labelId != null) {
      if (labelId == 'unlabeled') {
        query = 'SELECT * FROM notes WHERE id NOT IN (SELECT note_id FROM note_labels)';
      } else {
        query = 'SELECT n.* FROM notes n JOIN note_labels nl ON n.id = nl.note_id WHERE nl.label_id = ?';
        params = [labelId];
      }
    }

    final List<Map<String, dynamic>> maps = await db.rawQuery('$query ORDER BY updatedAt DESC', params);
    
    List<Note> notes = [];
    for (var map in maps) {
      final noteId = map['id'] as String;
      final List<Map<String, dynamic>> attachmentMaps = await db.query(
        'attachments',
        where: 'noteId = ?',
        whereArgs: [noteId],
      );
      
      final List<Map<String, dynamic>> labelMaps = await db.rawQuery(
        'SELECT l.* FROM labels l JOIN note_labels nl ON l.id = nl.label_id WHERE nl.note_id = ?',
        [noteId],
      );

      notes.add(Note.fromMap(
        map,
        attachments: attachmentMaps.map((a) => Attachment.fromMap(a)).toList(),
        labels: labelMaps.map((l) => Label.fromMap(l)).toList(),
      ));
    }
    return notes;
  }

  Future<void> updateNote(Note note) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'notes',
        note.toMap(),
        where: 'id = ?',
        whereArgs: [note.id],
      );
      
      // For simplicity, replace all attachments on update
      await txn.delete('attachments', where: 'noteId = ?', whereArgs: [note.id]);
      for (var attachment in note.attachments) {
        final attachmentMap = attachment.toMap();
        attachmentMap['noteId'] = note.id; // Ensure noteId is set for attachment
        await txn.insert('attachments', attachmentMap, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      // Update labels: delete existing and insert new ones
      await txn.delete('note_labels', where: 'note_id = ?', whereArgs: [note.id]);
      for (var label in note.labels) {
        await txn.insert('note_labels', {
          'note_id': note.id,
          'label_id': label.id,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }

  Future<void> deleteNote(String id) async {
    final db = await database;
    await db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
    // ON DELETE CASCADE will handle attachments and note_labels
  }

  Future<List<Note>> searchNotes(String keyword) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'notes',
      where: 'title LIKE ? OR content LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'updatedAt DESC',
    );

    List<Note> notes = [];
    for (var map in maps) {
      final noteId = map['id'] as String;
      final List<Map<String, dynamic>> attachmentMaps = await db.query(
        'attachments',
        where: 'noteId = ?',
        whereArgs: [noteId],
      );
      
      final List<Map<String, dynamic>> labelMaps = await db.rawQuery(
        'SELECT l.* FROM labels l JOIN note_labels nl ON l.id = nl.label_id WHERE nl.note_id = ?',
        [noteId],
      );

      notes.add(Note.fromMap(
        map,
        attachments: attachmentMaps.map((a) => Attachment.fromMap(a)).toList(),
        labels: labelMaps.map((l) => Label.fromMap(l)).toList(),
      ));
    }
    return notes;
  }

  // Label Operations
  Future<List<Label>> getLabels() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('labels', orderBy: 'name ASC');
    return maps.map((l) => Label.fromMap(l)).toList();
  }

  Future<void> insertLabel(Label label) async {
    final db = await database;
    await db.insert('labels', label.toMap(), conflictAlgorithm: ConflictAlgorithm.ignore); // Use ignore to prevent duplicate names
  }

  Future<void> updateLabel(Label label) async {
    final db = await database;
    await db.update(
      'labels',
      label.toMap(),
      where: 'id = ?',
      whereArgs: [label.id],
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteLabel(String id) async {
    final db = await database;
    await db.delete('labels', where: 'id = ?', whereArgs: [id]);
    // ON DELETE CASCADE will handle note_labels entries
  }
}
```
