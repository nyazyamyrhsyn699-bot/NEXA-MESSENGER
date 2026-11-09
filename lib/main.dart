import 'nexa_backend.dart';
import 'package:flutter/material.dart';

const green = Color(0xFF00F5A0);
const background = Color(0xFF080B10);
const panel = Color(0xFF121923);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NexaBackend.initialize();
  runApp(const NexaApp());
}

class NexaApp extends StatelessWidget {
  const NexaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NEXA Messenger',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: green,
          surface: panel,
        ),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final username = TextEditingController();
  final password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: green.withOpacity(.12),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: green, width: 1.5),
                ),
                child: const Icon(
                  Icons.bolt,
                  size: 65,
                  color: green,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'NEXA',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: green,
                ),
              ),
              const Text(
                'MESSENGER',
                style: TextStyle(
                  letterSpacing: 5,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'به دنیای NEXA خوش آمدید',
                style: TextStyle(fontSize: 21),
              ),
              const SizedBox(height: 25),
              input(username, 'نام کاربری', Icons.person),
              const SizedBox(height: 15),
              input(password, 'رمز عبور', Icons.lock,
                  obscure: true),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: green,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (username.text.trim().isEmpty ||
                        password.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('اطلاعات ورود را وارد کنید'),
                        ),
                      );
                      return;
                    }

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomePage(
                          username: username.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'ورود به NEXA',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {},
                child: const Text(
                  'ساخت حساب جدید',
                  style: TextStyle(color: green),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'CONNECT • COMMUNICATE • NEXA',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget input(
    TextEditingController controller,
    String hint,
    IconData icon, {
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      textDirection: TextDirection.rtl,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: green),
        filled: true,
        fillColor: panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final String username;

  const HomePage({super.key, required this.username});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selected = 0;

  final names = [
    'NEXA Support',
    'Amir',
    'Gaming Group',
    'Technology',
    'Friends',
  ];

  final messages = [
    'به NEXA خوش آمدید',
    'سلام، خوبی؟',
    'پیام جدید',
    'آخرین اخبار فناوری',
    'آنلاین هستید؟',
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: panel,
          title: const Row(
            children: [
              Icon(Icons.bolt, color: green, size: 30),
              SizedBox(width: 8),
              Text(
                'NEXA',
                style: TextStyle(
                  color: green,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.search),
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert),
            ),
          ],
        ),
        body: IndexedStack(
          index: selected,
          children: [
            chats(),
            contacts(),
            groups(),
            profile(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: panel,
          indicatorColor: green.withOpacity(.15),
          selectedIndex: selected,
          onDestinationSelected: (i) {
            setState(() => selected = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: green),
              label: 'چت‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              label: 'مخاطبین',
            ),
            NavigationDestination(
              icon: Icon(Icons.groups_outlined),
              label: 'گروه‌ها',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              label: 'پروفایل',
            ),
          ],
        ),
        floatingActionButton: selected == 0
            ? FloatingActionButton(
                backgroundColor: green,
                foregroundColor: Colors.black,
                onPressed: newChat,
                child: const Icon(Icons.add_comment),
              )
            : null,
      ),
    );
  }

  Widget chats() {
    return ListView(
      children: [
        const Padding(
          padding: EdgeInsets.all(18),
          child: Text(
            'پیام‌های شما',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        for (int i = 0; i < names.length; i++)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 7,
            ),
            leading: CircleAvatar(
              radius: 27,
              backgroundColor: green.withOpacity(.13),
              child: const Icon(
                Icons.person,
                color: green,
              ),
            ),
            title: Text(
              names[i],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              messages[i],
              style: const TextStyle(color: Colors.white54),
            ),
            trailing: const Icon(
              Icons.circle,
              color: green,
              size: 9,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(name: names[i]),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget contacts() {
    return const Center(
      child: Text(
        'مخاطبین NEXA',
        style: TextStyle(fontSize: 23, color: green),
      ),
    );
  }

  Widget groups() {
    return const Center(
      child: Text(
        'گروه‌ها و کانال‌ها',
        style: TextStyle(fontSize: 23, color: green),
      ),
    );
  }

  Widget profile() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 45,
            backgroundColor: green,
            child: Icon(Icons.person, size: 55, color: Colors.black),
          ),
          const SizedBox(height: 20),
          Text(
            widget.username,
            style: const TextStyle(fontSize: 23),
          ),
          const SizedBox(height: 10),
          const Text(
            'NEXA USER',
            style: TextStyle(color: green, letterSpacing: 3),
          ),
          const SizedBox(height: 30),
          const ListTile(
            leading: Icon(Icons.settings, color: green),
            title: Text('تنظیمات'),
          ),
          const ListTile(
            leading: Icon(Icons.shield, color: green),
            title: Text('امنیت و حریم خصوصی'),
          ),
        ],
      ),
    );
  }

  void newChat() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: panel,
        title: const Text('گفتگوی جدید'),
        content: const Text('بخش جستجوی کاربران در نسخه بعدی متصل می‌شود.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('باشه', style: TextStyle(color: green)),
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String name;

  const ChatPage({super.key, required this.name});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final controller = TextEditingController();
  final messages = <String>[];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: panel,
          title: Text(widget.name),
          actions: const [
            Icon(Icons.call, color: green),
            SizedBox(width: 18),
            Icon(Icons.videocam, color: green),
            SizedBox(width: 15),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: messages.length,
                itemBuilder: (_, i) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: green.withOpacity(.15),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Text(messages[i]),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              color: panel,
              child: Row(
                children: [
                  const Icon(Icons.attach_file, color: green),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'پیام خود را بنویسید...',
                        filled: true,
                        fillColor: background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (controller.text.trim().isEmpty) return;
                      setState(() {
                        messages.add(controller.text.trim());
                        controller.clear();
                      });
                    },
                    icon: const Icon(
                      Icons.send,
                      color: green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
