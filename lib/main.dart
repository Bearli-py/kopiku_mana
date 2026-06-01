import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_config.dart';
import 'app_theme.dart';
import 'app_routes.dart';
import 'splash_screen.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart';
import 'main_screen.dart';
import 'detail_cafe_screen.dart';
import 'cafe_list_screen.dart';
import 'search_screen.dart';
import 'cafe_model.dart';
import 'premium_screen.dart';
import 'topup_screen.dart';
import 'referral_screen.dart';
import 'review_history_screen.dart';
import 'point_history_screen.dart';
import 'help_screen.dart';
import 'settings_screen.dart';
import 'partnership_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const KopikuManaApp());
}

class KopikuManaApp extends StatelessWidget {
  const KopikuManaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kopiku Mana',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.main: (_) => const MainScreen(),
        AppRoutes.search: (_) => const SearchScreen(),
        AppRoutes.premium: (_) => const PremiumScreen(),
        AppRoutes.topup: (_) => const TopUpScreen(),
        AppRoutes.referral: (_) => const ReferralScreen(),
        AppRoutes.reviewHistory: (context) => const ReviewHistoryScreen(),
        AppRoutes.pointHistory: (context) => const PointHistoryScreen(),
        AppRoutes.help: (_) => const HelpScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
        AppRoutes.partnership: (_) => const PartnershipScreen(),
        AppRoutes.forgotPassword: (_) => const ForgotPasswordScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.cafeDetail) {
          final cafe = settings.arguments as CafeModel;
          return MaterialPageRoute(
            builder: (_) => DetailCafeScreen(cafe: cafe),
          );
        }
        if (settings.name == AppRoutes.cafeList) {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (_) => CafeListScreen(
              title: args['title'],
              cafes: args['cafes'],
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
      },
    );
  }
}
