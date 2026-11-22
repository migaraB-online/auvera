import 'package:material_ui/material_ui.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'cart.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _book() async {
    final cart = Cart.instance;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await Supabase.instance.client.rpc(
        'book_books',
        params: {'p_book_ids': cart.items.map((b) => b['id']).toList()},
      );
      cart.clear();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Booked!'),
          content: const Text(
            'Your books are reserved. Please collect them from the library.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } on PostgrestException catch (e) {
      // Messages come from the book_books() function (limit, availability).
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: ListenableBuilder(
        listenable: Cart.instance,
        builder: (context, _) {
          final items = Cart.instance.items;
          if (items.isEmpty) {
            return const Center(child: Text('Your cart is empty'));
          }
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final b = items[i];
                    return Card(
                      color: Colors.white,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(
                          '${b['title']}',
                          style: theme.textTheme.titleLarge,
                        ),
                        subtitle: Text('${b['author']}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () =>
                              Cart.instance.remove(b['id'] as String),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${items.length} of ${Cart.maxBooks} books',
                      textAlign: TextAlign.center,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _book,
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Book now'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
