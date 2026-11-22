import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart.dart';
import 'cart_screen.dart';

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
      .stream(primaryKey: ['id']);

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

  void _addToCart(Map<String, dynamic> book) {
    if (Cart.instance.isFull) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can book up to 5 books at a time.')),
      );
      return;
    }
    Cart.instance.add(book);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('AUVERA'),
        actions: [
          ListenableBuilder(
            listenable: Cart.instance,
            builder: (context, _) => IconButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const CartScreen()),
              ),
              icon: Badge(
                isLabelVisible: Cart.instance.count > 0,
                label: Text('${Cart.instance.count}'),
                child: const Icon(Icons.shopping_bag_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
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
                final books =
                    snap.data!.where((b) {
                      final matchesText =
                          q.isEmpty ||
                          '${b['title']}'.toLowerCase().contains(q) ||
                          '${b['author']}'.toLowerCase().contains(q);
                      final matchesLang =
                          _language == 'all' || b['language'] == _language;
                      return matchesText && matchesLang;
                    }).toList()..sort(
                      (a, b) => '${a['title']}'.toLowerCase().compareTo(
                        '${b['title']}'.toLowerCase(),
                      ),
                    );

                if (books.isEmpty) {
                  return const Center(child: Text('No books found'));
                }

                return ListenableBuilder(
                  listenable: Cart.instance,
                  builder: (context, _) => ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: books.length,
                    itemBuilder: (context, i) {
                      final b = books[i];
                      final status = '${b['status']}';
                      final inCart = Cart.instance.contains(b['id'] as String);
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
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
                              const SizedBox(width: 8),
                              if (status == 'available')
                                IconButton(
                                  tooltip: inCart
                                      ? 'Remove from cart'
                                      : 'Add to cart',
                                  icon: Icon(
                                    inCart
                                        ? Icons.remove_circle_outline
                                        : Icons.add_circle_outline,
                                  ),
                                  onPressed: () => inCart
                                      ? Cart.instance.remove(b['id'] as String)
                                      : _addToCart(b),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
