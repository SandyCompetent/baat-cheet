import 'package:chatbud/firebase_options.dart';
import 'package:chatbud/src/screen/contact_page.dart';
import 'package:chatbud/src/screen/group_page.dart';
import 'package:chatbud/src/screen/list_page.dart';
import 'package:chatbud/src/screen/message_page.dart';
import 'package:chatbud/theme_data.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'route_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const EntryPoint());
}

class EntryPoint extends StatelessWidget {
  const EntryPoint({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChatBud',
      theme: lightTheme,
      darkTheme: darkTheme,
      initialRoute: splashRoute,
      onGenerateRoute: RouteGenerator.generateRoute,
      home: const MyHomePage(),
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

  // Track user login status (default is Guest Mode)
  final bool _isLoggedIn = false;

  final List<Widget> _children = [
    const MessagePage(),
    const GroupPage(),
    const ListPage(),
    const ContactPage()
  ];

  void _onTappedBar(int index) {
    if (index == 0) {
      // AI Chat & Message Dashboard is open to guests
      setState(() {
        _currentIndex = index;
      });
    } else {
      // Social features require login
      final String featureName = index == 1
          ? 'Group Chats'
          : index == 2
              ? 'Saved Lists'
              : 'Contacts & Friends';
      _checkLoginAndProceed(() {
        setState(() {
          _currentIndex = index;
        });
      }, featureName);
    }
  }

  void _checkLoginAndProceed(VoidCallback onAuthorized, String featureName) {
    if (_isLoggedIn) {
      onAuthorized();
    } else {
      _showLoginRequiredDialog(featureName);
    }
  }

  void _showLoginRequiredDialog(String featureName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.lock_outline, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('Login Required'),
          ],
        ),
        content: Text(
          'You are currently in Guest Mode. Please sign in to access $featureName, add friends, and sync your chats.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue as Guest'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(loginRoute);
            },
            child: const Text(
              'Sign In / Register',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _children[_currentIndex],
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _checkLoginAndProceed(() {
            // Authorized action for adding friends
          }, 'Add Friends & Groups');
        },
        backgroundColor: Colors.redAccent,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onTappedBar,
        currentIndex: _currentIndex,
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.message),
            label: "AI Chat",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: "Group",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: "List",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.contacts),
            label: "Contacts",
          ),
        ],
      ),
    );
  }
}
