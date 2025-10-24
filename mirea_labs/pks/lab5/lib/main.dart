import 'package:flutter/material.dart';
import 'edit_note_page.dart';
import 'models/note.dart';

void main() => runApp(const SimpleNotesApp());

class SimpleNotesApp extends StatelessWidget {
  const SimpleNotesApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notely',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFF171821),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF202231),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF2A9D8F),
          foregroundColor: Colors.white,
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF2F3041),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),

        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const NotesPage(),
    );
  }
}

enum SortMode { updatedDesc, createdDesc, titleAsc }

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  final List<Note> _notes = [
    Note(id: '1', title: 'Пример', body: 'Это пример заметки. Нажмите на меня, чтобы отредактировать.', isPinned: true),
  ];

  String _searchQuery = '';
  bool _isSearching = false;
  bool _grid = true;
  SortMode _sort = SortMode.updatedDesc;
  final TextEditingController _searchController = TextEditingController();

  List<Note> get _visibleNotes {
    final q = _searchQuery.trim().toLowerCase();
    List<Note> filtered = _notes.where((n) {
      if (q.isEmpty) return true;
      return n.title.toLowerCase().contains(q) || n.body.toLowerCase().contains(q);
    }).toList();

    // sort
    int cmp(Note a, Note b) {
      switch (_sort) {
        case SortMode.updatedDesc:
          return b.updatedAt.compareTo(a.updatedAt);
        case SortMode.createdDesc:
          return b.createdAt.compareTo(a.createdAt);
        case SortMode.titleAsc:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      }
    }

    filtered.sort(cmp);

    // pinned first
    final pinned = filtered.where((n) => n.isPinned).toList();
    final regular = filtered.where((n) => !n.isPinned).toList();
    return [...pinned, ...regular];
  }

  Future<void> _addNote() async {
    final newNote = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => const EditNotePage()),
    );
    if (newNote != null && mounted) {
      setState(() => _notes.add(newNote));
    }
  }

  Future<void> _edit(Note note) async {
    final updated = await Navigator.push<Note>(
      context,
      MaterialPageRoute(builder: (_) => EditNotePage(existing: note)),
    );
    if (updated != null && mounted) {
      setState(() {
        final i = _notes.indexWhere((n) => n.id == updated.id);
        if (i != -1) {
          _notes[i] = updated.copyWith(updatedAt: DateTime.now());
        }
      });
    }
  }

  void _delete(Note note) {
    final index = _notes.indexOf(note);
    setState(() => _notes.removeAt(index));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Заметка удалена', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        action: SnackBarAction(
          label: 'Отменить',
          textColor: Colors.white,
          onPressed: () {
            if (mounted) {
              setState(() => _notes.insert(index, note));
            }
          },
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
      }
    });
  }

  void _onSearchChanged(String value) => setState(() => _searchQuery = value);

  PopupMenuButton _sortMenu() {
    return PopupMenuButton<SortMode>(
      icon: const Icon(Icons.sort),
      onSelected: (m) => setState(() => _sort = m),
      itemBuilder: (context) => [
        CheckedPopupMenuItem(
          value: SortMode.updatedDesc,
          checked: _sort == SortMode.updatedDesc,
          child: const Text('По дате изменения (новые сверху)'),
        ),
        CheckedPopupMenuItem(
          value: SortMode.createdDesc,
          checked: _sort == SortMode.createdDesc,
          child: const Text('По дате создания (новые сверху)'),
        ),
        CheckedPopupMenuItem(
          value: SortMode.titleAsc,
          checked: _sort == SortMode.titleAsc,
          child: const Text('По заголовку (A→Я)'),
        ),
      ],
    );
  }

  Widget _noteTile(Note n) {
    final meta = Text(
      'созд. ${_fmt(n.createdAt)}  •  изм. ${_fmt(n.updatedAt)}',
      style: const TextStyle(color: Colors.white60, fontSize: 12),
    );

    return Card(
      color: Color(n.color),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _edit(n),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      n.title.isEmpty ? '(без названия)' : n.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (n.isPinned) const Icon(Icons.push_pin, size: 18, color: Colors.white70),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                    onPressed: () => _delete(n),
                    tooltip: 'Удалить',
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                n.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
              const SizedBox(height: 10),
              meta,
            ],
          ),
        ),
      ),
    );
  }

  String _fmt(DateTime dt) {
    // simple local format: DD.MM HH:MM
    final two = (int v) => v < 10 ? '0$v' : '$v';
    return '${two(dt.day)}.${two(dt.month)}  ${two(dt.hour)}:${two(dt.minute)}';
    // (даты/локализацию можно расширить через intl, но без пакетов сохраняем просто)
  }

  @override
  Widget build(BuildContext context) {
    final notes = _visibleNotes;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Поиск в заголовке и тексте…',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                autofocus: true,
                onChanged: _onSearchChanged,
              )
            : const Text('Notely'),
        actions: [
          IconButton(
            tooltip: _grid ? 'Режим списка' : 'Режим плитки',
            icon: Icon(_grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
            onPressed: () => setState(() => _grid = !_grid),
          ),
          _sortMenu(),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        child: const Icon(Icons.add),
      ),
      body: notes.isEmpty
          ? const Center(
              child: Text(
                'Нет заметок. Нажмите +',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : _grid
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    itemCount: notes.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.78,
                    ),
                    itemBuilder: (_, i) => _noteTile(notes[i]),
                  ),
                )
              : ListView.builder(
                  itemCount: notes.length,
                  itemBuilder: (_, i) => _noteTile(notes[i]),
                ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
