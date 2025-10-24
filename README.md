# Отчёт по практическому занятию №5
## Выполнил: Лазарев Г.С. 
## Группа: ЭФБО-10-23

## Цели ПЗ

* Освоить работу со списками/сетками (`ListView.builder`, `GridView.builder`).
* Реализовать полноценный CRUD для заметок + «закрепление» (pin).
* Добавить расширенный поиск (по заголовку и тексту) и сортировку.
* Научиться передавать/возвращать данные между экранами через `Navigator.push/pop`.
* Настроить тему приложения и индивидуальные цвета карточек.
* Разобраться с типичными багами сборки/верстки (migrate на `CardThemeData`, устранение overflow в гриде).

---

## Ход работы

1. **Создание проекта**
   `flutter create notely_yefremov`

2. **Модель `Note` (`lib/models/note.dart`)**
   Расширил модель: добавил `isPinned`, `color`, `createdAt`, `updatedAt`.

   ```dart
   class Note {
     final String id;
     String title;
     String body;
     bool isPinned;
     int color;            // храню как ARGB int
     DateTime createdAt;
     DateTime updatedAt;

     Note({
       required this.id,
       required this.title,
       required this.body,
       this.isPinned = false,
       this.color = 0xFF2F3041,
       DateTime? createdAt,
       DateTime? updatedAt,
     })  : createdAt = createdAt ?? DateTime.now(),
          updatedAt = updatedAt ?? DateTime.now();

     Note copyWith({
       String? title, String? body, bool? isPinned,
       int? color, DateTime? createdAt, DateTime? updatedAt,
     }) => Note(
       id: id,
       title: title ?? this.title,
       body: body ?? this.body,
       isPinned: isPinned ?? this.isPinned,
       color: color ?? this.color,
       createdAt: createdAt ?? this.createdAt,
       updatedAt: updatedAt ?? this.updatedAt,
     );
   }
   ```

3. **Экран списка (`lib/main.dart`)**

   * Переименовал приложение в **Notely**, обновил палитру.
   * Добавил **режимы отображения**: список ↔ плитка (переключатель в AppBar).
   * Реализовал **сортировку**: по дате изменения, по дате создания, по заголовку.
   * **Поиск** теперь идёт по заголовку **и** по телу заметки.
   * **Закреплённые** заметки всегда выводятся первыми.
   * Карточки показывают метаданные: «созд.» и «изм.» (локальное форматирование).
   * Тема: мигрировал `cardTheme` на **`CardThemeData`** (исправление ошибки сборки во Flutter).

   Ключевые фрагменты:

   ```dart
   // ThemeData: важно — CardThemeData (а не CardTheme)
   theme: ThemeData(
     useMaterial3: true,
     scaffoldBackgroundColor: const Color(0xFF171821),
     appBarTheme: const AppBarTheme(
       backgroundColor: Color(0xFF202231),
       titleTextStyle: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
       iconTheme: IconThemeData(color: Colors.white),
     ),
     floatingActionButtonTheme: const FloatingActionButtonThemeData(
       backgroundColor: Color(0xFF2A9D8F), foregroundColor: Colors.white,
     ),
     cardTheme: CardThemeData( // <- фикc несовместимости типов
       color: const Color(0xFF2F3041),
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
       elevation: 2,
       margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
     ),
     textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
   );
   ```

   ```dart
   // Поиск по заголовку и телу
   final q = _searchQuery.trim().toLowerCase();
   final filtered = _notes.where((n) =>
     q.isEmpty ||
     n.title.toLowerCase().contains(q) ||
     n.body.toLowerCase().contains(q)
   ).toList();
   ```

   ```dart
   // Сортировка + закреплённые вверх
   enum SortMode { updatedDesc, createdDesc, titleAsc }

   filtered.sort((a, b) {
     switch (_sort) {
       case SortMode.updatedDesc: return b.updatedAt.compareTo(a.updatedAt);
       case SortMode.createdDesc: return b.createdAt.compareTo(a.createdAt);
       case SortMode.titleAsc:    return a.title.toLowerCase().compareTo(b.title.toLowerCase());
     }
   });
   final visible = [
     ...filtered.where((n) => n.isPinned),
     ...filtered.where((n) => !n.isPinned),
   ];
   ```

   ```dart
   // Grid: резиновая высота + без overflow
   GridView.builder(
     itemCount: visible.length,
     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
       crossAxisCount: 2,
       crossAxisSpacing: 8,
       mainAxisSpacing: 8,
       childAspectRatio: 0.78, // вместо фиксированной высоты
     ),
     itemBuilder: (_, i) => _noteTile(visible[i]),
   );
   ```

   ```dart
   // Карточка заметки
   Card(
     color: Color(n.color),
     child: InkWell(
       onTap: () => _edit(n),
       borderRadius: BorderRadius.circular(14),
       child: Padding(
         padding: const EdgeInsets.all(14),
         child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Row(
               children: [
                 Expanded(child: Text(n.title.isEmpty ? '(без названия)' : n.title,
                   maxLines: 1, overflow: TextOverflow.ellipsis,
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
                 )),
                 if (n.isPinned) const Icon(Icons.push_pin, size: 18, color: Colors.white70),
                 IconButton(icon: const Icon(Icons.delete_outline, size: 20, color: Colors.white),
                   onPressed: () => _delete(n),
                 ),
               ],
             ),
             const SizedBox(height: 6),
             Text(n.body, maxLines: 3, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white)),
             const SizedBox(height: 8),
             Text('созд. ${_fmt(n.createdAt)} • изм. ${_fmt(n.updatedAt)}',
               style: const TextStyle(color: Colors.white60, fontSize: 11),
               maxLines: 1, overflow: TextOverflow.ellipsis,
             ),
           ],
         ),
       ),
     ),
   );
   ```

4. **Экран редактирования (`lib/edit_note_page.dart`)**

   * Кнопка «булавка» в AppBar — переключает `isPinned`.
   * Палитра пресет-цветов карточки (tap по свотчу).
   * Сохранение: создание новой заметки или обновление с изменением `updatedAt`.
   * Пустая заметка (и заголовок, и тело пустые) не создаётся.

   Фрагменты:

   ```dart
   static const _palette = <int>[0xFF2F3041,0xFF3D405B,0xFF264653,0xFF1D3557,0xFF6D597A,0xFF4A4E69,0xFF2A9D8F,0xFF8CBD8A];

   IconButton(
     tooltip: _isPinned ? 'Открепить' : 'Закрепить',
     icon: Icon(_isPinned ? Icons.push_pin : Icons.push_pin_outlined),
     onPressed: () => setState(() => _isPinned = !_isPinned),
   );

   // Контент: заголовок + тело, тело находится внутри цветного контейнера
   Container(
     decoration: BoxDecoration(color: Color(_color), borderRadius: BorderRadius.circular(12)),
     padding: const EdgeInsets.all(12),
     child: TextField(
       controller: _bodyCtrl,
       maxLines: null,
       style: const TextStyle(color: Colors.white),
       decoration: const InputDecoration(hintText: 'Текст заметки…', hintStyle: TextStyle(color: Colors.white70), border: InputBorder.none),
     ),
   );
   ```

5. **Удаление с Undo**
   Логика сохранена: `Dismissible` и кнопка на карточке, с `SnackBar` и «Отменить».

6. **Правки и отладка**

   * Исправил ошибку сборки iOS/Flutter: `cardTheme` → **`CardThemeData(...)`**.
   * Устранил «BOTTOM OVERFLOWED…» в гриде: отказ от фиксированной высоты (`mainAxisExtent`) в пользу `childAspectRatio` + ограничение `maxLines` у текста.

---

## Ключевые фрагменты (итог)

* **Поиск в `AppBar` (заголовок + тело):**

  ```dart
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
        onChanged: (v) => setState(() => _searchQuery = v),
      )
    : const Text('Notely'),
  ```

* **Режим списка/плитки и сортировка:**

  ```dart
  IconButton(
    tooltip: _grid ? 'Режим списка' : 'Режим плитки',
    icon: Icon(_grid ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
    onPressed: () => setState(() => _grid = !_grid),
  );

  PopupMenuButton<SortMode>(
    icon: const Icon(Icons.sort),
    onSelected: (m) => setState(() => _sort = m),
    itemBuilder: (_) => const [
      CheckedPopupMenuItem(value: SortMode.updatedDesc, child: Text('По дате изменения (новые сверху)')),
      CheckedPopupMenuItem(value: SortMode.createdDesc, child: Text('По дате создания (новые сверху)')),
      CheckedPopupMenuItem(value: SortMode.titleAsc,    child: Text('По заголовку (A→Я)')),
    ],
  );
  ```

* **Навигация и возврат результата:**

  ```dart
  final updated = await Navigator.push<Note>(
    context,
    MaterialPageRoute(builder: (_) => EditNotePage(existing: note)),
  );
  if (updated != null && mounted) {
    setState(() {
      final i = _notes.indexWhere((n) => n.id == updated.id);
      if (i != -1) _notes[i] = updated.copyWith(updatedAt: DateTime.now());
    });
  }
  ```

---



## Выводы

* **Что получилось:**
  Приложение заметок с добавлением/редактированием/удалением, **закреплением**, **индивидуальными цветами карточек**, **поиском по заголовку и тексту**, **сортировками** и **двумя режимами отображения** (список/плитка). Метаданные «создано/изменено» помогают визуально ориентироваться.

* **Что было сложным:**

  1. Миграция темы на `CardThemeData` (иначе iOS-сборка падала по типам).
  2. Борьба с переполнением в гриде: отказ от фиксированной высоты, настройка `childAspectRatio`, ограничение `maxLines`.
  3. Корректная стратегия сортировки с учётом закреплённых заметок.

## Скриншоты
<img width="370" height="804" alt="image" src="https://github.com/user-attachments/assets/9675b94b-cbe8-4c75-a7bb-f6d81c437134" />   <img width="400" height="851" alt="image" src="https://github.com/user-attachments/assets/750f9076-f8bc-4310-94b8-f09637410bfe" />

<img width="397" height="854" alt="image" src="https://github.com/user-attachments/assets/8cf815a7-6fff-4c72-8dfb-2e7afede2c24" />

