import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_profile.dart';
import '../../core/utils/user_provider.dart';
import '../home/presentation/home_screen.dart';
import 'calibration_screen.dart';

/// Splash Screen con animación de carga y enrutado inicial
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _scaleAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.3, 1.0)),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: const Interval(0.4, 1.0)),
    );

    _animController.forward();

    // Navegar después de 2.5 segundos
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      final profile = ref.read(userProfileProvider);
      if (profile != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/calibration');
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: Center(
          child: AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo con efecto de pulsación y brillo
                  ScaleTransition(
                    scale: _scaleAnim,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow detrás del logo
                        Opacity(
                          opacity: _glowAnim.value,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  AppTheme.colorPrimary.withOpacity(0.3),
                                  AppTheme.colorSecondary.withOpacity(0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Icono central
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppTheme.colorPrimary.withOpacity(_glowAnim.value),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.colorPrimary.withOpacity(0.5 * _glowAnim.value),
                                blurRadius: 25,
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppTheme.colorPrimary, AppTheme.colorSecondary],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: const Icon(Icons.bolt, size: 55, color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  FadeTransition(
                    opacity: _fadeAnim,
                    child: Column(
                      children: [
                        Text(
                          'LEVEL UP',
                          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            shadows: [
                              Shadow(
                                color: AppTheme.colorPrimary.withOpacity(0.7),
                                blurRadius: 15,
                              ),
                              Shadow(
                                color: AppTheme.colorSecondary.withOpacity(0.4),
                                blurRadius: 30,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'THE SYSTEM',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.colorXP,
                            letterSpacing: 5,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Indicador de carga minimalista
                        SizedBox(
                          width: 160,
                          child: LinearProgressIndicator(
                            backgroundColor: Colors.white.withOpacity(0.05),
                            color: AppTheme.colorPrimary,
                            value: _glowAnim.value,
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Inicializando Sistema...',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
