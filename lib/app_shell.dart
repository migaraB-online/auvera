import 'package:material_ui/material_ui.dart';

import 'books_screen.dart';
import 'home_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [BooksScreen(), HomeScreen()];
    return Scaffold(
      body: pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            label: 'Books',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            label: 'My Card',
          ),
        ],
      ),
    );
  }
}
