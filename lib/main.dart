import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const url = 'https://qscxdvikapcqwevcgbhd.supabase.co';
const key = 'sb_publishable_LFZQ0SS5nsqcJ_otNVRvVA_2i3p6EfE';

final db = Supabase.instance.client;
const green = Color(0xFF00FF88);
const dark = Color(0xFF080D0B);
const panel = Color(0xFF121B16);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: url, publishableKey: key);
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'NEXA MESSENGER',
    debugShowCheckedModeBanner: false,
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: dark,
      colorScheme: const ColorScheme.dark(
        primary: green,
        surface: panel,
      ),
      appBarTheme: const AppBarTheme(backgroundColor: dark),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) => StreamBuilder<AuthState>(
    stream: db.auth.onAuthStateChange,
    builder: (context, snapshot) {
      if (db.auth.currentUser == null) return const LoginPage();
      return const HomePage();
    },
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool register = false;
  bool busy = false;


  // NEXA_GOOGLE_LOGIN_FINAL
  Future<void> nexaGoogleLogin() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await db.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.nexa://login-callback/',
      );
    } catch (e) {
      if (mounted) show('خطا در ورود گوگل: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> submit() async {
    if (email.text.trim().isEmpty || password.text.length < 8) {
      show('ایمیل و رمز حداقل ۸ کاراکتری وارد کن.');
      return;
    }
    setState(() => busy = true);
    try {
      if (register) {
        final result = await db.auth.signUp(
          email: email.text.trim(),
          password: password.text,
        );
        if (result.session == null) {
          show('ثبت‌نام انجام شد؛ ایمیلت را برای تأیید بررسی کن.');
        }
      } else {
        await db.auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
    } catch (e) {
      show('خطا: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void show(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(26),
        child: Column(
          children: [
            const Icon(Icons.bolt, color: green, size: 78),
            const Text('NEXA',
              style: TextStyle(
                color: green, fontSize: 38,
                fontWeight: FontWeight.bold, letterSpacing: 7,
              )),
            const Text('MESSENGER'),
            const SizedBox(height: 40),
            // NEXA_GOOGLE_LOGIN_FINAL
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: busy ? null : nexaGoogleLogin,
                icon: const Text(
                  'G',
                  style: TextStyle(
                    color: Color(0xFF4285F4),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                label: const Text('ورود با حساب گوگل'),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'ایمیل',
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: password,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'رمز عبور (حداقل ۸ کاراکتر)',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: busy ? null : submit,
                child: Text(busy ? 'لطفاً صبر کن...' :
                  register ? 'ثبت‌نام' : 'ورود'),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => register = !register),
              child: Text(register
                ? 'قبلاً حساب داری؟ ورود'
                : 'حساب نداری؟ ثبت‌نام'),
            ),
            TextButton(
              onPressed: () async {
                if (email.text.trim().isEmpty) {
                  show('ابتدا ایمیل را وارد کن.');
                  return;
                }
                try {
                  await db.auth.resetPasswordForEmail(email.text.trim());
                  show('لینک بازیابی به ایمیلت ارسال شد.');
                } catch (e) { show('خطا: $e'); }
              },
              child: const Text('فراموشی رمز عبور'),
            ),
          ],
        ),
      ),
    ),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final title = TextEditingController();
  bool busy = false;

  Future<List<Map<String, dynamic>>> loadChats() async {
    final uid = db.auth.currentUser!.id;
    final memberships = await db.from('chat_members')
      .select('chat_id').eq('user_id', uid);
    final ids = memberships.map((e) => e['chat_id'].toString()).toList();
    if (ids.isEmpty) return [];
    final rows = await db.from('chats').select()
      .inFilter('id', ids).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> createChat() async {
    title.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گفتگوی جدید'),
        content: TextField(controller: title,
          decoration: const InputDecoration(labelText: 'نام گفتگو')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('لغو')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, title.text.trim()),
            child: const Text('ساخت')),
        ],
      ),
    );
    if (value == null || value.isEmpty) return;
    setState(() => busy = true);
    try {
      final uid = db.auth.currentUser!.id;
      final row = await db.from('chats').insert({
        'title': value, 'type': 'group', 'created_by': uid,
      }).select().single();
      await db.from('chat_members').insert({
        'chat_id': row['id'], 'user_id': uid, 'role': 'owner',
      });
      if (mounted) openChat(row['id'].toString(), value);
    } catch (e) {
      if (mounted) message('خطا در ساخت گفتگو: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void openChat(String id, String name) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChatPage(chatId: id, title: name),
    ));
  }

  void message(String value) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(value)),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('NEXA', style: TextStyle(color: green)),
      actions: [
        IconButton(
          onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProfilePage())),
          icon: const Icon(Icons.person),
        ),
        IconButton(
          onPressed: () => db.auth.signOut(),
          icon: const Icon(Icons.logout),
        ),
      ],
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: green,
      foregroundColor: Colors.black,
      onPressed: busy ? null : createChat,
      child: const Icon(Icons.add_comment),
    ),
    body: FutureBuilder<List<Map<String, dynamic>>>(
      future: loadChats(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('خطا: ${snapshot.error}'));
        }
        final rows = snapshot.data ?? [];
        if (rows.isEmpty) {
          return const Center(child: Text('هنوز گفتگویی نداری'));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, i) => ListTile(
              leading: const CircleAvatar(
                backgroundColor: panel,
                child: Icon(Icons.forum, color: green),
              ),
              title: Text(rows[i]['title']?.toString() ?? 'گفتگو'),
              subtitle: Text(rows[i]['type']?.toString() ?? ''),
              onTap: () => openChat(
                rows[i]['id'].toString(),
                rows[i]['title'].toString(),
              ),
            ),
          ),
        );
      },
    ),
  );
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final username = TextEditingController();
  final display = TextEditingController();
  bool busy = false;

  Future<void> save() async {
    final uid = db.auth.currentUser!.id;
    if (username.text.trim().isEmpty || display.text.trim().isEmpty) return;
    setState(() => busy = true);
    try {
      await db.from('profiles').upsert({
        'id': uid,
        'username': username.text.trim(),
        'display_name': display.text.trim(),
      });
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('پروفایل')),
    body: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        TextField(controller: display,
          decoration: const InputDecoration(labelText: 'نام نمایشی')),
        const SizedBox(height: 12),
        TextField(controller: username,
          decoration: const InputDecoration(labelText: 'نام کاربری')),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: busy ? null : save,
          child: const Text('ذخیره'),
        ),
      ]),
    ),
  );
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String title;
  const ChatPage({super.key, required this.chatId, required this.title});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();
  bool busy = false;

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty || busy) return;
    setState(() => busy = true);
    try {
      await db.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': db.auth.currentUser!.id,
        'content': text,
        'message_type': 'text',
      });
      input.clear();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ارسال ناموفق: $e')));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: Column(children: [
      Expanded(
        child: StreamBuilder<List<Map<String, dynamic>>>(
          stream: db.from('messages').stream(primaryKey: ['id'])
            .eq('chat_id', widget.chatId).order('created_at'),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('خطا: ${snapshot.error}'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final rows = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: rows.length,
              itemBuilder: (context, i) {
                final row = rows[i];
                final mine = row['sender_id'] == db.auth.currentUser!.id;
                return Align(
                  alignment: mine ? Alignment.centerRight :
                    Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(13),
                    constraints: const BoxConstraints(maxWidth: 290),
                    decoration: BoxDecoration(
                      color: mine ? const Color(0xFF075C38) : panel,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(row['content']?.toString() ?? ''),
                  ),
                );
              },
            );
          },
        ),
      ),
      SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Row(children: [
            Expanded(child: TextField(
              controller: input,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'پیام بنویس...'),
            )),
            IconButton(
              onPressed: busy ? null : send,
              icon: const Icon(Icons.send, color: green),
            ),
          ]),
        ),
      ),
    ]),
  );
}
