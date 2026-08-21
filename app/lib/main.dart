import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/api_client.dart';
import 'core/token_storage.dart';
import 'features/auth/auth_api.dart';
import 'features/auth/auth_state.dart';
import 'features/auth/login_screen.dart';
import 'features/ingredient/ingredient_api.dart';
import 'features/inventory/inventory_api.dart';
import 'features/mealplan/meal_plan_api.dart';
import 'features/recipe/recipe_api.dart';
import 'features/shopping/shopping_api.dart';
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
        Provider<IngredientApi>(create: (_) => IngredientApi(apiClient)),
        Provider<InventoryApi>(create: (_) => InventoryApi(apiClient)),
        Provider<RecipeApi>(create: (_) => RecipeApi(apiClient)),
        Provider<MealPlanApi>(create: (_) => MealPlanApi(apiClient)),
        Provider<ShoppingApi>(create: (_) => ShoppingApi(apiClient)),
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
    final loggedIn = context.select<AuthState, bool>((a) => a.loggedIn);
    return MaterialApp(
      // 로그인 상태가 바뀌면 네비게이터를 통째로 새로 만든다.
      // home만 갈아끼우면 그 위에 쌓여 있던 화면(설정·상세 등)이 남아,
      // 로그아웃이나 401 만료 뒤에도 이전 화면이 그대로 보인다.
      key: ValueKey(loggedIn),
      title: 'Smart Kitchen',
      theme: ThemeData(colorSchemeSeed: Colors.green, useMaterial3: true),
      // 달력(S-32 날짜 선택)이 한국어로 나오도록. 앱은 한국어 전용이다
      locale: const Locale('ko'),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: const [Locale('ko'), Locale('en')],
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
