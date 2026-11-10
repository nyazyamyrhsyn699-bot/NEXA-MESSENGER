import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://qscxdvikapcqwevcgbhd.supabase.co';
const supabaseKey = 'sb_publishable_LFZQ0SS5nsqcJ_otNVRvVA_2i3p6EfE';

final supabase = Supabase.instance.client;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );
  runApp(const NexaApp());
}

const green = Color(0xFF00FF88);
const background = Color(0xFF080D0B);
const panel = Color(0xFF121B16);

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXA MESSENGER',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: green,
          brightness: Brightness.dark,
        ),
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
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (supabase.auth.currentUser == null) {
          return const LoginPage();
        }
        return const ProfilePage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final phone = TextEditingController(text: '+98');
  final code = TextEditingController();
  bool sent = false;
  bool loading = false;

  Future<void> sendCode() async {
    setState(() => loading = true);
    try {
      await supabase.auth.signInWithOtp(phone: phone.text.trim());
      setState(() => sent = true);
      message('کد تأیید ارسال شد.');
    } catch (e) {
      message('خطا در ارسال کد: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> verifyCode() async {
    setState(() => loading = true);
    try {
      await supabase.auth.verifyOTP(
        phone: phone.text.trim(),
        token: code.text.trim(),
        type: OtpType.sms,
      );
    } catch (e) {
      message('کد تأیید نامعتبر است یا منقضی شده: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  void message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              children: [
                const Icon(Icons.bolt, color: green, size: 76),
                const SizedBox(height: 12),
                const Text(
                  'NEXA',
                  style: TextStyle(
                    color: green,
                    fontSize: 38,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 7,
                  ),
                ),
                const Text('MESSENGER',
                    style: TextStyle(letterSpacing: 5)),
                const SizedBox(height: 45),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'شماره موبایل با کد کشور',
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                if (sent) ...[
                  const SizedBox(height: 14),
                  TextField(
                    controller: code,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'کد پیامکی',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: loading
                        ? null
                        : sent
                            ? verifyCode
                            : sendCode,
                    child: loading
                        ? const CircularProgressIndicator()
                        : Text(sent ? 'تأیید و ورود' : 'ارسال کد ورود'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'ارتباط امن از طریق NEXA',
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final username = TextEditingController();
  final displayName = TextEditingController();
  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final id = supabase.auth.currentUser!.id;
      final row = await supabase
          .from('profiles')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (row != null) {
        username.text = row['username']?.toString() ?? '';
        displayName.text = row['display_name']?.toString() ?? '';
      }
    } catch (_) {}
    if (mounted) setState(() => loading = false);
  }

  Future<void> save() async {
    if (username.text.trim().isEmpty ||
        displayName.text.trim().isEmpty) {
      return;
    }

    setState(() => saving = true);
    try {
      await supabase.from('profiles').upsert({
        'id': supabase.auth.currentUser!.id,
        'username': username.text.trim(),
        'display_name': displayName.text.trim(),
      });
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا در ذخیره پروفایل: $e')),
      );
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('پروفایل NEXA')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.account_circle, size: 90, color: green),
            const SizedBox(height: 24),
            TextField(
              controller: displayName,
              decoration: const InputDecoration(labelText: 'نام نمایشی'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: username,
              decoration: const InputDecoration(labelText: 'نام کاربری'),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : save,
                child: Text(saving ? 'در حال ذخیره...' : 'ذخیره و ادامه'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final title = TextEditingController();
  bool loading = false;

  Future<List<Map<String, dynamic>>> chats() async {
    final result = await supabase
        .from('chats')
        .select()
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(result);
  }

  Future<void> createChat() async {
    title.clear();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('گفتگوی جدید'),
        content: TextField(
          controller: title,
          decoration: const InputDecoration(labelText: 'عنوان گفتگو'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('لغو'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, title.text.trim()),
            child: const Text('ساخت'),
          ),
        ],
      ),
    );

    if (value == null || value.isEmpty) return;

    setState(() => loading = true);
    try {
      final row = await supabase.from('chats').insert({
        'title': value,
        'type': 'group',
        'created_by': supabase.auth.currentUser!.id,
      }).select().single();

      await supabase.from('chat_members').insert({
        'chat_id': row['id'],
        'user_id': supabase.auth.currentUser!.id,
        'role': 'owner',
      });

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: row['id'].toString(),
            chatTitle: value,
          ),
        ),
      );
      setState(() {});
    } catch (e) {
      showMessage('ساخت گفتگو ناموفق بود: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NEXA',
            style: TextStyle(color: green, letterSpacing: 4)),
        actions: [
          IconButton(
            onPressed: () async {
              await supabase.auth.signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: green,
        foregroundColor: Colors.black,
        onPressed: loading ? null : createChat,
        child: const Icon(Icons.add_comment),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: chats(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطا در دریافت گفتگوها: ${snapshot.error}'));
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.forum_outlined, size: 70, color: green),
                  SizedBox(height: 15),
                  Text('هنوز گفتگویی نداری'),
                  Text('برای ساخت گفتگو دکمه + را بزن'),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final chat = data[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: panel,
                    child: Icon(Icons.forum, color: green),
                  ),
                  title: Text(chat['title']?.toString() ?? 'گفتگو'),
                  subtitle: Text(chat['type']?.toString() ?? ''),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatPage(
                        chatId: chat['id'].toString(),
                        chatTitle: chat['title']?.toString() ?? 'گفتگو',
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String chatId;
  final String chatTitle;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.chatTitle,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final input = TextEditingController();

  Future<void> send() async {
    final text = input.text.trim();
    if (text.isEmpty) return;
    input.clear();

    try {
      await supabase.from('messages').insert({
        'chat_id': widget.chatId,
        'sender_id': supabase.auth.currentUser!.id,
        'content': text,
        'message_type': 'text',
      });
    } catch (e) {
      input.text = text;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ارسال پیام ناموفق بود: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatTitle)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: supabase
                  .from('messages')
                  .stream(primaryKey: ['id'])
                  .eq('chat_id', widget.chatId)
                  .order('created_at'),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('خطا: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final rows = snapshot.data!;
                if (rows.isEmpty) {
                  return const Center(child: Text('اولین پیام را بفرست'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final mine = row['sender_id'] ==
                        supabase.auth.currentUser!.id;
                    return Align(
                      alignment: mine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
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
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        hintText: 'پیام بنویس...',
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: send,
                    icon: const Icon(Icons.send, color: green),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
