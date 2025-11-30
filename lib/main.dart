import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'features/settings/providers/settings_provider.dart';
import 'firebase_options.dart';

// Import the screen files
import 'features/auth/login_screen.dart';
import 'features/auth/signup_screen.dart';
import 'features/home/home_screen.dart';
import 'features/marketplace/marketplace_screen.dart';
import 'features/marketplace/screens/payment_screen.dart';
import 'features/marketplace/services/marketplace_service.dart'
    show LocalMarketplaceService;
import 'features/ai_bot/screens/chat_list_screen.dart';
import 'features/profile/profile_screen.dart';
import 'package:straycare_demo/features/marketplace/models/marketplace_model.dart'
    show Cart;
// Note: enums.dart is imported within home_screen.dart where it's needed

import 'l10n/app_localizations.dart';

// --- MAIN FUNCTION ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(const StrayCareDemoApp());
}

// --- MYAPP WIDGET ---
class StrayCareDemoApp extends StatelessWidget {
  const StrayCareDemoApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => SettingsProvider())],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'StrayCare Demo',
            themeMode: settings.themeMode,
            locale: settings.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'), // English
              Locale('bn'), // Bangla
              Locale('es'), // Spanish
              Locale('fr'), // French
            ],
            // Light Theme
            theme: ThemeData(
              primaryColor: const Color(0xFF6B46C1),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B46C1),
                primary: const Color(0xFF6B46C1),
                secondary: const Color(0xFFA78BFA),
                surface: Colors.white,
                onSurface: Colors.black87,
              ),
              scaffoldBackgroundColor: Colors.grey[50],
              cardTheme: CardThemeData(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Colors.white,
                elevation: 1,
                iconTheme: IconThemeData(color: Color(0xFF6B46C1)),
                titleTextStyle: TextStyle(
                  color: Color(0xFF6B46C1),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: const Color(0xFF6B46C1),
                unselectedItemColor: Colors.grey[600],
                backgroundColor: Colors.white,
                elevation: 8,
                type: BottomNavigationBarType.fixed,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFFA78BFA),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.black87),
                bodyMedium: TextStyle(color: Colors.black54),
              ),
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            // Dark Theme
            darkTheme: ThemeData.dark().copyWith(
              primaryColor: const Color(0xFF6B46C1),
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF6B46C1),
                primary: const Color(0xFF6B46C1),
                secondary: const Color(0xFFA78BFA),
                surface: const Color(0xFF121212),
                onSurface: Colors.white70,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: const Color(0xFF121212),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E1E1E),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 8.0,
                ),
              ),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                elevation: 1,
                iconTheme: IconThemeData(color: Color(0xFFA78BFA)),
                titleTextStyle: TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              bottomNavigationBarTheme: BottomNavigationBarThemeData(
                selectedItemColor: const Color(0xFFA78BFA),
                unselectedItemColor: Colors.grey[400],
                backgroundColor: const Color(0xFF1E1E1E),
                elevation: 8,
                type: BottomNavigationBarType.fixed,
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF6B46C1),
              ),
              textTheme: const TextTheme(
                bodyLarge: TextStyle(color: Colors.white),
                bodyMedium: TextStyle(color: Colors.white70),
              ),
            ),
            home: const LoginScreen(),
            debugShowCheckedModeBanner: false,
            routes: {
              '/login': (context) => const LoginScreen(),
              '/signup': (context) => const SignUpScreen(),
              '/home': (context) => const MainAppShell(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == '/payment') {
                final args = settings.arguments;
                if (args is Cart) {
                  return MaterialPageRoute(
                    builder: (context) => PaymentScreen(
                      cart: args,
                      service: LocalMarketplaceService(),
                    ),
                  );
                }
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

// --- MAIN APP SHELL ---
// This widget remains here as it controls the overall structure.
class MainAppShell extends StatefulWidget {
  const MainAppShell({Key? key}) : super(key: key);

  @override
  _MainAppShellState createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _currentIndex = 0;

  // List now refers to the imported screen classes
  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketplaceScreen(),
    const ChatListScreen(),
    const ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalizations.of(context).translate('home'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.storefront_outlined),
            activeIcon: const Icon(Icons.storefront_rounded),
            label: AppLocalizations.of(context).translate('marketplace'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.chat_bubble_outline),
            activeIcon: const Icon(Icons.chat_bubble),
            label: AppLocalizations.of(context).translate('ai_bot'),
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppLocalizations.of(context).translate('profile'),
          ),
        ],
      ),
    );
  }
}
