import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/note.dart';
import '../services/database_service.dart';
import '../widgets/create_stash_dialog.dart';

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
      builder: (context) => const CreateStashDialog(),
    );

    if (newNote != null) {
      await databaseService.insertNote(newNote);
      if (!context.mounted) return;
      setState(() {}); // Refresh list
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New stash created!')),
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
                  title: Text(note.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    note.content.isEmpty ? 'Empty stash' : note.content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(
                    '${note.updatedAt.day}/${note.updatedAt.month}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () {
                    // TODO: Open note editor
                  },
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
