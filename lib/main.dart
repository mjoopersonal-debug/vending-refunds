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
  await Firebase.initializeApp();
  await AppAlarm.init();
  runApp(const SofiesApp());
}

class SofiesApp extends StatelessWidget {
  const SofiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SOFTIES Vending Refunds',
      navigatorKey: navKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: pink, primary: pink),
        scaffoldBackgroundColor: offWhite,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(backgroundColor: pink, foregroundColor: Colors.white),
      ),
      home: const AuthGate(),
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
    } on FirebaseAuthException {
      setState(() => _error = 'Sign-in failed. Check email and password.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('icon.png', height: 160, errorBuilder: (_, __, ___) => const Icon(Icons.icecream, size: 120, color: pink)),
                const SizedBox(height: 8),
                const Text('SOFTIES', style: TextStyle(color: pink, fontSize: 30, fontWeight: FontWeight.bold)),
                const Text('Owner sign-in'),
                const SizedBox(height: 24),
                TextField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                TextField(controller: _password, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
                const SizedBox(height: 12),
                if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: Padding(padding: const EdgeInsets.all(14), child: Text(_busy ? 'Signing in...' : 'Sign in  →')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
          const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: pink)),
          const SizedBox(height: 16),
          _menuTile(context, 'Pending Refunds', Icons.access_time, pink, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Pending')))),
          _menuTile(context, 'Done Refunds', Icons.check_circle, Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RefundListScreen(status: 'Done')))),
          _menuTile(context, 'Settings', Icons.settings, Colors.blueGrey, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        ],
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
