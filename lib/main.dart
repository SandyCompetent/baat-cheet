import 'package:chatbud/firebase_options.dart';
import 'package:chatbud/project_meta_data.dart';
import 'package:chatbud/src/core/app_state.dart';
import 'package:chatbud/src/core/app_logger.dart';
import 'package:chatbud/src/core/service_locator.dart';
import 'package:chatbud/src/screen/contact_page.dart';
import 'package:chatbud/src/screen/conversation_screen.dart';
import 'package:chatbud/src/screen/memory_page.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/src/screen/persona_hub_screen.dart';
import 'package:chatbud/src/services/gemini_service.dart';
import 'package:chatbud/src/core/constants.dart';
import 'package:chatbud/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'route_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    // Route AppLogger warnings/errors to Crashlytics once Firebase is up.
    // Guarded: Crashlytics is unsupported on web and absent in test/offline
    // environments, so failures here must never block app startup.
    if (!kIsWeb) {
      final crashlytics = FirebaseCrashlytics.instance;
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);
      AppLogger.errorReporter =
          (message, error, stackTrace, {bool fatal = false}) {
        crashlytics.recordError(
          error ?? message,
          stackTrace,
          reason: message,
          fatal: fatal,
        );
      };
      FlutterError.onError = crashlytics.recordFlutterFatalError;
    }
  } catch (e) {
    // Graceful fallback for environments where Firebase options are mocked or offline
    AppLogger.w('Firebase/Crashlytics initialization skipped', error: e);
  }

  // Register the service composition root before building the app.
  setupLocator();

  try {
    await AppState.instance.initialize().timeout(const Duration(seconds: 3));
  } catch (e) {
    AppLogger.w('AppState initialization timed out; continuing startup',
        error: e);
  }

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
          onGenerateRoute: RouteGenerator.generateRoute,
          home: const MyHomePage(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

const double kDesktopBreakpoint = 840.0;

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 1;

  final List<Widget> _children = [
    const MessagePage(),
    const PersonaHubScreen(),
    const MemoryPage(),
    const ContactPage(),
  ];

  void _onTappedBar(int index) {
    setState(() {
      _currentIndex = index;
    });
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
                child: Icon(Icons.smart_toy_rounded,
                    color: context.accent, size: 22),
              ),
              title: const Text('ChatBud AI Assistant'),
              subtitle: const Text('Instant answers, research & assistance'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ConversationScreen(
                      conversationId: AppConstants.aiAssistantId,
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
                child:
                    Icon(Icons.hub_outlined, color: context.accent, size: 22),
              ),
              title: const Text('Browse AI Personas'),
              subtitle:
                  const Text('Explore engineering, security & creative minds'),
              onTap: () {
                Navigator.pop(ctx);
                setState(() => _currentIndex = 1);
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= kDesktopBreakpoint;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: context.bgCanvas,
        body: Row(
          children: [
            _DesktopSidebar(
              currentIndex: _currentIndex,
              onSelectTab: _onTappedBar,
              onNewChat: _onFabPressed,
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: context.borderSubtle,
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _children,
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _children,
      ),
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
        child: SafeArea(
          top: false,
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
                icon: Icons.smart_toy_outlined,
                label: 'Persona',
                index: 1,
                current: _currentIndex,
                onTap: _onTappedBar,
              ),
              const SizedBox(width: 48), // notch gap for FAB
              _NavItem(
                icon: Icons.psychology_outlined,
                label: 'Memory',
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
      ),
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onSelectTab;
  final VoidCallback onNewChat;

  const _DesktopSidebar({
    required this.currentIndex,
    required this.onSelectTab,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: context.bgSurface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Header
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: context.accentSubtle,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: context.accent.withValues(alpha: 0.25),
                  ),
                ),
                padding: const EdgeInsets.all(4),
                child: Image.asset(appLogo, fit: BoxFit.contain),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ChatBud',
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'AI Workspace · Multi-Agent',
                    style: TextStyle(
                      color: context.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Primary New Chat Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: onNewChat,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text(
                'New Chat',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 14),

          // Nav Items
          _DesktopSidebarItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chats',
            index: 0,
            currentIndex: currentIndex,
            onTap: () => onSelectTab(0),
          ),
          const SizedBox(height: 6),
          _DesktopSidebarItem(
            icon: Icons.smart_toy_outlined,
            activeIcon: Icons.smart_toy_rounded,
            label: 'Persona Hub',
            index: 1,
            currentIndex: currentIndex,
            onTap: () => onSelectTab(1),
          ),
          const SizedBox(height: 6),
          _DesktopSidebarItem(
            icon: Icons.psychology_outlined,
            activeIcon: Icons.psychology_rounded,
            label: 'Memory Vault',
            index: 2,
            currentIndex: currentIndex,
            onTap: () => onSelectTab(2),
          ),
          const SizedBox(height: 6),
          _DesktopSidebarItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profile & Settings',
            index: 3,
            currentIndex: currentIndex,
            onTap: () => onSelectTab(3),
          ),

          const Spacer(),

          // Footer info & quick toggles
          Divider(height: 1, color: context.borderSubtle),
          const SizedBox(height: 12),

          // Model Pill
          ListenableBuilder(
            listenable: GeminiService.instance,
            builder: (context, _) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: context.bgElevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: context.accent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        GeminiService.instance.currentModel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.textPrimary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 8),

          // Theme switcher & connection status
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: context.statusOnline,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Ready',
                style: TextStyle(
                  color: context.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Tooltip(
                message: 'Toggle Theme',
                child: IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    context.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 18,
                    color: context.textSecondary,
                  ),
                  onPressed: () {
                    final next = context.isDark ? ThemeMode.light : ThemeMode.dark;
                    AppState.instance.setThemeMode(next);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DesktopSidebarItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final VoidCallback onTap;

  const _DesktopSidebarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = index == currentIndex;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? context.accentSubtle : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 19,
              color: isSelected ? context.accent : context.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? context.accent : context.textPrimary,
                ),
              ),
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
