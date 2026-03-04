import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class NoteEditorDialog extends StatefulWidget {
  final Note? existingNote;

  const NoteEditorDialog({super.key, this.existingNote});

  @override
  State<NoteEditorDialog> createState() => _NoteEditorDialogState();
}

class _NoteEditorDialogState extends State<NoteEditorDialog> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late List<Attachment> _attachments;
  final _uuid = const Uuid();
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingNote?.title ?? '');
    _contentController = TextEditingController(text: widget.existingNote?.content ?? '');
    _attachments = List.from(widget.existingNote?.attachments ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _pickFile(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        for (var file in result.files) {
          if (file.path != null) {
            _attachments.add(
              Attachment(
                id: _uuid.v4(),
                filename: file.name,
                size: file.size,
                mimeType: _getMimeType(file.extension, type),
                localPath: file.path,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not access file: ${file.name}')),
            );
          }
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      final bytes = await photo.length();
      setState(() {
        _attachments.add(
          Attachment(
            id: _uuid.v4(),
            filename: 'Photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
            size: bytes,
            mimeType: 'image/jpeg',
            localPath: photo.path,
          ),
        );
      });
    }
  }

  Future<void> _recordVideo() async {
    final XFile? video = await _imagePicker.pickVideo(source: ImageSource.camera);
    if (video != null) {
      final bytes = await video.length();
      setState(() {
        _attachments.add(
          Attachment(
            id: _uuid.v4(),
            filename: 'Video_${DateTime.now().millisecondsSinceEpoch}.mp4',
            size: bytes,
            mimeType: 'video/mp4',
            localPath: video.path,
          ),
        );
      });
    }
  }

  Future<void> _toggleAudioRecording() async {
    if (_isRecording) {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        final file = File(path);
        final bytes = await file.length();
        setState(() {
          _attachments.add(
            Attachment(
              id: _uuid.v4(),
              filename: 'Audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
              size: bytes,
              mimeType: 'audio/m4a',
              localPath: path,
            ),
          );
        });
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path = '${directory.path}/audio_${_uuid.v4()}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        setState(() => _isRecording = true);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    }
  }

  String _getMimeType(String? extension, FileType type) {
    if (extension != null) return 'application/$extension';
    switch (type) {
      case FileType.image: return 'image/*';
      case FileType.video: return 'video/*';
      case FileType.audio: return 'audio/*';
      default: return 'application/octet-stream';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingNote != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Stash' : 'New Stash'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter stash title',
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                hintText: 'Enter stash text',
                alignLabelWithHint: true,
              ),
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
                if (_isRecording)
                  const Row(
                    children: [
                      Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                      SizedBox(width: 4),
                      Text('Recording...', style: TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: [
                _buildAttachButton(Icons.image, 'Image', () => _pickFile(FileType.image)),
                _buildAttachButton(Icons.camera_alt, 'Photo', _takePhoto),
                _buildAttachButton(Icons.videocam, 'Video', () => _pickFile(FileType.video)),
                _buildAttachButton(Icons.video_call, 'Record', _recordVideo),
                _buildAttachButton(Icons.audiotrack, 'Audio', () => _pickFile(FileType.audio)),
                _buildAttachButton(
                  _isRecording ? Icons.stop : Icons.mic, 
                  _isRecording ? 'Stop' : 'Voice', 
                  _toggleAudioRecording,
                  color: _isRecording ? Colors.red : null,
                ),
                _buildAttachButton(Icons.file_present, 'File', () => _pickFile(FileType.any)),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final attachment = _attachments[index];
                    return Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(_getIconForMime(attachment.mimeType), size: 24),
                                  const SizedBox(height: 4),
                                  Text(
                                    attachment.filename,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close, size: 16),
                              onPressed: () {
                                setState(() {
                                  _attachments.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_titleController.text.isEmpty && _contentController.text.isEmpty && _attachments.isEmpty) {
              return;
            }
            final now = DateTime.now();
            final note = isEditing 
              ? widget.existingNote!.copyWith(
                  title: _titleController.text.isEmpty ? 'Untitled Stash' : _titleController.text,
                  content: _contentController.text,
                  updatedAt: now,
                  attachments: _attachments,
                )
              : Note(
                  id: _uuid.v4(),
                  title: _titleController.text.isEmpty ? 'Untitled Stash' : _titleController.text,
                  content: _contentController.text,
                  createdAt: now,
                  updatedAt: now,
                  attachments: _attachments,
                );
            Navigator.of(context).pop(note);
          },
          child: Text(isEditing ? 'Save' : 'Create'),
        ),
      ],
    );
  }

  Widget _buildAttachButton(IconData icon, String label, VoidCallback onPressed, {Color? color}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  IconData _getIconForMime(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.movie;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }
}
