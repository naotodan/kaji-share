import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chore_store.dart';
import 'home_view.dart';
import 'chore_list_view.dart';
import 'settings_view.dart';

class MainTabView extends StatefulWidget {
  const MainTabView({super.key});

  @override
  State<MainTabView> createState() => _MainTabViewState();
}

class _MainTabViewState extends State<MainTabView> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChoreStore(),
      child: Scaffold(
        body: IndexedStack(
          index: _index,
          children: const [HomeView(), ChoreListView(), SettingsView()],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'ホーム'),
            NavigationDestination(
                icon: Icon(Icons.check_circle_outline),
                selectedIcon: Icon(Icons.check_circle),
                label: '家事一覧'),
            NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: '設定'),
          ],
        ),
      ),
    );
  }
}
