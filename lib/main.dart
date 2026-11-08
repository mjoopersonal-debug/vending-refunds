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
const darkPlum = Color(0xFF5A0F2E);
const greyPlum = Color(0xFF7C5F6B);

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
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shadowColor: pink.withOpacity(0.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: pink,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// ---------- Sign-in screen ----------

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

  InputDecoration _decoration(String label) => InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: brightPink)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: brightPink)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: pink, width: 2)),
      );

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
            child: Column(
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: pink.withOpacity(0.25), blurRadius: 18)],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.icecream, size: 100, color: pink),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Owner sign-in', style: TextStyle(color: darkPlum, fontSize: 18)),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: _decoration('Email')),
                      const SizedBox(height: 14),
                      TextField(controller: _password, obscureText: true, decoration: _decoration('Password')),
                      const SizedBox(height: 10),
                      if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: FilledButton(
                          onPressed: _busy ? null : _signIn,
                          child: Text(_busy ? 'Signing in...' : 'Sign in  →',
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Sweet Service. Always!', style: TextStyle(color: pink, fontStyle: FontStyle.italic)),
                const SizedBox(height: 16),
                Image.asset('assets/cone.png', height: 220, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
                Image.asset('assets/wave.png', width: double.infinity, height: 110, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- Home screen ----------

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
    await AppAlarm.schedule(
      key: 'new-request-${DateTime.now().millisecondsSinceEpoch}',
      when: DateTime.now().add(const Duration(seconds: 3)),
      title: 'New refund request',
      body: 'A customer has requested a refund.',
    );
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

  void _signOut() => FirebaseAuth.instance.signOut();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Header(onSignOut: _signOut),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(child: _statCard('Pending', _pendingCount.toString(), pink, Colors.white)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('refunds')
                          .where('status', isEqualTo: 'Done')
                          .snapshots(),
                      builder: (context, snap) {
                        final doneCount = snap.hasData ? snap.data!.size.toString() : '0';
                        return _statCard('Done', doneCount, Colors.green, const Color(0xFFF1FBF2));
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
            child: Column(
              children: [
                _menuTile('Pending\nRefunds', Icons.access_time, pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Pending')))),
                _menuTile('Done\nRefunds', Icons.check_circle, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Done')))),
                _menuTile('Settings', Icons.settings, greyPlum, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Image.asset('assets/cone.png', height: 200, errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color numberColor, Color background) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: pink.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: pink, fontSize: 15)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: numberColor, fontSize: 28, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _menuTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        elevation: 2,
        shadowColor: pink.withOpacity(0.2),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                CircleAvatar(radius: 24, backgroundColor: color, child: Icon(icon, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(label, style: const TextStyle(color: darkPlum, fontSize: 17, fontWeight: FontWeight.bold)),
                ),
                const Icon(Icons.chevron_right, color: pink, size: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSignOut;
  const _Header({required this.onSignOut});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [brightPink, pink],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 14,
              top: 8,
              child: Material(
                color: Colors.white24,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSignOut,
                  child: const Padding(
                    padding: EdgeInsets.all(10),
                    child: Icon(Icons.logout, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 20,
              top: 78,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello!', style: TextStyle(color: Colors.white70, fontSize: 15)),
                  Text('Welcome Back', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Positioned(
              right: 6,
              top: 40,
              child: Image.asset(
                'assets/icon.png',
                height: 150,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
