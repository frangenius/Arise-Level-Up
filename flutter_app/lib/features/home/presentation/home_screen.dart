import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_profile.dart';
import '../../core/utils/user_provider.dart';
import '../../core/database/db_helper.dart';
import '../missions/presentation/missions_screen.dart';
import '../profile/presentation/profile_screen.dart';
import '../rpg/presentation/rpg_screen.dart';
import '../inventory/presentation/inventory_screen.dart';
import '../stats/presentation/stats_screen.dart';
import '../shop/presentation/shop_screen.dart';

/// Pantalla principal con NavigationBar inferior de 5 pestañas
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkDailyReset();
  }

  Future<void> _checkDailyReset() async {
    final needsRecovery = await ref.read(userProfileProvider.notifier).checkDailyReset();
    if (needsRecovery && mounted) {
      _showRecoveryMissionDialog();
    }
  }

  void _showRecoveryMissionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0a0f1e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.colorWarning, width: 1),
        ),
        title: const Text(
          '⚠️ MODO RECUPERACIÓN',
          style: TextStyle(
            fontFamily: 'Orbitron',
            color: AppTheme.colorWarning,
            fontSize: 16,
            fontWeight: FontWeight.w900,
          ),
          textAlign: TextAlign.center,
        ),
        content: const Text(
          'Has estado inactivo durante varios días. El Sistema ha detectado tu ausencia.\n\n'
          'Una misión especial de recuperación ha sido creada para ti. Complétala para restaurar tu ritmo.',
          style: TextStyle(color: Colors.white70, height: 1.5),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Entendido, Hunter',
              style: TextStyle(
                fontFamily: 'Orbitron',
                color: AppTheme.colorPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Lista de pantallas principales por pestaña
  late final List<Widget> _screens = [
    const _HomeTab(),
    const MissionsScreen(),
    const RPGScreen(),
    const InventoryScreen(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF030608),
          border: Border(
            top: BorderSide(
              color: AppTheme.colorPrimary.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          height: 68,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            NavigationDestination(
              icon: Icon(Icons.scroll_outlined),
              selectedIcon: Icon(Icons.scroll),
              label: 'Misiones',
            ),
            NavigationDestination(
              icon: Icon(Icons.sports_martial_arts_outlined),
              selectedIcon: Icon(Icons.sports_martial_arts),
              label: 'RPG',
            ),
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Items',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Stats',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestaña de Inicio con panel de control completo
class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) return const SizedBox();

    final xpPercent = profile.xp / profile.xpForNextLevel;

    return CustomScrollView(
      slivers: [
        // AppBar superior
        SliverAppBar(
          floating: true,
          backgroundColor: Colors.transparent,
          title: RichText(
            text: TextSpan(
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w900),
              children: [
                const TextSpan(text: '⚡ SYSTEM '),
                TextSpan(text: '[LEVEL UP]', style: TextStyle(color: AppTheme.colorPrimary)),
              ],
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined, color: Colors.white60),
              onPressed: () {},
            ),
          ],
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              const SizedBox(height: 8),

              // Banner del usuario
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.glassPanel(neonBorder: true),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              profile.hunterRank == 'E'
                                  ? 'Cazador Rango E'
                                  : 'Cazador Rango ${profile.hunterRank}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.colorXP,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(profile.name, style: Theme.of(context).textTheme.displaySmall),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.colorPrimary, AppTheme.colorSecondary],
                            ),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.colorSecondary.withOpacity(0.4),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Text(
                            'LV ${profile.level}',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Barra XP
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: xpPercent.clamp(0.0, 1.0),
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: const AlwaysStoppedAnimation(AppTheme.colorXP),
                        minHeight: 10,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Experiencia', style: Theme.of(context).textTheme.bodySmall),
                        Text(
                          '${profile.xp} / ${profile.xpForNextLevel} XP',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.colorXP,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Racha y Oro
              Row(
                children: [
                  _metaBox(context, '🔥', 'Racha', '${profile.currentStreak} Días'),
                  const SizedBox(width: 10),
                  _metaBox(context, '🟡', 'Oro', '${profile.gold}'),
                  const SizedBox(width: 10),
                  _metaBox(context, '⚡', 'Energía', '${profile.energy} / 5'),
                ],
              ),

              const SizedBox(height: 20),

              // Estadísticas resumidas
              Text('ATRIBUTOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 2,
              )),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: AppTheme.glassPanel(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _miniStatBox(context, '💪', 'STR', profile.stats['strength'] ?? 10),
                    _miniStatBox(context, '🧠', 'INT', profile.stats['intelligence'] ?? 10),
                    _miniStatBox(context, '⏱️', 'DIS', profile.stats['discipline'] ?? 10),
                    _miniStatBox(context, '🧘', 'SPI', profile.stats['spirit'] ?? 10),
                    _miniStatBox(context, '🛡️', 'DEF', profile.stats['defense'] ?? 10),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Acceso rápido: Tienda y Portales
              Text('ACCESOS RÁPIDOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white60, fontSize: 11, letterSpacing: 2,
              )),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const ShopScreen(),
                        ));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: AppTheme.glassPanel(violetBorder: true),
                        child: Column(
                          children: [
                            const Text('🏪', style: TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text('TIENDA', style: TextStyle(
                              fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.colorSecondary,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        // Navegar al tab RPG (index 2)
                        final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                        homeState?.setState(() => homeState._selectedIndex = 2);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: AppTheme.glassPanel(neonBorder: true),
                        child: Column(
                          children: [
                            const Text('🌀', style: TextStyle(fontSize: 26)),
                            const SizedBox(height: 6),
                            Text('PORTALES', style: TextStyle(
                              fontFamily: 'Orbitron', fontSize: 12, fontWeight: FontWeight.w700,
                              color: AppTheme.colorPrimary,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Misiones del día
              Text('MISIONES DEL DÍA', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.white60,
                fontSize: 11,
                letterSpacing: 2,
              )),
              const SizedBox(height: 10),
              _DailyMissionsWidget(),

              const SizedBox(height: 100),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _metaBox(BuildContext context, String icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: AppTheme.glassPanel(),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
                Text(value, style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStatBox(BuildContext context, String icon, String label, int value) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontFamily: 'Orbitron', fontSize: 9, color: Colors.white38)),
        Text(
          '$value',
          style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

class _DailyMissionsWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: DbHelper.instance.getMissions(
        type: 'diaria',
        date: _todayStr(),
      ),
      builder: (context, snapshot) {
        final missions = snapshot.data ?? [];
        if (missions.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassPanel(),
            child: const Center(
              child: Text(
                'No hay misiones para hoy. Ve a la pestaña Misiones para crear una.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            ),
          );
        }
        return Column(
          children: missions.take(4).map((m) {
            final completed = (m['completed'] as int) == 1;
            final attr = m['attribute'] as String;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: completed
                    ? AppTheme.colorSuccess.withOpacity(0.04)
                    : Colors.white.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border(
                  left: BorderSide(
                    color: completed ? AppTheme.colorSuccess : AppTheme.getAttributeColor(attr),
                    width: 3,
                  ),
                  top: BorderSide(color: Colors.white.withOpacity(0.06)),
                  right: BorderSide(color: Colors.white.withOpacity(0.06)),
                  bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: completed ? AppTheme.colorSuccess : AppTheme.colorPrimary,
                      ),
                      color: completed ? AppTheme.colorSuccess.withOpacity(0.2) : Colors.transparent,
                    ),
                    child: completed
                        ? const Icon(Icons.check, color: AppTheme.colorSuccess, size: 14)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['name'] as String,
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: completed ? Colors.white38 : Colors.white,
                            decoration: completed ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '+${m['reward_xp']} XP',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.colorXP,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${m['duration_minutes']}min',
                              style: const TextStyle(fontSize: 12, color: Colors.white38),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
