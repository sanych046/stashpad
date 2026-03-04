import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/note.dart';

class CreateStashDialog extends StatefulWidget {
  const CreateStashDialog({super.key});

  @override
  State<CreateStashDialog> createState() => _CreateStashDialogState();
}

class _CreateStashDialogState extends State<CreateStashDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<Attachment> _attachments = [];
  final _uuid = const Uuid();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
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
          _attachments.add(
            Attachment(
              id: _uuid.v4(),
              filename: file.name,
              size: file.size,
              mimeType: _getMimeType(file.extension, type),
              localPath: file.path,
            ),
          );
        }
      });
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
    return AlertDialog(
      title: const Text('New Stash'),
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
            const Text('Attachments', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachButton(Icons.image, 'Image', FileType.image),
                _buildAttachButton(Icons.videocam, 'Video', FileType.video),
                _buildAttachButton(Icons.audiotrack, 'Audio', FileType.audio),
                _buildAttachButton(Icons.file_present, 'File', FileType.any),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 16),
              Flexible(
                child: SizedBox(
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
            final note = Note(
              id: _uuid.v4(),
              title: _titleController.text.isEmpty ? 'Untitled Stash' : _titleController.text,
              content: _contentController.text,
              createdAt: now,
              updatedAt: now,
              attachments: _attachments,
            );
            Navigator.of(context).pop(note);
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  Widget _buildAttachButton(IconData icon, String label, FileType type) {
    return Column(
      children: [
        IconButton.filledTonal(
          onPressed: () => _pickFile(type),
          icon: Icon(icon),
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
