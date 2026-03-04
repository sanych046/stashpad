import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:cryptography/cryptography.dart';
import '../models/note.dart';

class SyncService extends ChangeNotifier {
  WebSocketChannel? _channel;
  final String _serverUrl = 'ws://localhost:8000/ws'; // Adjust for production
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _userId;
  String? get userId => _userId;
  
  final List<Note> _notes = [];
  List<Note> get notes => _notes;

  SecretKey? _sessionKey;
  final _algorithm = AesGcm.with256bits();

  Future<void> connect(String userId, String sessionId, List<int> masterKeyBytes) async {
    _userId = userId;
    _sessionKey = SecretKey(masterKeyBytes);
    
    final uri = Uri.parse('$_serverUrl/$userId');
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
    if (index >= 0) {
      _notes[index] = note;
    } else {
      _notes.add(note);
    }
    notifyListeners();
  }

  void _removeNote(String noteId) {
    _notes.removeWhere((n) => n.id == noteId);
    notifyListeners();
  }

  void disconnect() {
    _channel?.sink.close();
    _isConnected = false;
    _notes.clear();
    notifyListeners();
  }
}
