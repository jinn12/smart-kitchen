import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/inventory/inventory_api.dart';
import 'features/shell/main_shell.dart';

void main() {
  final tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final authApi = AuthApi(apiClient, tokenStorage);
  final authState = AuthState(authApi, tokenStorage);

  // 토큰 만료(401)를 받으면 로그인 상태를 내린다 -> 루트가 로그인 화면으로 되돌린다
  apiClient.onUnauthorized = authState.onSessionExpired;

  runApp(
    MultiProvider(
      providers: [
        Provider<TokenStorage>.value(value: tokenStorage),
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthApi>.value(value: authApi),
        Provider<InventoryApi>(create: (_) => InventoryApi(apiClient)),
        ChangeNotifierProvider<AuthState>.value(value: authState..restore()),
      ],
      child: const SmartKitchenApp(),
    ),
  );
}

class SmartKitchenApp extends StatelessWidget {
  const SmartKitchenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Kitchen',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      home: const _Root(),
    );
  }
}

/// 저장된 토큰 유무로 첫 화면을 가른다.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    if (auth.initializing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.loggedIn ? const MainShell() : const LoginScreen();
  }
}
