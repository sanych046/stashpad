import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cryptography/cryptography.dart';
import '../models/note.dart';
import 'storage_service.dart';

class SyncService extends ChangeNotifier {
  final _storage = StorageService();
  final List<Note> _notes = [];
  IOWebSocketChannel? _channel;
  bool _isConnected = false;

  String? _userId;
  String? _sessionId;
  List<int>? _masterKeyBytes;

  List<Note> get notes => _notes;
  bool get isConnected => _isConnected;
  String? get userId => _userId;

  SecretKey? _sessionKey;
  final _algorithm = AesGcm.with256bits();

  SyncService() {
    _initFromStorage();
  }

  Future<void> _initFromStorage() async {
    _userId = await _storage.getString('user_id');
    _sessionId = await _storage.getString('session_id');
    final masterKeyHex = await _storage.getString('master_key');
    
    if (_userId != null && _sessionId != null && masterKeyHex != null) {
      _masterKeyBytes = _hexToBytes(masterKeyHex);
      _sessionKey = SecretKey(_masterKeyBytes!);
      
      // Load encrypted notes
      final notesJson = await _storage.getEncrypted('notes_cache', _masterKeyBytes!);
      if (notesJson != null) {
        final List<dynamic> list = json.decode(notesJson);
        _notes.clear();
        _notes.addAll(list.map((m) => Note.fromMap(m)));
        notifyListeners();
      }
      
      // Auto reconnect
      reconnect();
    }
  }

  Future<void> _saveToStorage() async {
    if (_userId != null) await _storage.saveString('user_id', _userId!);
    if (_sessionId != null) await _storage.saveString('session_id', _sessionId!);
    if (_masterKeyBytes != null) await _storage.saveString('master_key', _bytesToHex(_masterKeyBytes!));
    
    if (_masterKeyBytes != null && _notes.isNotEmpty) {
      final notesJson = json.encode(_notes.map((n) => n.toMap()).toList());
      await _storage.saveEncrypted('notes_cache', notesJson, _masterKeyBytes!);
    }
  }

  String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  List<int> _hexToBytes(String hex) {
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return bytes;
  }

  Future<void> connect(String userId, String sessionId, List<int> masterKeyBytes) async {
    _userId = userId;
    _sessionId = sessionId;
    _masterKeyBytes = masterKeyBytes;
    _sessionKey = SecretKey(masterKeyBytes);
    
    final uri = Uri.parse('ws://localhost:8000/ws/$userId/$sessionId');
    _channel = IOWebSocketChannel.connect(uri);
    
    await _saveToStorage();
    
    _isConnected = true;
    notifyListeners();
    
    // Request full sync upon connection
    _channel!.sink.add(json.encode({'type': 'REQUEST_SYNC'}));

    _channel!.stream.listen(
      (data) {
        _handleMessage(data);
      },
      onDone: () {
        _isConnected = false;
        notifyListeners();
      },
      onError: (error) {
        print('WebSocket Error: $error');
        _isConnected = false;
        notifyListeners();
      },
    );
  }

  void _handleMessage(String data) async {
    try {
      final message = json.decode(data);
      final type = message['type'];
      final payload = message['payload'];

      if (message['type'] == 'SESSION_REVOKED') {
        _logout();
        return;
      }

      if (type == 'SYNC_NOTE' || type == 'NOTE_UPDATE') {
        final decryptedNote = await _decryptPayload(payload);
        if (decryptedNote != null) {
          _updateNote(decryptedNote);
        }
      } else if (type == 'NOTE_DELETE') {
        final noteId = message['noteId'];
        _removeNote(noteId);
      }
    } catch (e) {
      print('Error handling message: $e');
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
      print('Decryption error: $e');
      return null;
    }
  }

  void _updateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index != -1) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    _saveToStorage();
    notifyListeners();
  }

  void _removeNote(String noteId) {
    _notes.removeWhere((n) => n.id == noteId);
    _saveToStorage();
    notifyListeners();
  }

  void logout() {
    _logout();
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    notifyListeners();
  }

  void _logout() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _userId = null;
    _sessionId = null;
    _masterKeyBytes = null;
    _sessionKey = null;
    _notes.clear();
    _storage.clearAll();
    notifyListeners();
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
      _updateNote(note); // Optimistic update
    } catch (e) {
      print('Error syncing note ${note.id}: $e');
    }
  }

  Future<void> deleteNote(String noteId) async {
     if (!_isConnected) return;
     
     final message = {
        'type': 'NOTE_DELETE',
        'noteId': noteId,
      };
      
      _channel?.sink.add(json.encode(message));
      _removeNote(noteId); // Optimistic update
  }
  
  void reconnect() {
    if (_userId != null && _sessionId != null && _masterKeyBytes != null) {
      connect(_userId!, _sessionId!, _masterKeyBytes!);
    }
  }
}
