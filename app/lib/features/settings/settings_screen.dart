import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_info.dart';
import '../auth/auth_state.dart';

/// S-51 설정. 탭이 아니라 냉장고 탭 앱바의 톱니 아이콘으로 들어온다 (D-012).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final auth = context.read<AuthState>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('로그아웃할까요?\n다시 이용하려면 로그인해야 해요.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('닫기')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('로그아웃')),
        ],
      ),
    );
    if (ok != true) return;
    // 로그아웃하면 루트가 로그인 화면으로 갈아치우므로 이 화면은 함께 사라진다
    await auth.logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          _sectionTitle(context, '계정'),
          ListTile(
            leading: const Icon(Icons.mail_outline),
            title: const Text('이메일'),
            subtitle: Text(auth.email ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('닉네임'),
            subtitle: Text(auth.nickname ?? '-'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('로그아웃'),
            onTap: () => _logout(context),
          ),
          const Divider(height: 24),

          _sectionTitle(context, '앱 정보'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('버전'),
            subtitle: Text(appVersion),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('공공데이터 출처'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                ...openDataAttributions.map((line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(line),
                    )),
              ],
            ),
            isThreeLine: true,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('개인정보처리방침'),
            // 문서 링크는 배포 회차에 연결한다
            trailing: const Text('준비 중', style: TextStyle(color: Colors.grey)),
            enabled: false,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
}
