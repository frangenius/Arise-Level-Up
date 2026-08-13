import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/database/db_helper.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/calibration_screen.dart';
import 'features/home/presentation/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Bloquear orientación vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Estilo de la barra de sistema (transparente, íconos claros)
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF02040a),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  
  // Inicializar Hive para almacenamiento rápido de configuración y perfil
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('user_profile');
  
  // Inicializar base de datos SQLite
  await DbHelper.instance.database;
  
  runApp(
    // ProviderScope wraps everything para que Riverpod funcione
    const ProviderScope(
      child: LevelUpApp(),
    ),
  );
}

class LevelUpApp extends ConsumerWidget {
  const LevelUpApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LEVEL UP - The System',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      
      // Enrutamiento inicial según el perfil del usuario
      initialRoute: '/',
      routes: {
        '/': (ctx) => const SplashScreen(),
        '/calibration': (ctx) => const CalibrationScreen(),
        '/home': (ctx) => const HomeScreen(),
      },
    );
  }
}
