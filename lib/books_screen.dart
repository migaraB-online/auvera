import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BooksScreen extends StatefulWidget {
  const BooksScreen({super.key});

  @override
  State<BooksScreen> createState() => _BooksScreenState();
}

class _BooksScreenState extends State<BooksScreen> {
  final _search = TextEditingController();
  String _language = 'all';

  // Live stream: when a book's status changes, every screen updates.
  late final Stream<List<Map<String, dynamic>>> _books = Supabase
      .instance
      .client
      .from('books')
      .stream(primaryKey: ['id'])
      .order('title');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF2E7D32);
      case 'booked':
        return const Color(0xFFC9A24B);
      default:
        return const Color(0xFF8E8E93);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'booked':
        return 'Booked';
      default:
        return 'Borrowed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AUVERA')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search by title or author',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final entry in const {
                  'all': 'All',
                  'si': 'සිංහල',
                  'en': 'English',
                }.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: _language == entry.key,
                      onSelected: (_) => setState(() => _language = entry.key),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _books,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Text('Could not load books:\n${snap.error}'),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final q = _search.text.trim().toLowerCase();
                final books = snap.data!.where((b) {
                  final matchesText =
                      q.isEmpty ||
                      '${b['title']}'.toLowerCase().contains(q) ||
                      '${b['author']}'.toLowerCase().contains(q);
                  final matchesLang =
                      _language == 'all' || b['language'] == _language;
                  return matchesText && matchesLang;
                }).toList();

                if (books.isEmpty) {
                  return const Center(child: Text('No books found'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final b = books[i];
                    final status = '${b['status']}';
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        title: Text(
                          '${b['title']}',
                          style: theme.textTheme.titleLarge,
                        ),
                        subtitle: Text(
                          '${b['author']}  •  ${b['category'] ?? ''}',
                        ),
                        trailing: Chip(
                          label: Text(
                            _statusLabel(status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          backgroundColor: _statusColor(status),
                          side: BorderSide.none,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
