import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../widgets/note_editor_dialog.dart';

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
        title: const Text('My Stashes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
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
                  Icon(Icons.note_alt_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No stashes yet',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final notes = snapshot.data!;
          return ListView.builder(
            itemCount: notes.length,
            padding: const EdgeInsets.all(8),
            itemBuilder: (context, index) {
              final note = notes[index];
              return Card(
                elevation: 0,
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.description_outlined),
                  ),
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        note.content.isEmpty ? 'Empty stash' : note.content,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (note.attachments.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Row(
                            children: [
                              Icon(Icons.attach_file, size: 12, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 4),
                              Text(
                                '${note.attachments.length} attachment${note.attachments.length > 1 ? 's' : ''}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _editNote(context, note);
                      } else if (value == 'delete') {
                        _confirmDelete(context, note);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, size: 20, color: Theme.of(context).colorScheme.error),
                            const SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _editNote(context, note),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _createNewNote(context),
        icon: const Icon(Icons.add),
        label: const Text('New Stash'),
      ),
    );
  }
}
