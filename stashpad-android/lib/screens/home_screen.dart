import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stashpad'),
        elevation: 0,
        scrolledUnderElevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final Note? selectedNote = await showSearch<Note?>(
                context: context,
                delegate: NoteSearchDelegate(databaseService: databaseService),
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
      body: FutureBuilder<List<Note>>(
        future: databaseService.getNotes(),
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
                    Icons.lightbulb_outline, 
                    size: 120, 
                    color: Theme.of(context).colorScheme.outlineVariant
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Notes you add appear here',
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
                                if (value == 'delete') _confirmDelete(context, note);
                              },
                              itemBuilder: (context) => [
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

class NoteSearchDelegate extends SearchDelegate<Note?> {
  final DatabaseService databaseService;

  NoteSearchDelegate({required this.databaseService});

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
                  // The Home screen handles opening the editor after the search closes
                },
              ),
            );
          },
        );
      },
    );
  }
}
