import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';

// Variável global
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

void main() async {
  // Garante que os plugins (como SharedPreferences) iniciem antes do app
  WidgetsFlutterBinding.ensureInitialized();

  // Carrega a preferência salva antes de rodar o app
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? true; // Padrão é escuro
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          title: 'Agenda Medonha',
          debugShowCheckedModeBanner: false,

          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            useMaterial3: true,
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            cardColor: const Color(0xFF1E1E1E),
            useMaterial3: true,
          ),

          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('pt', 'BR')],
          locale: const Locale('pt', 'BR'),

          home: const HomeScreen(),
        );
      },
    );
  }
}