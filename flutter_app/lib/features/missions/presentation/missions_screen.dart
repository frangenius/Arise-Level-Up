import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_provider.dart';
import '../../core/database/db_helper.dart';

/// Pantalla de misiones con gestión completa y temporizador de concentración
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Hoy', 'Semana', 'Especiales', 'Creadas'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<List<Map<String, dynamic>>> _loadMissions(int tabIndex) {
    switch (tabIndex) {
      case 0: return DbHelper.instance.getMissions(type: 'diaria', date: _todayStr());
      case 1: return DbHelper.instance.getMissions(type: 'semanal');
      case 2: return DbHelper.instance.getMissions(type: 'especial');
      case 3: return DbHelper.instance.getMissions(type: 'personalizada');
      default: return Future.value([]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('MISIONES'),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppTheme.colorPrimary,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, fontWeight: FontWeight.w700),
          indicatorColor: AppTheme.colorPrimary,
          dividerColor: Colors.white.withOpacity(0.1),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.colorPrimary,
        onPressed: () => _showCreateMissionDialog(),
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tabIdx) {
          return AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              return FutureBuilder<List<Map<String, dynamic>>>(
                future: _loadMissions(tabIdx),
                builder: (ctx, snapshot) {
                  final missions = snapshot.data ?? [];
                  if (missions.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📜', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 12),
                          Text(
                            'Sin misiones registradas aquí.\nCrea una nueva con el botón +',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white38),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: missions.length,
                    itemBuilder: (ctx, i) {
                      final m = missions[i];
                      return _MissionCard(
                        mission: m,
                        onStart: () => _launchFocusTimer(m),
                        onDelete: () => _deleteMission(m['id'] as int),
                      );
                    },
                  );
                },
              );
            },
          );
        }),
      ),
    );
  }

  Future<void> _deleteMission(int id) async {
    await DbHelper.instance.deleteMission(id);
    setState(() {});
  }

  void _launchFocusTimer(Map<String, dynamic> mission) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FocusTimerScreen(mission: mission),
        fullscreenDialog: true,
      ),
    ).then((_) => setState(() {})); // Refrescar al volver
  }

  void _showCreateMissionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0a0f1e),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        side: BorderSide(color: AppTheme.colorPrimary, width: 0.5),
      ),
      builder: (ctx) => _CreateMissionSheet(onSaved: () => setState(() {})),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final Map<String, dynamic> mission;
  final VoidCallback onStart;
  final VoidCallback onDelete;

  const _MissionCard({required this.mission, required this.onStart, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final completed = (mission['completed'] as int) == 1;
    final attr = mission['attribute'] as String;
    final difficulty = mission['difficulty'] as String;
    final attrColor = AppTheme.getAttributeColor(attr);
    final diffColor = AppTheme.getDifficultyColor(difficulty);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: attrColor, width: 3.5),
          top: BorderSide(color: Colors.white.withOpacity(0.06)),
          right: BorderSide(color: Colors.white.withOpacity(0.06)),
          bottom: BorderSide(color: Colors.white.withOpacity(0.06)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${mission['name']} ${completed ? '✓' : ''}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: completed ? Colors.white38 : Colors.white,
                      decoration: completed ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: diffColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: diffColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    difficulty.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: diffColor,
                    ),
                  ),
                ),
              ],
            ),
            if ((mission['description'] ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                mission['description'],
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                _pill('🔋 +${mission['reward_xp']} XP', AppTheme.colorXP),
                const SizedBox(width: 6),
                _pill('🟡 +${mission['reward_gold']}', AppTheme.colorGold),
                const SizedBox(width: 6),
                _pill('⏱️ ${mission['duration_minutes']}min', Colors.white38),
                const Spacer(),
                if (!completed)
                  GestureDetector(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppTheme.colorPrimary, AppTheme.colorSecondary],
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'INICIAR',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline, color: Colors.white24, size: 20),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Text(label, style: TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: color));
  }
}

/// Pantalla de Temporizador de Concentración (Modo Enfoque a pantalla completa)
class FocusTimerScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> mission;
  const FocusTimerScreen({super.key, required this.mission});

  @override
  ConsumerState<FocusTimerScreen> createState() => _FocusTimerScreenState();
}

class _FocusTimerScreenState extends ConsumerState<FocusTimerScreen>
    with SingleTickerProviderStateMixin {
  late int _totalSeconds;
  late int _secondsLeft;
  late AnimationController _ringController;
  bool _isRunning = true;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _totalSeconds = (widget.mission['duration_minutes'] as int) * 60;
    _secondsLeft = _totalSeconds;

    _ringController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _totalSeconds),
    );

    _ringController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _onMissionComplete();
      }
    });

    _ringController.forward();
    _ringController.addListener(() {
      if (mounted) {
        setState(() {
          _secondsLeft = _totalSeconds - (_ringController.value * _totalSeconds).round();
        });
      }
    });
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  Future<void> _onMissionComplete() async {
    setState(() { _completed = true; _isRunning = false; });

    // Marcar misión como completada en la BD
    final updated = Map<String, dynamic>.from(widget.mission);
    updated['completed'] = 1;
    updated['time_spent'] = widget.mission['duration_minutes'];
    updated['date_completed'] = _todayStr();
    await DbHelper.instance.updateMission(updated);

    // Dar recompensas al usuario mediante el notifier
    final notifier = ref.read(userProfileProvider.notifier);
    final leveledUp = await notifier.addXP(widget.mission['reward_xp'] as int);
    await notifier.addGold(widget.mission['reward_gold'] as int);
    
    // Incrementar atributo
    final attr = widget.mission['attribute'] as String;
    final diff = widget.mission['difficulty'] as String;
    int attrGain = 1;
    if (diff == 'dificil') attrGain = 2;
    if (diff == 'extrema') attrGain = 3;
    await notifier.incrementStat(attr, attrGain);
    await notifier.updateStreak(true);
    await notifier.incrementTotalMissions();

    if (leveledUp && mounted) {
      _showLevelUpDialog();
    }
  }

  void _showLevelUpDialog() {
    final profile = ref.read(userProfileProvider);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0a0f1e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.colorPrimary, width: 1.5),
        ),
        title: const Text(
          '⚡ ¡NIVEL AUMENTADO!',
          style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Has alcanzado el Nivel ${profile?.level ?? '?'}.\n\nEl Sistema reconoce tu esfuerzo, Hunter.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar', style: TextStyle(fontFamily: 'Orbitron', color: AppTheme.colorPrimary)),
          ),
        ],
      ),
    );
  }

  void _cancelTimer() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0a0f1e),
        title: const Text('¿Abandonar la Misión?',
            style: TextStyle(fontFamily: 'Orbitron', color: AppTheme.colorError)),
        content: const Text(
          'Si abandonas, la misión fallará y tu racha activa se romperá. '
          'No recibirás recompensas.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continuar Misión', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userProfileProvider.notifier).updateStreak(false);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Abandonar', style: TextStyle(color: AppTheme.colorError)),
          ),
        ],
      ),
    );
  }

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    final progress = 1 - _ringController.value;

    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (widget.mission['name'] as String).toUpperCase(),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 20,
                    shadows: [Shadow(color: AppTheme.colorPrimary.withOpacity(0.5), blurRadius: 10)],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Registrando: ${(widget.mission['attribute'] as String).toUpperCase()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.colorXP,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 50),

                // Ring de progreso circular
                SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 8,
                          backgroundColor: Colors.white.withOpacity(0.04),
                          valueColor: AlwaysStoppedAnimation(
                            _completed ? AppTheme.colorSuccess : AppTheme.colorPrimary,
                          ),
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      _completed
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text('✅', style: TextStyle(fontSize: 40)),
                                const SizedBox(height: 8),
                                Text(
                                  '¡COMPLETADO!',
                                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: AppTheme.colorSuccess,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 42,
                                shadows: [
                                  Shadow(color: AppTheme.colorPrimary.withOpacity(0.4), blurRadius: 20),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                if (_completed)
                  Column(
                    children: [
                      Text(
                        '+${widget.mission['reward_xp']} XP  |  +${widget.mission['reward_gold']} Oro',
                        style: const TextStyle(
                          fontFamily: 'Orbitron',
                          color: AppTheme.colorXP,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: AppTheme.primaryButtonGradient,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 40),
                              child: Text(
                                'RECLAMAR RECOMPENSAS',
                                style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  TextButton(
                    onPressed: _cancelTimer,
                    child: const Text(
                      '❌  Cancelar Misión',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        color: AppTheme.colorError,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet de creación de misiones personalizadas
class _CreateMissionSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _CreateMissionSheet({required this.onSaved});

  @override
  ConsumerState<_CreateMissionSheet> createState() => _CreateMissionSheetState();
}

class _CreateMissionSheetState extends ConsumerState<_CreateMissionSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  String _attribute = 'strength';
  String _difficulty = 'normal';
  int _duration = 15;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;

    final now = DateTime.now();
    final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    int xp = 30, gold = 20;
    switch (_difficulty) {
      case 'muy_facil': xp = 15; gold = 10; break;
      case 'facil': xp = 30; gold = 20; break;
      case 'normal': xp = 60; gold = 45; break;
      case 'dificil': xp = 100; gold = 80; break;
      case 'extrema': xp = 160; gold = 130; break;
    }

    await DbHelper.instance.insertMission({
      'name': _nameCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'type': 'personalizada',
      'difficulty': _difficulty,
      'duration_minutes': _duration,
      'attribute': _attribute,
      'reward_xp': xp,
      'reward_gold': gold,
      'completed': 0,
      'time_spent': 0,
      'date_created': todayStr,
    });

    widget.onSaved();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('NUEVA MISIÓN',
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'NOMBRE'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'DESCRIPCIÓN'),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _attribute,
                  dropdownColor: const Color(0xFF0a0f1e),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'ATRIBUTO'),
                  items: const [
                    DropdownMenuItem(value: 'strength', child: Text('💪 Fuerza')),
                    DropdownMenuItem(value: 'intelligence', child: Text('🧠 Inteligencia')),
                    DropdownMenuItem(value: 'discipline', child: Text('⏱️ Disciplina')),
                    DropdownMenuItem(value: 'spirit', child: Text('🧘 Espíritu')),
                    DropdownMenuItem(value: 'defense', child: Text('🛡️ Defensa')),
                  ],
                  onChanged: (v) => setState(() => _attribute = v!),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _difficulty,
                  dropdownColor: const Color(0xFF0a0f1e),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'DIFICULTAD'),
                  items: const [
                    DropdownMenuItem(value: 'muy_facil', child: Text('Muy Fácil')),
                    DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                    DropdownMenuItem(value: 'extrema', child: Text('Extrema')),
                  ],
                  onChanged: (v) => setState(() => _difficulty = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('DURACIÓN: $_duration minutos',
              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: Colors.white60)),
          Slider(
            value: _duration.toDouble(),
            min: 5,
            max: 120,
            divisions: 23,
            activeColor: AppTheme.colorPrimary,
            inactiveColor: Colors.white.withOpacity(0.1),
            onChanged: (v) => setState(() => _duration = v.round()),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: AppTheme.primaryButtonGradient,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _save,
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('💾  REGISTRAR MISIÓN',
                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
