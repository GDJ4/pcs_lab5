import 'package:flutter/material.dart';
import 'models/note.dart';

class EditNotePage extends StatefulWidget {
  final Note? existing;
  const EditNotePage({super.key, this.existing});

  @override
  State<EditNotePage> createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _bodyCtrl;
  late bool _isPinned;
  late int _color;

  static const _palette = <int>[
    0xFF2F3041, // dark card
    0xFF3D405B,
    0xFF264653,
    0xFF1D3557,
    0xFF6D597A,
    0xFF4A4E69,
    0xFF2A9D8F,
    0xFF8CBD8A,
  ];

  @override
  void initState() {
    super.initState();
    final n = widget.existing;
    _titleCtrl = TextEditingController(text: n?.title ?? '');
    _bodyCtrl = TextEditingController(text: n?.body ?? '');
    _isPinned = n?.isPinned ?? false;
    _color = n?.color ?? _palette.first;
  }

  void _save() {
    final base = widget.existing;
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();

    if ((title.isEmpty && body.isEmpty)) {
      Navigator.pop(context); // do not create empty note
      return;
    }

    if (base == null) {
      final note = Note(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        body: body,
        isPinned: _isPinned,
        color: _color,
      );
      Navigator.pop(context, note);
    } else {
      final updated = base.copyWith(
        title: title,
        body: body,
        isPinned: _isPinned,
        color: _color,
        updatedAt: DateTime.now(),
      );
      Navigator.pop(context, updated);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F1F2F),
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Новая заметка' : 'Редактирование'),
        actions: [
          IconButton(
            tooltip: _isPinned ? 'Открепить' : 'Закрепить',
            icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => _isPinned = !_isPinned),
          ),
          IconButton(
            tooltip: 'Сохранить',
            icon: const Icon(Icons.check),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _palette.map((c) {
              final selected = _color == c;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(c),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white24,
                      width: selected ? 2 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(
              hintText: 'Заголовок',
              hintStyle: TextStyle(color: Colors.white70),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Color(_color),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _bodyCtrl,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Текст заметки…',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }
}
