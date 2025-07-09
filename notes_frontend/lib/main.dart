import 'package:flutter/material.dart';

// PUBLIC_INTERFACE
void main() {
  runApp(const NotesApp());
}

/// The main NotesApp widget, applying the custom light theme and
/// serving as the entry point of the application.
// PUBLIC_INTERFACE
class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorPrimary = const Color(0xFF1976D2);
    final colorSecondary = const Color(0xFF424242);
    final colorAccent = const Color(0xFFFFC107);
    return MaterialApp(
      title: 'NoteEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.light(
          primary: colorPrimary,
          secondary: colorSecondary,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          elevation: 0.25,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: -1,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorAccent,
          foregroundColor: Colors.black87,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black38),
        ),
        scaffoldBackgroundColor: Colors.white,
        dividerColor: Colors.grey.shade200,
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      home: const NotesListScreen(),
    );
  }
}

/// Data model for a Note.
class Note {
  int id;
  String title;
  String content;
  DateTime updatedAt;
  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.updatedAt,
  });

  /// Generate a copy with optional overrides
  Note copyWith({String? title, String? content, DateTime? updatedAt}) => Note(
        id: id,
        title: title ?? this.title,
        content: content ?? this.content,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class NotesRepository extends ChangeNotifier {
  int _nextId = 1;
  final List<Note> _notes = [];

  List<Note> getNotes({String? query}) {
    if (query == null || query.trim().isEmpty) {
      return List.unmodifiable(_notes)..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final lowercaseQuery = query.trim().toLowerCase();
    return List.unmodifiable(_notes.where((n) =>
      n.title.toLowerCase().contains(lowercaseQuery) ||
      n.content.toLowerCase().contains(lowercaseQuery)
    ))..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  void addNote(String title, String content) {
    _notes.insert(
      0,
      Note(
        id: _nextId++,
        title: title,
        content: content,
        updatedAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void updateNote(Note note, String newTitle, String newContent) {
    final index = _notes.indexWhere((element) => element.id == note.id);
    if (index != -1) {
      _notes[index] = note.copyWith(
        title: newTitle,
        content: newContent,
        updatedAt: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void deleteNote(Note note) {
    _notes.removeWhere((n) => n.id == note.id);
    notifyListeners();
  }

  Note? getById(int id) {
    try {
      return _notes.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }
}

// --- Screens and widgets ---

/// The main notes list screen with search and FAB for new note.
class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  State<NotesListScreen> createState() => _NotesListScreenState();
}

class _NotesListScreenState extends State<NotesListScreen> {
  final NotesRepository repo = NotesRepository();
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    // Add some sample notes initially for testing/demo
    repo.addNote('Welcome', 'Tap the "+" button to add a new note.');
    repo.addNote('Minimal', 'This is a minimal notes app with CRUD and search.');
    repo.addListener(_refresh);
  }

  @override
  void dispose() {
    repo.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  void _navigateToNoteDetail({Note? note}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NoteDetailScreen(
          repository: repo,
          note: note,
        ),
      ),
    );
    setState(() {});
  }

  void _deleteNote(Note note) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete note?'),
        content: const Text('Are you sure you want to delete this note? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              repo.deleteNote(note);
              Navigator.pop(context);
            },
            child: const Text('Delete'), // emphasize destructive
          ),
        ],
      ),
    );
  }

  Widget _buildNoteTile(Note note) {
    return Card(
      elevation: 0.4,
      shadowColor: Colors.grey.shade100,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          note.title.isNotEmpty ? note.title : "(Untitled)",
          style: const TextStyle(fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: note.content.isNotEmpty
            ? Text(
                note.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              )
            : null,
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _navigateToNoteDetail(note: note);
            } else if (value == 'delete') {
              _deleteNote(note);
            }
          },
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NoteViewScreen(note: note),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notes = repo.getNotes(query: searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        centerTitle: true,
        elevation: 0.5,
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 14, 8, 6),
            child: SizedBox(
              height: 40,
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.black45),
                  hintText: 'Search notes',
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide.none,
                  ),
                ),
                style: const TextStyle(fontSize: 16),
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
              ),
            ),
          ),
          if (notes.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  searchQuery.trim().isEmpty
                      ? "No notes yet.\nTap + to add a new note."
                      : "No notes found.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black38,
                  ),
                ),
              ),
            ),
          if (notes.isNotEmpty)
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: notes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 2),
                itemBuilder: (context, idx) => _buildNoteTile(notes[idx]),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNoteDetail(),
        tooltip: "Add new note",
        child: const Icon(Icons.add, size: 26),
      ),
    );
  }
}

/// The screen for viewing a note in detail (read-only).
class NoteViewScreen extends StatelessWidget {
  final Note note;
  const NoteViewScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    Color bg = Colors.grey.shade50;
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Note'),
        elevation: 0.5,
      ),
      body: Container(
        color: bg,
        width: double.infinity,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            Text(
              note.title.isNotEmpty ? note.title : "(Untitled)",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                letterSpacing: -.7,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              "Last updated: ${_formatDate(note.updatedAt)}",
              style: const TextStyle(fontSize: 12.5, color: Colors.black38),
            ),
            const Divider(height: 24, thickness: 1.2),
            Text(
              note.content,
              style: const TextStyle(fontSize: 16.3, color: Colors.black87, height: 1.42),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Pop, then go back to detail in edit mode (simulate FAB for edit)
          Navigator.pop(context);
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => NoteDetailScreen(repository: null, note: note),
          ));
        },
        tooltip: 'Edit note',
        child: const Icon(Icons.edit),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    final hour = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return "Today, $hour:$min";
  }
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}

/// The screen for creating or editing a note.
/// If [note] is null, creates a new note. If a note is passed, allows editing.
class NoteDetailScreen extends StatefulWidget {
  final NotesRepository? repository;
  final Note? note;
  const NoteDetailScreen({super.key, required this.repository, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  bool _isEditing = false;
  bool _contentChanged = false;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.note != null;
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _titleController.addListener(_onChanged);
    _contentController.addListener(_onChanged);
  }

  void _onChanged() {
    setState(() {
      _contentChanged = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_contentChanged && _isEditing) {
      Navigator.pop(context);
      return;
    }
    if (widget.repository == null && widget.note != null) {
      // Special fallback: popping from view screen and re-entering detail
      Navigator.pop(context);
      return;
    }
    if (_formKey.currentState!.validate()) {
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();
      if (_isEditing) {
        widget.repository!.updateNote(widget.note!, title, content);
      } else {
        widget.repository!.addNote(title, content);
      }
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _isEditing;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Note' : "New Note"),
        actions: [
          if (!isEdit)
            IconButton(
              tooltip: "Save",
              onPressed: _save,
              icon: const Icon(Icons.check_rounded),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Container(
          color: Colors.grey.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                decoration: const InputDecoration(
                  hintText: "Title",
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty && (_contentController.text.trim().isEmpty)) {
                    return 'Enter title or content';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Expanded(
                child: TextFormField(
                  controller: _contentController,
                  minLines: 10,
                  maxLines: null,
                  expands: true,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: "Content",
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.36),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: isEdit
          ? FloatingActionButton(
              tooltip: "Save",
              onPressed: _save,
              child: const Icon(Icons.check_rounded),
            )
          : null,
    );
  }
}
