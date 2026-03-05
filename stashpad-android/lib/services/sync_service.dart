import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cryptography/cryptography.dart';
import '../models/note.dart';
import 'database_service.dart';

class SyncService extends ChangeNotifier {
  WebSocketChannel? _channel;
  
  String get _wsUrl {
    final String host = kIsWeb ? 'localhost' : (defaultTargetPlatform == TargetPlatform.android ? '10.0.2.2' : 'localhost');
    return 'ws://$host:8000/ws';
  }
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  SecretKey? _sessionKey;
  final _algorithm = AesGcm.with256bits();
  
  String? _userId;
  String? get userId => _userId;

  DatabaseService? _databaseService;

  Future<void> connect(String userId, String sessionId, List<int> keyBytes, DatabaseService databaseService) async {
    _userId = userId;
    _sessionKey = SecretKey(keyBytes);
    _databaseService = databaseService;
    
    // Persist sync state in encrypted DB
    await _databaseService!.saveSyncState(userId, sessionId, keyBytes);

    // Note: In a real Android emulator, localhost is 10.0.2.2
    // If testing on a real device, this needs to be the server's IP
    final uri = Uri.parse('$_wsUrl/$userId/mobile');
    _channel = WebSocketChannel.connect(uri);
    
    _isConnected = true;
    notifyListeners();

    _channel!.stream.listen(
      (data) {
        _handleMessage(data);
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('WebSocket Error: $error');
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  Future<void> tryAutoConnect(DatabaseService databaseService) async {
    _databaseService = databaseService;
    final state = await _databaseService!.getSyncState();
    if (state != null) {
      debugPrint('Auto-connecting for user: ${state['userId']}');
      await connect(state['userId'], state['sessionId'], state['keyBytes'], databaseService);
    }
  }

  void _handleMessage(String data) async {
    debugPrint('Received message: $data');
    if (_databaseService == null || _sessionKey == null) return;
    
    try {
      final message = json.decode(data);
      final type = message['type'];
      
      if (type == 'SESSION_REVOKED') {
        _logout();
        return;
      }
      
      if (type == 'REQUEST_SYNC') {
        await syncAllNotes(_databaseService!);
      } else if (type == 'SYNC_NOTE' || type == 'NOTE_UPDATE') {
        final payload = message['payload'];
        final decryptedNote = await _decryptPayload(payload);
        if (decryptedNote != null) {
          await _databaseService!.insertNote(decryptedNote);
          // NOTE: In a more robust architecture, we'd trigger a general refresh event
          // But since HomeScreen listens to a stream or future of database notes, saving to DB is enough
          // if UI pulls from DB on resume. 
        }
      } else if (type == 'NOTE_DELETE') {
        final noteId = message['noteId'];
        await _databaseService!.deleteNote(noteId);
      }
    } catch (e) {
      debugPrint('Error handling message: $e');
    }
  }

  Future<Note?> _decryptPayload(Map<String, dynamic> payload) async {
    if (_sessionKey == null) return null;

    try {
      final nonce = base64.decode(payload['nonce']);
      final ciphertext = base64.decode(payload['ciphertext']);
      
      final secretBox = SecretBox(
        ciphertext,
        nonce: nonce,
        mac: Mac(base64.decode(payload['tag'])),
      );

      final clearText = await _algorithm.decrypt(
        secretBox,
        secretKey: _sessionKey!,
      );

      final noteMap = json.decode(utf8.decode(clearText));
      return Note.fromMap(noteMap);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }

  Future<void> syncAllNotes(DatabaseService databaseService) async {
    if (!_isConnected || _sessionKey == null) return;

    final notes = await databaseService.getNotes();
    for (var note in notes) {
      await syncNote(note);
    }
  }

  Future<void> syncNote(Note note) async {
    if (!_isConnected || _sessionKey == null) return;

    try {
      final noteJson = json.encode(note.toMap());
      final clearText = utf8.encode(noteJson);
      
      final secretBox = await _algorithm.encrypt(
        clearText,
        secretKey: _sessionKey!,
      );

      final payload = {
        'nonce': base64.encode(secretBox.nonce),
        'ciphertext': base64.encode(secretBox.cipherText),
        'tag': base64.encode(secretBox.mac.bytes),
      };

      final message = {
        'type': 'SYNC_NOTE',
        'payload': payload,
      };

      _channel?.sink.add(json.encode(message));
    } catch (e) {
      debugPrint('Error syncing note ${note.id}: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
     if (!_isConnected) return;
     
     final message = {
        'type': 'NOTE_DELETE',
        'noteId': noteId,
      };
      
      _channel?.sink.add(json.encode(message));
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    notifyListeners();
  }

  void _logout() async {
    disconnect();
    _userId = null;
    _sessionKey = null;
    if (_databaseService != null) {
      await _databaseService!.clearSyncState();
    }
    notifyListeners();
  }
}
