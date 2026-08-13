import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_profile.dart';
import '../../core/utils/user_provider.dart';

/// Pantalla de calibración inicial (onboarding de primer uso)
class CalibrationScreen extends ConsumerStatefulWidget {
  const CalibrationScreen({super.key});

  @override
  ConsumerState<CalibrationScreen> createState() => _CalibrationScreenState();
}

class _CalibrationScreenState extends ConsumerState<CalibrationScreen> {
  int _currentSlide = 0;
  final PageController _pageController = PageController();

  // Datos recopilados durante la calibración
  final TextEditingController _nameController = TextEditingController(text: 'Franco');
  String _selectedAvatar = 'knight';
  String _physicalDays = '0';
  String _studyTime = 'nada';
  String _goal = 'fisico';

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextSlide() {
    if (_currentSlide == 0 && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa tu nombre para continuar.')),
      );
      return;
    }
    if (_currentSlide < 3) {
      setState(() => _currentSlide++);
      _pageController.animateToPage(
        _currentSlide,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeCalibration() async {
    // Calcular estadísticas base según respuestas
    int strength = 10, intelligence = 10, discipline = 10, spirit = 10, defense = 10;

    if (_physicalDays == '3-5') strength += 3;
    if (_physicalDays == 'todos') strength += 5;

    if (_studyTime == '30m') intelligence += 2;
    if (_studyTime == '1h') intelligence += 4;
    if (_studyTime == '2h+') intelligence += 6;

    // Determinar clase según objetivo
    String userClass = 'guerrero';
    if (_goal == 'aprender') userClass = 'estratega';
    else if (_goal == 'disciplinado') userClass = 'desafiante';
    else if (_goal == 'bienestar') userClass = 'explorador';

    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    final profile = UserProfile(
      name: _nameController.text.trim(),
      selectedAvatar: _selectedAvatar,
      userClass: userClass,
      createdDate: todayStr,
      lastLoginDate: todayStr,
      stats: {
        'strength': strength,
        'intelligence': intelligence,
        'discipline': discipline,
        'spirit': spirit,
        'defense': defense,
      },
    );

    await ref.read(userProfileProvider.notifier).saveProfile(profile);

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Indicador de progreso del onboarding
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: List.generate(4, (idx) {
                    return Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          color: idx <= _currentSlide
                              ? AppTheme.colorPrimary
                              : Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildSlide1(),
                    _buildSlide2(),
                    _buildSlide3(),
                    _buildSlide4(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlide1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inicialización del Sistema',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.colorPrimary)),
          const SizedBox(height: 8),
          Text('¿Cómo te llamarás en el Sistema, Cazador?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: Colors.white, fontSize: 18),
            decoration: const InputDecoration(
              labelText: 'NOMBRE DEL CAZADOR',
              hintText: 'Ingresa tu nombre...',
            ),
          ),
          const SizedBox(height: 28),
          Text('ELIGE TU AVATAR INICIAL',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white60)),
          const SizedBox(height: 12),
          _avatarCard(
            value: 'knight',
            icon: '🛡️',
            title: 'Caballero de las Sombras',
            desc: 'Especialista en fuerza y combate cuerpo a cuerpo.',
          ),
          const SizedBox(height: 8),
          _avatarCard(
            value: 'mage',
            icon: '🔮',
            title: 'Hechicero del Abismo',
            desc: 'Controlador del maná y dominio de la inteligencia.',
          ),
          const SizedBox(height: 32),
          _buildPrimaryBtn('Continuar ➡️', _nextSlide),
        ],
      ),
    );
  }

  Widget _buildSlide2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Análisis Físico',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.colorPrimary)),
          const SizedBox(height: 8),
          Text('¿Cuántos días por semana realizas actividad física?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...[
            ('0', '💤', 'Ninguno (Sedentario)'),
            ('1-2', '🏃', '1 - 2 días por semana'),
            ('3-5', '💪', '3 - 5 días por semana'),
            ('todos', '🔥', 'Todos los días (Atleta)'),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _optionCard(
                selected: _physicalDays == e.$1,
                icon: e.$2,
                title: e.$3,
                onTap: () => setState(() => _physicalDays = e.$1),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildPrimaryBtn('Continuar ➡️', _nextSlide),
        ],
      ),
    );
  }

  Widget _buildSlide3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Análisis Mental',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.colorPrimary)),
          const SizedBox(height: 8),
          Text('¿Cuánto tiempo dedicas a estudiar o leer diariamente?',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...[
            ('nada', '❌', 'Nada actualmente'),
            ('30m', '📖', '30 Minutos al día'),
            ('1h', '🧠', '1 Hora al día'),
            ('2h+', '🌌', 'Más de 2 Horas al día'),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _optionCard(
                selected: _studyTime == e.$1,
                icon: e.$2,
                title: e.$3,
                onTap: () => setState(() => _studyTime = e.$1),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildPrimaryBtn('Continuar ➡️', _nextSlide),
        ],
      ),
    );
  }

  Widget _buildSlide4() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Objetivo Principal',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(color: AppTheme.colorPrimary)),
          const SizedBox(height: 8),
          Text('El Sistema calibrará tus misiones diarias según tu camino.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          ...[
            ('fisico', '💪', 'Mejorar Físico', 'Clase: Guerrero • Boost: Fuerza'),
            ('aprender', '📚', 'Aprender Más', 'Clase: Estratega • Boost: Inteligencia'),
            ('disciplinado', '⏱️', 'Ser más Disciplinado', 'Clase: Desafiante • Boost: Disciplina'),
            ('bienestar', '🧘', 'Mejorar Bienestar', 'Clase: Explorador • Boost: Espíritu'),
          ].map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _optionCard(
                selected: _goal == e.$1,
                icon: e.$2,
                title: e.$3,
                subtitle: e.$4,
                onTap: () => setState(() => _goal = e.$1),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: AppTheme.primaryButtonGradient,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _completeCalibration,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      '🔥  DESPERTAR SISTEMA',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatarCard({
    required String value,
    required String icon,
    required String title,
    required String desc,
  }) {
    final selected = _selectedAvatar == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedAvatar = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.colorPrimary.withOpacity(0.12)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.colorPrimary : Colors.white.withOpacity(0.08),
            width: 1.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.colorPrimary.withOpacity(0.2), blurRadius: 12)]
              : [],
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 26)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: selected ? AppTheme.colorPrimary : Colors.white,
                  )),
                  Text(desc, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.colorPrimary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _optionCard({
    required bool selected,
    required String icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.colorPrimary.withOpacity(0.1)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.colorPrimary : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodyLarge),
                  if (subtitle != null)
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.colorXP,
                    )),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.colorPrimary, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryBtn(String label, VoidCallback onTap) {
    return Container(
      decoration: AppTheme.primaryButtonGradient,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
