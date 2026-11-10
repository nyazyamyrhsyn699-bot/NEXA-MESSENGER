NEXA MESSENGER V2

Before building:
1. Open Supabase SQL Editor.
2. Run supabase/migrations/001_nexa_core.sql.
3. In Supabase Authentication > Providers, enable Email.
4. Configure email confirmation and SMTP if needed.
5. Enable Realtime for the messages table.
6. Do not put service_role keys in the mobile app.

Current implemented:
- Email signup/login/password reset
- Profile editing
- Group creation
- Member chat list
- Realtime text messaging

Not yet implemented:
- Direct user discovery and private-chat creation
- Media upload and voice/video calls
- Push notifications
- Full admin dashboard and moderation workflow
- End-to-end encryption
