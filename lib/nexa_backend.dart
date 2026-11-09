import 'package:supabase_flutter/supabase_flutter.dart';

class NexaBackend {
  static const String supabaseUrl =
      'https://qscxdvikapcqwevcgbhd.supabase.co';

  static const String supabaseKey =
      'sb_publishable_LFZQ0SS5nsqcJ_otNVRvVA_2i3p6EfE';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  // ارسال کد ورود پیامکی
  static Future<void> sendOtp(String phone) async {
    await client.auth.signInWithOtp(
      phone: phone,
    );
  }

  // تأیید کد پیامکی
  static Future<void> verifyOtp({
    required String phone,
    required String token,
  }) async {
    await client.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  // خروج از حساب
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // ایجاد یا به‌روزرسانی پروفایل
  static Future<void> saveProfile({
    required String username,
    required String displayName,
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    await client.from('profiles').upsert({
      'id': user.id,
      'username': username,
      'display_name': displayName,
    });
  }

  // ساخت گفتگو
  static Future<String> createChat({
    required String title,
    String type = 'private',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    final result = await client
        .from('chats')
        .insert({
          'title': title,
          'type': type,
          'created_by': user.id,
        })
        .select('id')
        .single();

    final chatId = result['id'] as String;

    await client.from('chat_members').insert({
      'chat_id': chatId,
      'user_id': user.id,
      'role': 'owner',
    });

    return chatId;
  }

  // ارسال پیام
  static Future<void> sendMessage({
    required String chatId,
    required String content,
    String messageType = 'text',
  }) async {
    final user = currentUser;
    if (user == null) {
      throw Exception('User is not authenticated');
    }

    await client.from('messages').insert({
      'chat_id': chatId,
      'sender_id': user.id,
      'content': content,
      'message_type': messageType,
    });
  }

  // دریافت پیام‌های گفتگو
  static Future<List<Map<String, dynamic>>> getMessages(
    String chatId,
  ) async {
    final result = await client
        .from('messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at');

    return List<Map<String, dynamic>>.from(result);
  }

  // دریافت گفتگوهای کاربر
  static Future<List<Map<String, dynamic>>> getChats() async {
    final result = await client
        .from('chats')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(result);
  }
}
