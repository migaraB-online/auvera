import 'package:flutter/foundation.dart';

/// Holds the books a member has picked before booking.
class Cart extends ChangeNotifier {
  Cart._();
  static final Cart instance = Cart._();

  static const maxBooks = 5;
  final Map<String, Map<String, dynamic>> _items = {};

  List<Map<String, dynamic>> get items => _items.values.toList();
  int get count => _items.length;
  bool contains(String id) => _items.containsKey(id);
  bool get isFull => _items.length >= maxBooks;

  void add(Map<String, dynamic> book) {
    if (isFull) return;
    _items[book['id'] as String] = book;
    notifyListeners();
  }

  void remove(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
