import 'package:chatbud/firebase_options.dart';
import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/screen/contact_page.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/group_page.dart';
import 'package:chatbud/src/screen/list_page.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'route_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Graceful fallback for environments where Firebase options are mocked or offline
  }

  await AppState.instance.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const EntryPoint());
}

class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'ChatBud',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: AppState.instance.themeMode,
          initialRoute: splashRoute,
          onGenerateRoute: RouteGenerator.generateRoute,
          home: const MyHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;

  final List<Widget> _children = [
    const MessagePage(),
    const GroupPage(),
    const ListPage(),
    const ContactPage(),
  ];

  void _onTappedBar(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _checkLoginAndProceed(VoidCallback onAuthorized, String featureName) {
    if (AppState.instance.isLoggedIn) {
      onAuthorized();
    } else {
      _showLoginRequiredDialog(featureName);
    }
  }

  void _showLoginRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock_outline, color: context.statusDanger, size: 22),
            const SizedBox(width: 8),
            const Text('Sign In Required'),
          ],
        ),
        content: Text(
          'You are currently in Guest Mode. Please sign in to access $featureName and sync your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue as Guest'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(loginRoute);
            },
            child: const Text('Sign In / Register'),
          ),
        ],
      ),
    );
  }

  void _onFabPressed() {
    _showNewChatModal();
  }

  void _showNewChatModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start a Conversation',
              style: TextStyle(
                color: context.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.smart_toy_rounded, color: context.accent, size: 22),
              ),
              title: const Text('ChatBud AI Assistant'),
              subtitle: const Text('Instant answers, research & assistance'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConversationScreen(
                      conversationId: 'ai_assistant',
                      title: 'ChatBud AI Assistant',
                      isAi: true,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.group_add_outlined, color: context.accent, size: 22),
              ),
              title: const Text('New Group Channel'),
              subtitle: const Text('Collaborate with friends or teammates'),
              onTap: () {
                Navigator.pop(ctx);
                _checkLoginAndProceed(() {
                  setState(() => _currentIndex = 1);
                }, 'Group Channels');
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: _children[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: _onFabPressed,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 4,
        child: const Icon(Icons.edit_outlined),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: context.bgSurface,
        elevation: 0,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        padding: EdgeInsets.zero,
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.chat_bubble_outline_rounded,
              label: 'Chats',
              index: 0,
              current: _currentIndex,
              onTap: _onTappedBar,
            ),
            _NavItem(
              icon: Icons.group_outlined,
              label: 'Groups',
              index: 1,
              current: _currentIndex,
              onTap: _onTappedBar,
            ),
            const SizedBox(width: 48), // notch gap for FAB
            _NavItem(
              icon: Icons.bookmark_border_rounded,
              label: 'Saved',
              index: 2,
              current: _currentIndex,
              onTap: _onTappedBar,
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              index: 3,
              current: _currentIndex,
              onTap: _onTappedBar,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == current;
    final color = isSelected ? context.accent : context.textMuted;

    return Expanded(
      child: InkWell(
        onTap: () => onTap(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 18 : 0,
                height: 3,
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  color: isSelected ? context.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
