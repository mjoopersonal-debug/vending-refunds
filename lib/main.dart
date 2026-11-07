import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'app_alarm.dart';
import 'refund_screens.dart';
import 'settings_screen.dart';

const pink = Color(0xFFD81860);
const brightPink = Color(0xFFFF4081);
const lightPink = Color(0xFFFFC1D9);
const offWhite = Color(0xFFFFF0F5);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startError;
  try {
    await Firebase.initializeApp();
  } catch (e) {
    startError = 'Firebase start failed:\n$e';
  }
  try {
    await AppAlarm.init();
  } catch (e) {
    startError = (startError ?? '') + '\n\nAlarm start failed:\n$e';
  }
  runApp(SofiesApp(startError: startError));
}

class SofiesApp extends StatelessWidget {
  final String? startError;
  const SofiesApp({super.key, this.startError});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOFTIES Vending Refunds',
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: pink, primary: pink, surface: offWhite),
        scaffoldBackgroundColor: offWhite,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: pink, foregroundColor: Colors.white, centerTitle: false),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 2,
          shadowColor: pink.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: startError != null ? ErrorScreen(message: startError!) : const AuthGate(),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup problem')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: SelectableText(message, style: const TextStyle(fontSize: 15)),
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorScreen(message: 'Auth error:\n${snap.error}');
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData) return const HomeScreen();
        return const SignInScreen();
      },
    );
  }
}

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() { _busy = true; _error = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
    } catch (e) {
      setState(() => _error = 'Sign-in failed. Check email and password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, lightPink],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/icon.png', height: 170, errorBuilder: (_, __, ___) => const Icon(Icons.icecream, size: 120, color: pink)),
                const SizedBox(height: 8),
                const Text('SOFTIES', style: TextStyle(color: pink, fontSize: 30, fontWeight: FontWeight.bold)),
                const Text('Owner sign-in', style: TextStyle(color: Color(0xFF5A0F2E))),
                const SizedBox(height: 24),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: brightPink)))),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: InputDecoration(labelText: 'Password', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: brightPink)))),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: Padding(padding: const EdgeInsets.all(14), child: Text(_busy ? 'Signing in...' : 'Sign in  →', style: const TextStyle(fontSize: 17))),
                  ),
                ),
                const SizedBox(height: 24),
                Image.asset('assets/cone.png', height: 150, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<QuerySnapshot>? _sub;
  bool _firstLoad = true;
  int _pendingCount = 0;

  @override
  void initState() {
    super.initState();
    // Live listener: every new Pending refund rings the alarm and shows a notice
    _sub = FirebaseFirestore.instance
        .collection('refunds')
        .where('status', isEqualTo: 'Pending')
        .snapshots()
        .listen((snap) {
      final count = snap.size;
      if (!_firstLoad && count > _pendingCount) {
        _alertNewRequest();
      }
      _firstLoad = false;
      _pendingCount = count;
      if (mounted) setState(() {});
    });
  }

  Future<void> _alertNewRequest() async {
    await AppAlarm.test();
    final ctx = navKey.currentContext;
    if (ctx != null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('New refund request received!'), duration: Duration(seconds: 6)),
      );
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SOFTIES'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Image.asset('assets/wave.png', height: 90, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: pink)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _countCard('Pending', _pendingCount.toString(), pink)),
          ]),
          const SizedBox(height: 16),
          _menuTile(context, 'Pending Refunds', Icons.access_time, pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Pending')))),
          _menuTile(context, 'Done Refunds', Icons.check_circle, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Done')))),
          _menuTile(context, 'Settings', Icons.settings, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
          const SizedBox(height: 16),
          Center(child: Image.asset('assets/cone.png', height: 110, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        ],
      ),
    );
  }

  Widget _countCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Text(label, style: TextStyle(color: color, fontSize: 15)),
          Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        ]),
      ),
    );
  }

  Widget _menuTile(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.chevron_right, color: pink),
        onTap: onTap,
      ),
    );
  }
}
