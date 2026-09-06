import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../viewmodels/auth_view_model.dart';
import '../viewmodels/flash_view_model.dart';
import '../viewmodels/friend_view_model.dart';
import '../viewmodels/home_view_model.dart';
import 'flash_compose_view.dart';
import 'friends_view.dart';
import 'home_view.dart';
import 'received_flashes_view.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // 첫 진입 시 각 화면 데이터 로드.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeViewModel>().load();
      context.read<FriendViewModel>().load();
      context.read<FlashViewModel>().loadReceived();
    });
  }

  static const _titles = ['지금 한가한 친구', '받은 번개', '친구'];

  @override
  Widget build(BuildContext context) {
    final unseen = context.select<FlashViewModel, int>((f) => f.unseen);

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_index]),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: () => context.read<AuthViewModel>().logout(),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [
          HomeView(),
          ReceivedFlashesView(),
          FriendsView(),
        ],
      ),
      floatingActionButton: _index == 2
          ? null
          : FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FlashComposeView()),
              ),
              icon: const Text('⚡', style: TextStyle(fontSize: 18)),
              label: const Text('번개 보내기'),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() => _index = i);
          if (i == 1) context.read<FlashViewModel>().clearUnseen();
        },
        destinations: [
          const NavigationDestination(
              icon: Icon(Icons.people_alt_outlined),
              selectedIcon: Icon(Icons.people_alt),
              label: '홈'),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: unseen > 0,
              label: Text('$unseen'),
              child: const Icon(Icons.bolt_outlined),
            ),
            selectedIcon: const Icon(Icons.bolt),
            label: '번개',
          ),
          const NavigationDestination(
              icon: Icon(Icons.group_outlined),
              selectedIcon: Icon(Icons.group),
              label: '친구'),
        ],
      ),
    );
  }
}
