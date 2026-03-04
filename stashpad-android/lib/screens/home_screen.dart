import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../widgets/note_editor_dialog.dart';
import 'connect_web_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _selectedLabelId; // null = All, 'unlabeled' = Unlabeled, else = labelId
  String _selectedLabelName = 'Stashpad';

  void _createNewNote(BuildContext context) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    final Note? newNote = await showDialog<Note>(
      context: context,
      builder: (context) => const NoteEditorDialog(),
    );

    if (newNote != null) {
      await databaseService.insertNote(newNote);
      if (!context.mounted) return;
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New stash created!')),
      );
    }
  }

  void _editNote(BuildContext context, Note note) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    final Note? updatedNote = await showDialog<Note>(
      context: context,
      builder: (context) => NoteEditorDialog(existingNote: note),
    );

    if (updatedNote != null) {
      await databaseService.updateNote(updatedNote);
      if (!context.mounted) return;
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stash updated!')),
      );
    }
  }

  void _confirmDelete(BuildContext context, Note note) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Stash?'),
        content: Text('Are you sure you want to delete "${note.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await databaseService.deleteNote(note.id);
      if (!context.mounted) return;
      setState(() {});
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stash deleted')),
      );
    }
  }

  void _showManageLabelsDialog(BuildContext context) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    await showDialog(
      context: context,
      builder: (context) => ManageLabelsDialog(databaseService: databaseService),
    );
    setState(() {}); // Refresh labels in drawer
  }

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedLabelName),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final Note? selectedNote = await showSearch<Note?>(
                context: context,
                delegate: NoteSearchDelegate(
                  databaseService: databaseService,
                  onShare: _shareNote,
                  onCopy: _copyNote,
                  onDelete: (note) => _confirmDelete(context, note),
                ),
              );
              if (selectedNote != null && context.mounted) {
                _editNote(context, selectedNote);
              }
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'connect') {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const ConnectWebScreen()),
                );
              } else if (value == 'settings') {
                _showSettings(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'connect',
                child: Row(
                  children: [
                    Icon(Icons.qr_code_scanner, size: 20),
                    SizedBox(width: 12),
                    Text('Connect Web client'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 20),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: Center(
                child: Text(
                  'Stashpad',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: const Text('Notes'),
              selected: _selectedLabelId == null,
              onTap: () {
                setState(() {
                  _selectedLabelId = null;
                  _selectedLabelName = 'Stashpad';
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_off_outlined),
              title: const Text('Unlabeled'),
              selected: _selectedLabelId == 'unlabeled',
              onTap: () {
                setState(() {
                  _selectedLabelId = 'unlabeled';
                  _selectedLabelName = 'Unlabeled';
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LABELS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showManageLabelsDialog(context),
                    child: const Text('Edit'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Label>>(
                future: databaseService.getLabels(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox();
                  }
                  final labels = snapshot.data!;
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      final label = labels[index];
                      return ListTile(
                        leading: const Icon(Icons.label_outlined),
                        title: Text(label.name),
                        selected: _selectedLabelId == label.id,
                        onTap: () {
                          setState(() {
                            _selectedLabelId = label.id;
                            _selectedLabelName = label.name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showSettings(context);
              },
            ),
          ],
        ),
      ),
      body: FutureBuilder<List<Note>>(
        future: databaseService.getNotes(labelId: _selectedLabelId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _selectedLabelId == null ? Icons.lightbulb_outline : Icons.label_outline, 
                    size: 120, 
                    color: Theme.of(context).colorScheme.outlineVariant
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _selectedLabelId == null 
                      ? 'Notes you add appear here'
                      : 'No notes with this label',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.outline
                    ),
                  ),
                ],
              ),
            );
          }

          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _editNote(context, note),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                note.title,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _confirmDelete(context, note);
                                } else if (value == 'share') {
                                  _shareNote(note);
                                } else if (value == 'copy') {
                                  _copyNote(note);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'share',
                                  child: Row(
                                    children: [
                                      Icon(Icons.share, size: 20),
                                      SizedBox(width: 8),
                                      Text('Share'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'copy',
                                  child: Row(
                                    children: [
                                      Icon(Icons.copy, size: 20),
                                      SizedBox(width: 8),
                                      Text('Copy to buffer'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (note.content.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            note.content,
                            maxLines: 5,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        if (note.labels.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: note.labels.map((label) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label.name,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            )).toList(),
                          ),
                        ],
                        if (note.attachments.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: note.attachments.take(3).map((a) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondaryContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getIconForMime(a.mimeType), 
                                    size: 14,
                                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      a.filename,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                          ),
                          if (note.attachments.length > 3)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '+${note.attachments.length - 3} more',
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => _createNewNote(context),
        elevation: 2,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon!')),
    );
  }

  IconData _getIconForMime(String mimeType) {
    if (mimeType.startsWith('image/')) return Icons.image;
    if (mimeType.startsWith('video/')) return Icons.movie;
    if (mimeType.startsWith('audio/')) return Icons.audiotrack;
    return Icons.insert_drive_file;
  }
}

class ManageLabelsDialog extends StatefulWidget {
  final DatabaseService databaseService;

  const ManageLabelsDialog({super.key, required this.databaseService});

  @override
  State<ManageLabelsDialog> createState() => _ManageLabelsDialogState();
}

class _ManageLabelsDialogState extends State<ManageLabelsDialog> {
  final _labelController = TextEditingController();
  // final _uuid = const Uuid(); // Uuid import is missing in the original document, but present in the provided snippet.
                               // Assuming it's intended to be imported if used.
  // For now, commenting out to avoid error if Uuid is not imported.
  // If Uuid is needed, add 'package:uuid/uuid.dart'; to imports.

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  void _addLabel() async {
    if (_labelController.text.trim().isEmpty) return;
    
    final newLabel = Label(
      id: _uuid.v4(),
      name: _labelController.text.trim(),
      createdAt: DateTime.now(),
    );
    
    await widget.databaseService.insertLabel(newLabel);
    _labelController.clear();
    setState(() {});
  }

  void _deleteLabel(String id) async {
    await widget.databaseService.deleteLabel(id);
    setState(() {});
  }

  void _editLabel(Label label) async {
    final editController = TextEditingController(text: label.name);
    final String? newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Label'),
        content: TextField(
          controller: editController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Label name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, editController.text.trim()), child: const Text('Save')),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != label.name) {
      await widget.databaseService.updateLabel(label.copyWith(name: newName));
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Labels'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _labelController,
                    decoration: const InputDecoration(
                      hintText: 'Create new label',
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _addLabel,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: FutureBuilder<List<Label>>(
                future: widget.databaseService.getLabels(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No labels yet');
                  }
                  final labels = snapshot.data!;
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: labels.length,
                    itemBuilder: (context, index) {
                      final label = labels[index];
                      return ListTile(
                        leading: const Icon(Icons.label_outlined, size: 20),
                        title: Text(label.name),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editLabel(label),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _deleteLabel(label.id),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class NoteSearchDelegate extends SearchDelegate<Note?> {
  final DatabaseService databaseService;
  final Function(Note) onShare;
  final Function(Note) onCopy;
  final Function(Note) onDelete;

  NoteSearchDelegate({
    required this.databaseService,
    required this.onShare,
    required this.onCopy,
    required this.onDelete,
  });

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Search stashes by keyword'));
    }
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Note>>(
      future: databaseService.searchNotes(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No matches found'));
        }

        final notes = snapshot.data!;
        return ListView.builder(
          itemCount: notes.length,
          padding: const EdgeInsets.all(8),
          itemBuilder: (context, index) {
            final note = notes[index];
            return Card(
              elevation: 1,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
              child: ListTile(
                title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(
                  note.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  close(context, note);
                },
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onSelected: (value) {
                    if (value == 'delete') {
                      onDelete(note);
                    } else if (value == 'share') {
                      onShare(note);
                    } else if (value == 'copy') {
                      onCopy(note);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'share',
                      child: Row(
                        children: [
                          Icon(Icons.share, size: 20),
                          SizedBox(width: 8),
                          Text('Share'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'copy',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 20),
                          SizedBox(width: 8),
                          Text('Copy to buffer'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Delete',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
