import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_profile.dart';
import '../../core/utils/user_provider.dart';
import '../../core/database/db_helper.dart';

/// Pantalla de perfil del personaje
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('PERFIL')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de identidad del cazador
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassPanel(neonBorder: true),
              child: Column(
                children: [
                  // Avatar
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.colorPrimary, AppTheme.colorSecondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.colorPrimary.withOpacity(0.4),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        profile.selectedAvatar == 'knight' ? '🛡️' : '🔮',
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile.name,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '[${profile.activeTitle.toUpperCase()}]',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.colorGold,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.colorPrimary, AppTheme.colorSecondary],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Rango ${profile.hunterRank}  |  Nivel ${profile.level}',
                      style: const TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Estadísticas detalladas
            _sectionHeader(context, 'ESTADÍSTICAS PRINCIPALES'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassPanel(),
              child: Column(
                children: [
                  _statRow(context, '💪', 'Fuerza', profile.stats['strength'] ?? 10, AppTheme.colorStrength),
                  _statRow(context, '🧠', 'Inteligencia', profile.stats['intelligence'] ?? 10, AppTheme.colorIntelligence),
                  _statRow(context, '⏱️', 'Disciplina', profile.stats['discipline'] ?? 10, AppTheme.colorDiscipline),
                  _statRow(context, '🧘', 'Espíritu', profile.stats['spirit'] ?? 10, AppTheme.colorSpirit),
                  _statRow(context, '🛡️', 'Defensa', profile.stats['defense'] ?? 10, AppTheme.colorDefense),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Info de clase
            _sectionHeader(context, 'CLASE Y CLASE ESPECIAL'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassPanel(),
              child: Row(
                children: [
                  Text(_classEmoji(profile.userClass), style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _className(profile.userClass),
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      Text(
                        _classDesc(profile.userClass),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Logros
            _sectionHeader(context, 'LOGROS'),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DbHelper.instance.getAchievements(),
              builder: (ctx, snapshot) {
                final achievements = snapshot.data ?? [];
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: achievements.map((ach) {
                    final completed = (ach['completed'] as int) == 1;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: completed
                            ? AppTheme.colorGold.withOpacity(0.08)
                            : Colors.white.withOpacity(0.02),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: completed ? AppTheme.colorGold.withOpacity(0.4) : Colors.white.withOpacity(0.06),
                        ),
                      ),
                      child: Text(
                        '${completed ? '🏆' : '🔒'} ${ach['name']}',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: completed ? AppTheme.colorGold : Colors.white30,
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _statRow(BuildContext context, String icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (value / 500).clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 6,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 40,
            child: Text(
              '$value',
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700, color: color),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Colors.white60,
        fontSize: 11,
        letterSpacing: 2,
      ),
    );
  }

  String _classEmoji(String c) {
    switch (c) {
      case 'guerrero': return '⚔️';
      case 'estratega': return '📚';
      case 'desafiante': return '💎';
      case 'explorador': return '🗺️';
      default: return '⚡';
    }
  }

  String _className(String c) {
    switch (c) {
      case 'guerrero': return 'GUERRERO';
      case 'estratega': return 'ESTRATEGA';
      case 'desafiante': return 'DESAFIANTE';
      case 'explorador': return 'EXPLORADOR';
      default: return 'CAZADOR';
    }
  }

  String _classDesc(String c) {
    switch (c) {
      case 'guerrero': return '+20% Daño Físico, +10% Defensa';
      case 'estratega': return '+25% XP por misiones de estudio';
      case 'desafiante': return '+30% Oro en misiones completadas';
      case 'explorador': return '+20% XP, Evasión aumentada';
      default: return 'Clase base sin bonus especial.';
    }
  }
}
