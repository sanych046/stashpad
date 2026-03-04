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
    
    // In a real app, this password should be derived from user input or stored in a secure enclave
    // For this implementation, we use a fixed key as a placeholder for SQLCipher
    const String password = 'temporary_secure_key_stashpad';

    return await openDatabase(
      path,
      version: 2,
      password: password,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE notes (
            id TEXT PRIMARY KEY,
            title TEXT,
            content TEXT,
            category TEXT,
            type TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            isPinned INTEGER,
            color TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE attachments (
            id TEXT PRIMARY KEY,
            noteId TEXT,
            filename TEXT,
            size INTEGER,
            mimeType TEXT,
            localPath TEXT,
            remoteUrl TEXT,
            FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE attachments (
              id TEXT PRIMARY KEY,
              noteId TEXT,
              filename TEXT,
              size INTEGER,
              mimeType TEXT,
              localPath TEXT,
              remoteUrl TEXT,
              FOREIGN KEY (noteId) REFERENCES notes (id) ON DELETE CASCADE
            )
          ''');
        }
      },
    );
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
        attachmentMap['noteId'] = note.id;
        await txn.insert(
          'attachments',
          attachmentMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Note>> getNotes() async {
    final db = await database;
    final List<Map<String, dynamic>> noteMaps = await db.query('notes', orderBy: 'updatedAt DESC');
    
    List<Note> notes = [];
    for (var noteMap in noteMaps) {
      final List<Map<String, dynamic>> attachmentMaps = await db.query(
        'attachments',
        where: 'noteId = ?',
        whereArgs: [noteMap['id']],
      );
      
      final attachments = attachmentMaps.map((m) => Attachment.fromMap(m)).toList();
      notes.add(Note.fromMap(noteMap, attachments: attachments));
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
        attachmentMap['noteId'] = note.id;
        await txn.insert('attachments', attachmentMap);
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
  }
}
