import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_provider.dart';
import '../../../core/database/db_helper.dart';

// ========================================================
// MODELOS DE DATOS RPG
// ========================================================

class Enemy {
  final String name;
  final String icon;
  final int hp;
  final int maxHp;
  final int attack;
  final int defense;
  final String rank;
  final List<EnemySkill> skills;

  const Enemy({
    required this.name,
    required this.icon,
    required this.hp,
    required this.maxHp,
    required this.attack,
    required this.defense,
    required this.rank,
    this.skills = const [],
  });

  Enemy copyWith({int? hp}) => Enemy(
    name: name, icon: icon, hp: hp ?? this.hp, maxHp: maxHp,
    attack: attack, defense: defense, rank: rank, skills: skills,
  );
}

class EnemySkill {
  final String name;
  final double damageMultiplier;
  final String? statusEffect; // 'poison' | 'stun' | 'bleed'
  final double statusChance;

  const EnemySkill({
    required this.name,
    this.damageMultiplier = 1.0,
    this.statusEffect,
    this.statusChance = 0.3,
  });
}

class LootItem {
  final String name;
  final String icon;
  final String rarity;
  final String type;
  final int goldValue;

  const LootItem({
    required this.name,
    required this.icon,
    required this.rarity,
    required this.type,
    required this.goldValue,
  });
}

class CombatState {
  final int playerHp;
  final int playerMaxHp;
  final int playerMana;
  final int playerMaxMana;
  final int enemyIndex;
  final int stage;
  final List<Enemy> enemies;
  final List<String> log;
  final String? playerStatus; // 'poison' | 'stun' | 'bleed' | null
  final int statusTurns;
  final bool isPlayerTurn;
  final bool isCombatOver;
  final bool isVictory;
  final List<LootItem> loot;
  final int xpGained;
  final int goldGained;

  const CombatState({
    required this.playerHp,
    required this.playerMaxHp,
    this.playerMana = 50,
    this.playerMaxMana = 50,
    this.enemyIndex = 0,
    this.stage = 1,
    this.enemies = const [],
    this.log = const [],
    this.playerStatus,
    this.statusTurns = 0,
    this.isPlayerTurn = true,
    this.isCombatOver = false,
    this.isVictory = false,
    this.loot = const [],
    this.xpGained = 0,
    this.goldGained = 0,
  });

  CombatState copyWith({
    int? playerHp, int? playerMaxHp, int? playerMana, int? playerMaxMana,
    int? enemyIndex, int? stage, List<Enemy>? enemies, List<String>? log,
    String? playerStatus, int? statusTurns, bool? isPlayerTurn,
    bool? isCombatOver, bool? isVictory, List<LootItem>? loot,
    int? xpGained, int? goldGained, bool clearStatus = false,
  }) => CombatState(
    playerHp: playerHp ?? this.playerHp,
    playerMaxHp: playerMaxHp ?? this.playerMaxHp,
    playerMana: playerMana ?? this.playerMana,
    playerMaxMana: playerMaxMana ?? this.playerMaxMana,
    enemyIndex: enemyIndex ?? this.enemyIndex,
    stage: stage ?? this.stage,
    enemies: enemies ?? this.enemies,
    log: log ?? this.log,
    playerStatus: clearStatus ? null : (playerStatus ?? this.playerStatus),
    statusTurns: clearStatus ? 0 : (statusTurns ?? this.statusTurns),
    isPlayerTurn: isPlayerTurn ?? this.isPlayerTurn,
    isCombatOver: isCombatOver ?? this.isCombatOver,
    isVictory: isVictory ?? this.isVictory,
    loot: loot ?? this.loot,
    xpGained: xpGained ?? this.xpGained,
    goldGained: goldGained ?? this.goldGained,
  );

  Enemy? get currentEnemy =>
      enemies.isNotEmpty && enemyIndex < enemies.length ? enemies[enemyIndex] : null;
}

// ========================================================
// PORTAL Y BESTIARY DATA
// ========================================================

class PortalData {
  static final _rng = Random();

  static const ranks = ['E', 'D', 'C', 'B', 'A', 'S'];

  static const rankColors = {
    'E': AppTheme.colorSuccess,
    'D': AppTheme.colorPrimary,
    'C': AppTheme.colorWarning,
    'B': AppTheme.colorError,
    'A': AppTheme.colorSecondary,
    'S': AppTheme.colorGold,
  };

  static const rankRequiredLevel = {
    'E': 1, 'D': 10, 'C': 25, 'B': 50, 'A': 75, 'S': 100,
  };

  static List<Enemy> generateEnemies(String rank) {
    switch (rank) {
      case 'E':
        return [
          Enemy(name: 'Goblin', icon: '👺', hp: 40, maxHp: 40, attack: 8, defense: 3, rank: rank,
            skills: [const EnemySkill(name: 'Mordisco', damageMultiplier: 1.2)]),
          Enemy(name: 'Araña Oscura', icon: '🕷️', hp: 35, maxHp: 35, attack: 10, defense: 2, rank: rank,
            skills: [const EnemySkill(name: 'Veneno', damageMultiplier: 0.8, statusEffect: 'poison', statusChance: 0.5)]),
          Enemy(name: 'Lobo Sombrío', icon: '🐺', hp: 55, maxHp: 55, attack: 12, defense: 5, rank: rank,
            skills: [const EnemySkill(name: 'Embestida', damageMultiplier: 1.5)]),
        ];
      case 'D':
        return [
          Enemy(name: 'Esqueleto Guerrero', icon: '💀', hp: 70, maxHp: 70, attack: 15, defense: 8, rank: rank,
            skills: [const EnemySkill(name: 'Tajo Óseo', damageMultiplier: 1.3)]),
          Enemy(name: 'Hechicero Oscuro', icon: '🧙', hp: 50, maxHp: 50, attack: 20, defense: 5, rank: rank,
            skills: [const EnemySkill(name: 'Bola de Sombra', damageMultiplier: 1.4, statusEffect: 'stun', statusChance: 0.25)]),
          Enemy(name: 'Orco Berserker', icon: '👹', hp: 100, maxHp: 100, attack: 18, defense: 10, rank: rank,
            skills: [const EnemySkill(name: 'Furia', damageMultiplier: 1.8)]),
        ];
      case 'C':
        return [
          Enemy(name: 'Caballero Maldito', icon: '🗡️', hp: 130, maxHp: 130, attack: 25, defense: 15, rank: rank,
            skills: [const EnemySkill(name: 'Corte Maldito', damageMultiplier: 1.4, statusEffect: 'bleed', statusChance: 0.4)]),
          Enemy(name: 'Golem de Piedra', icon: '🪨', hp: 200, maxHp: 200, attack: 20, defense: 25, rank: rank,
            skills: [const EnemySkill(name: 'Aplastamiento', damageMultiplier: 1.6)]),
          Enemy(name: 'Liche', icon: '☠️', hp: 120, maxHp: 120, attack: 30, defense: 12, rank: rank,
            skills: [
              const EnemySkill(name: 'Necrosis', damageMultiplier: 1.5, statusEffect: 'poison', statusChance: 0.6),
              const EnemySkill(name: 'Drenar Vida', damageMultiplier: 1.2),
            ]),
        ];
      case 'B':
        return [
          Enemy(name: 'Demonio Menor', icon: '😈', hp: 250, maxHp: 250, attack: 35, defense: 20, rank: rank,
            skills: [const EnemySkill(name: 'Llama Infernal', damageMultiplier: 1.6, statusEffect: 'bleed', statusChance: 0.3)]),
          Enemy(name: 'Wyrm Venenoso', icon: '🐉', hp: 300, maxHp: 300, attack: 30, defense: 30, rank: rank,
            skills: [const EnemySkill(name: 'Aliento Tóxico', damageMultiplier: 1.3, statusEffect: 'poison', statusChance: 0.7)]),
          Enemy(name: 'General Oscuro', icon: '⚔️', hp: 350, maxHp: 350, attack: 40, defense: 25, rank: rank,
            skills: [
              const EnemySkill(name: 'Ejecución', damageMultiplier: 2.0),
              const EnemySkill(name: 'Aturdimiento', damageMultiplier: 1.0, statusEffect: 'stun', statusChance: 0.5),
            ]),
        ];
      case 'A':
        return [
          Enemy(name: 'Fénix Carmesí', icon: '🔥', hp: 400, maxHp: 400, attack: 45, defense: 30, rank: rank,
            skills: [const EnemySkill(name: 'Inmolación', damageMultiplier: 1.8, statusEffect: 'bleed', statusChance: 0.5)]),
          Enemy(name: 'Titán de Hielo', icon: '🧊', hp: 500, maxHp: 500, attack: 40, defense: 40, rank: rank,
            skills: [const EnemySkill(name: 'Ventisca', damageMultiplier: 1.5, statusEffect: 'stun', statusChance: 0.4)]),
          Enemy(name: 'Señor de las Sombras', icon: '🌑', hp: 450, maxHp: 450, attack: 55, defense: 35, rank: rank,
            skills: [
              const EnemySkill(name: 'Abismo Eterno', damageMultiplier: 2.2),
              const EnemySkill(name: 'Drenar Alma', damageMultiplier: 1.4, statusEffect: 'poison', statusChance: 0.6),
            ]),
        ];
      case 'S':
        return [
          Enemy(name: 'Igris, Caballero Sangriento', icon: '🩸', hp: 600, maxHp: 600, attack: 60, defense: 45, rank: rank,
            skills: [
              const EnemySkill(name: 'Tajo de Sangre', damageMultiplier: 1.8, statusEffect: 'bleed', statusChance: 0.6),
              const EnemySkill(name: 'Danza de Espadas', damageMultiplier: 2.5),
            ]),
          Enemy(name: 'Beru, Rey Hormiga', icon: '🐜', hp: 800, maxHp: 800, attack: 55, defense: 50, rank: rank,
            skills: [
              const EnemySkill(name: 'Mandíbula Letal', damageMultiplier: 2.0),
              const EnemySkill(name: 'Veneno Mortal', damageMultiplier: 1.5, statusEffect: 'poison', statusChance: 0.8),
            ]),
          Enemy(name: 'Dragón Azul Kamish', icon: '🐲', hp: 1200, maxHp: 1200, attack: 75, defense: 60, rank: rank,
            skills: [
              const EnemySkill(name: 'Aliento de Dragón', damageMultiplier: 2.5, statusEffect: 'bleed', statusChance: 0.7),
              const EnemySkill(name: 'Cataclismo', damageMultiplier: 3.0),
            ]),
        ];
      default:
        return [];
    }
  }

  static List<LootItem> generateLoot(String rank) {
    final lootTable = <LootItem>[];
    final roll = _rng.nextDouble();

    // Siempre da oro
    final goldBase = {'E': 50, 'D': 100, 'C': 200, 'B': 400, 'A': 750, 'S': 1500}[rank] ?? 50;

    // Posibilidad de objetos según rango
    if (roll < 0.6) {
      lootTable.add(LootItem(name: 'Poción de Vida', icon: '❤️', rarity: 'comun', type: 'consumible', goldValue: goldBase));
    }
    if (roll < 0.35) {
      final rarities = {'E': 'comun', 'D': 'poco_comun', 'C': 'raro', 'B': 'epico', 'A': 'legendario', 'S': 'mitico'};
      lootTable.add(LootItem(
        name: _randomWeapon(rank),
        icon: _randomWeaponIcon(),
        rarity: rarities[rank] ?? 'comun',
        type: 'arma',
        goldValue: goldBase,
      ));
    }
    if (roll < 0.15 && (rank == 'A' || rank == 'S')) {
      lootTable.add(LootItem(name: 'Fragmento del Monarca', icon: '💎', rarity: 'legendario', type: 'material', goldValue: goldBase * 2));
    }

    return lootTable;
  }

  static String _randomWeapon(String rank) {
    final weapons = {
      'E': ['Daga de Cobre', 'Espada Oxidada', 'Arco Simple'],
      'D': ['Espada de Hierro', 'Hacha de Batalla', 'Bastón Arcano'],
      'C': ['Espada de Plata', 'Lanza Encantada', 'Cetro del Mago'],
      'B': ['Hoja del Abismo', 'Martillo Rúnico', 'Grimorio Oscuro'],
      'A': ['Filo del Destino', 'Lanza del Relámpago', 'Orbe Celestial'],
      'S': ['Daga de las Sombras', 'Espada del Monarca', 'Corona del Primer Hunter'],
    };
    final list = weapons[rank] ?? weapons['E']!;
    return list[_rng.nextInt(list.length)];
  }

  static String _randomWeaponIcon() {
    const icons = ['⚔️', '🗡️', '🔱', '🏹', '🪄', '🔮'];
    return icons[_rng.nextInt(icons.length)];
  }

  static int xpReward(String rank) => {'E': 80, 'D': 200, 'C': 450, 'B': 900, 'A': 1800, 'S': 4000}[rank] ?? 80;
  static int goldReward(String rank) => {'E': 100, 'D': 250, 'C': 500, 'B': 1000, 'A': 2000, 'S': 5000}[rank] ?? 100;
}

// ========================================================
// PANTALLA PRINCIPAL RPG
// ========================================================

class RPGScreen extends ConsumerWidget {
  const RPGScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) return const SizedBox();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('PORTALES')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Energía disponible
            Container(
              padding: const EdgeInsets.all(14),
              decoration: AppTheme.glassPanel(neonBorder: true),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Energía de Portal', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (i) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(6),
                                color: i < profile.energy
                                    ? AppTheme.colorPrimary.withOpacity(0.3)
                                    : Colors.white.withOpacity(0.03),
                                border: Border.all(
                                  color: i < profile.energy ? AppTheme.colorPrimary : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  i < profile.energy ? '⚡' : '',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${profile.energy}/5',
                      style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.colorPrimary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text('SELECCIONA UN PORTAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white60, fontSize: 11, letterSpacing: 2,
            )),
            const SizedBox(height: 10),

            // Lista de portales
            ...PortalData.ranks.map((rank) {
              final requiredLevel = PortalData.rankRequiredLevel[rank] ?? 1;
              final isLocked = profile.level < requiredLevel;
              final color = PortalData.rankColors[rank] ?? AppTheme.colorPrimary;
              final hasEnergy = profile.energy > 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (isLocked || !hasEnergy) ? null : () => _enterPortal(context, ref, rank),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isLocked
                            ? Colors.white.withOpacity(0.01)
                            : color.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isLocked ? Colors.white10 : color.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 50, height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: isLocked
                                  ? null
                                  : LinearGradient(
                                      colors: [color.withOpacity(0.3), color.withOpacity(0.1)],
                                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                                    ),
                              color: isLocked ? Colors.white.withOpacity(0.03) : null,
                            ),
                            child: Center(
                              child: Text(
                                isLocked ? '🔒' : '🌀',
                                style: TextStyle(fontSize: isLocked ? 20 : 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Portal Rango $rank',
                                  style: TextStyle(
                                    fontFamily: 'Orbitron', fontSize: 15, fontWeight: FontWeight.w700,
                                    color: isLocked ? Colors.white24 : color,
                                  ),
                                ),
                                Text(
                                  isLocked
                                      ? 'Requiere Nivel $requiredLevel'
                                      : '3 Etapas • ${PortalData.xpReward(rank)} XP • ${PortalData.goldReward(rank)} Oro',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isLocked ? Colors.white16 : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isLocked)
                            Icon(Icons.chevron_right, color: color.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _enterPortal(BuildContext context, WidgetRef ref, String rank) {
    final profile = ref.read(userProfileProvider);
    if (profile == null || profile.energy < 1) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0a0f1e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: PortalData.rankColors[rank] ?? AppTheme.colorPrimary, width: 1),
        ),
        title: Text(
          '🌀 Portal Rango $rank',
          style: TextStyle(
            fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w900,
            color: PortalData.rankColors[rank],
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '¿Deseas entrar al Portal de Rango $rank?\n\n'
          '• 3 etapas de combate por turnos\n'
          '• Costo: 1 Energía\n'
          '• Recompensa: ${PortalData.xpReward(rank)} XP + ${PortalData.goldReward(rank)} Oro + Loot',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userProfileProvider.notifier).spendEnergy();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CombatScreen(rank: rank),
                    fullscreenDialog: true,
                  ),
                );
              }
            },
            child: Text(
              '⚡ ENTRAR',
              style: TextStyle(
                fontFamily: 'Orbitron', fontWeight: FontWeight.w900,
                color: PortalData.rankColors[rank],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================================
// PANTALLA DE COMBATE POR TURNOS
// ========================================================

class CombatScreen extends ConsumerStatefulWidget {
  final String rank;
  const CombatScreen({super.key, required this.rank});

  @override
  ConsumerState<CombatScreen> createState() => _CombatScreenState();
}

class _CombatScreenState extends ConsumerState<CombatScreen>
    with TickerProviderStateMixin {
  late CombatState _combat;
  final _rng = Random();
  bool _animatingAttack = false;

  late AnimationController _shakeController;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween(begin: 0.0, end: 8.0).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
    _shakeController.addStatusListener((s) { if (s == AnimationStatus.completed) _shakeController.reset(); });

    _initCombat();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _initCombat() {
    final profile = ref.read(userProfileProvider);
    final str = profile?.stats['strength'] ?? 10;
    final def = profile?.stats['defense'] ?? 10;
    final spi = profile?.stats['spirit'] ?? 10;
    final baseHp = 80 + (def * 3) + (str * 1);
    final baseMana = 30 + (spi * 2);

    final enemies = PortalData.generateEnemies(widget.rank);

    setState(() {
      _combat = CombatState(
        playerHp: baseHp,
        playerMaxHp: baseHp,
        playerMana: baseMana,
        playerMaxMana: baseMana,
        enemies: enemies,
        log: ['⚔️ ¡Portal Rango ${widget.rank} abierto! Etapa 1/3'],
      );
    });
  }

  int _calcPlayerDamage({double multiplier = 1.0}) {
    final profile = ref.read(userProfileProvider);
    final str = profile?.stats['strength'] ?? 10;
    final baseDmg = (str * 1.5 + 5).round();
    final variance = (_rng.nextDouble() * 0.3 - 0.15);
    return ((baseDmg * multiplier) * (1 + variance)).round().clamp(1, 9999);
  }

  int _calcEnemyDamage(Enemy enemy, {double multiplier = 1.0}) {
    final profile = ref.read(userProfileProvider);
    final def = profile?.stats['defense'] ?? 10;
    final rawDmg = enemy.attack * multiplier;
    final reduction = def * 0.5;
    final variance = (_rng.nextDouble() * 0.25 - 0.1);
    return ((rawDmg - reduction) * (1 + variance)).round().clamp(1, 9999);
  }

  void _playerAttack() {
    if (_animatingAttack || !_combat.isPlayerTurn || _combat.isCombatOver) return;
    _doPlayerAction('Ataque Normal', _calcPlayerDamage());
  }

  void _playerHeavyAttack() {
    if (_animatingAttack || !_combat.isPlayerTurn || _combat.isCombatOver) return;
    if (_combat.playerMana < 15) {
      _addLog('⚠️ ¡Maná insuficiente! (Necesitas 15)');
      return;
    }
    _doPlayerAction('Golpe Devastador', _calcPlayerDamage(multiplier: 2.0), manaCost: 15);
  }

  void _playerHeal() {
    if (_animatingAttack || !_combat.isPlayerTurn || _combat.isCombatOver) return;
    if (_combat.playerMana < 20) {
      _addLog('⚠️ ¡Maná insuficiente! (Necesitas 20)');
      return;
    }
    final healAmount = (_combat.playerMaxHp * 0.3).round();
    final newHp = (_combat.playerHp + healAmount).clamp(0, _combat.playerMaxHp);
    setState(() {
      _combat = _combat.copyWith(
        playerHp: newHp,
        playerMana: _combat.playerMana - 20,
        isPlayerTurn: false,
        log: [..._combat.log, '💚 Curación: +$healAmount HP (Maná: -20)'],
      );
    });
    Future.delayed(const Duration(milliseconds: 800), _enemyTurn);
  }

  void _doPlayerAction(String attackName, int damage, {int manaCost = 0}) {
    setState(() => _animatingAttack = true);
    _shakeController.forward();

    final enemy = _combat.currentEnemy!;
    final newEnemyHp = (enemy.hp - damage).clamp(0, enemy.maxHp);
    final updatedEnemies = List<Enemy>.from(_combat.enemies);
    updatedEnemies[_combat.enemyIndex] = enemy.copyWith(hp: newEnemyHp);

    final newLog = List<String>.from(_combat.log);
    newLog.add('⚔️ $attackName → ${enemy.name}: -$damage HP');

    int newMana = _combat.playerMana - manaCost;

    setState(() {
      _combat = _combat.copyWith(
        enemies: updatedEnemies,
        playerMana: newMana,
        log: newLog,
        isPlayerTurn: false,
      );
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() => _animatingAttack = false);
      if (newEnemyHp <= 0) {
        _onEnemyDefeated();
      } else {
        _enemyTurn();
      }
    });
  }

  void _onEnemyDefeated() {
    final enemy = _combat.currentEnemy!;
    _addLog('💀 ${enemy.name} derrotado!');

    final nextIndex = _combat.enemyIndex + 1;
    if (nextIndex >= _combat.enemies.length) {
      _onVictory();
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        setState(() {
          _combat = _combat.copyWith(
            enemyIndex: nextIndex,
            stage: _combat.stage + 1,
            isPlayerTurn: true,
            clearStatus: true,
            log: [..._combat.log, '── Etapa ${_combat.stage + 1}/3 ──'],
          );
        });
      });
    }
  }

  void _onVictory() {
    final xp = PortalData.xpReward(widget.rank);
    final gold = PortalData.goldReward(widget.rank);
    final loot = PortalData.generateLoot(widget.rank);

    setState(() {
      _combat = _combat.copyWith(
        isCombatOver: true,
        isVictory: true,
        xpGained: xp,
        goldGained: gold,
        loot: loot,
        log: [..._combat.log, '🏆 ¡VICTORIA! Portal Rango ${widget.rank} completado!'],
      );
    });
  }

  void _enemyTurn() {
    if (_combat.isCombatOver) return;

    // Aplicar estados al jugador
    int statusDamage = 0;
    if (_combat.playerStatus == 'poison') {
      statusDamage = (_combat.playerMaxHp * 0.05).round();
      _addLog('🟢 Veneno: -$statusDamage HP');
    } else if (_combat.playerStatus == 'bleed') {
      statusDamage = (_combat.playerMaxHp * 0.04).round();
      _addLog('🩸 Sangrado: -$statusDamage HP');
    } else if (_combat.playerStatus == 'stun') {
      final newTurns = _combat.statusTurns - 1;
      setState(() {
        _combat = _combat.copyWith(
          isPlayerTurn: true,
          statusTurns: newTurns,
          clearStatus: newTurns <= 0,
          log: [..._combat.log, '💫 Aturdido: pierdes el turno'],
        );
      });
      return;
    }

    final newHpAfterStatus = (_combat.playerHp - statusDamage).clamp(0, _combat.playerMaxHp);
    if (newHpAfterStatus <= 0) {
      setState(() {
        _combat = _combat.copyWith(playerHp: 0, isCombatOver: true, isVictory: false,
          log: [..._combat.log, '☠️ Has sido derrotado...']);
      });
      return;
    }

    final enemy = _combat.currentEnemy!;
    final skill = enemy.skills[_rng.nextInt(enemy.skills.length)];
    final damage = _calcEnemyDamage(enemy, multiplier: skill.damageMultiplier);
    final newHp = (newHpAfterStatus - damage).clamp(0, _combat.playerMaxHp);

    String? newStatus = _combat.playerStatus;
    int newStatusTurns = _combat.statusTurns > 0 ? _combat.statusTurns - 1 : 0;
    bool clearStatus = false;

    if (skill.statusEffect != null && _rng.nextDouble() < skill.statusChance && _combat.playerStatus == null) {
      newStatus = skill.statusEffect;
      newStatusTurns = skill.statusEffect == 'stun' ? 1 : 3;
      final statusIcons = {'poison': '🟢 Envenenado', 'bleed': '🩸 Sangrado', 'stun': '💫 Aturdido'};
      _addLog('${statusIcons[skill.statusEffect]} aplicado!');
    }

    if (newStatusTurns <= 0 && _combat.playerStatus != null) clearStatus = true;

    final newLog = List<String>.from(_combat.log);
    newLog.add('👹 ${enemy.name} usa ${skill.name}: -$damage HP');

    setState(() {
      _combat = _combat.copyWith(
        playerHp: newHp,
        playerStatus: clearStatus ? null : newStatus,
        statusTurns: clearStatus ? 0 : newStatusTurns,
        isPlayerTurn: true,
        log: newLog,
        isCombatOver: newHp <= 0,
        isVictory: false,
        clearStatus: clearStatus,
      );
    });

    if (newHp <= 0) {
      _addLog('☠️ Has caído en combate...');
    }
  }

  void _addLog(String msg) {
    setState(() {
      _combat = _combat.copyWith(log: [..._combat.log, msg]);
    });
  }

  Future<void> _claimRewards() async {
    if (!_combat.isVictory) {
      if (mounted) Navigator.pop(context);
      return;
    }

    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.addXP(_combat.xpGained);
    await notifier.addGold(_combat.goldGained);
    await notifier.incrementStat('strength', 1);
    await notifier.incrementStat('defense', 1);

    // Guardar loot en inventario
    for (final item in _combat.loot) {
      await DbHelper.instance.insertInventoryItem({
        'item_id': '${item.name.toLowerCase().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}',
        'name': item.name,
        'type': item.type,
        'rarity': item.rarity,
        'icon': item.icon,
        'description': 'Obtenido en Portal Rango ${widget.rank}',
        'quantity': 1,
        'equipped': 0,
        'upgrade_level': 0,
        'stats_json': '{}',
      });
    }

    // Registrar portal
    await DbHelper.instance.insertPortalRun({
      'portal_rank': widget.rank,
      'date_started': DateTime.now().toIso8601String(),
      'date_completed': DateTime.now().toIso8601String(),
      'result': 'victory',
      'stages_completed': 3,
      'xp_gained': _combat.xpGained,
      'gold_gained': _combat.goldGained,
      'loot_json': _combat.loot.map((l) => l.name).join(','),
    });

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final enemy = _combat.currentEnemy;
    final rankColor = PortalData.rankColors[widget.rank] ?? AppTheme.colorPrimary;

    return Scaffold(
      body: Container(
        decoration: AppTheme.mainGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Header de portal
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: rankColor.withOpacity(0.06),
                  border: Border(bottom: BorderSide(color: rankColor.withOpacity(0.2))),
                ),
                child: Row(
                  children: [
                    Text('🌀', style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'Portal Rango ${widget.rank} • Etapa ${_combat.stage}/3',
                      style: TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w700, color: rankColor),
                    ),
                    const Spacer(),
                    if (!_combat.isCombatOver)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text('Huir ❌', style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Colors.white38)),
                      ),
                  ],
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Enemigo
                      if (enemy != null && !_combat.isCombatOver) ...[
                        AnimatedBuilder(
                          animation: _shakeController,
                          builder: (_, child) => Transform.translate(
                            offset: Offset(_shakeAnim.value * sin(_shakeController.value * pi * 4), 0),
                            child: child,
                          ),
                          child: Column(
                            children: [
                              Text(enemy.icon, style: const TextStyle(fontSize: 60)),
                              const SizedBox(height: 6),
                              Text(enemy.name, style: TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: rankColor)),
                              const SizedBox(height: 8),
                              // HP Bar del enemigo
                              SizedBox(
                                width: 200,
                                child: Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: (enemy.hp / enemy.maxHp).clamp(0.0, 1.0),
                                        backgroundColor: Colors.white.withOpacity(0.05),
                                        valueColor: AlwaysStoppedAnimation(
                                          enemy.hp / enemy.maxHp > 0.5 ? AppTheme.colorError : AppTheme.colorWarning,
                                        ),
                                        minHeight: 8,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${enemy.hp} / ${enemy.maxHp} HP', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: Colors.white54)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Victoria / Derrota
                      if (_combat.isCombatOver)
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _combat.isVictory ? '🏆' : '☠️',
                                style: const TextStyle(fontSize: 60),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _combat.isVictory ? '¡VICTORIA!' : 'DERROTA',
                                style: TextStyle(
                                  fontFamily: 'Orbitron', fontSize: 24, fontWeight: FontWeight.w900,
                                  color: _combat.isVictory ? AppTheme.colorGold : AppTheme.colorError,
                                ),
                              ),
                              if (_combat.isVictory) ...[
                                const SizedBox(height: 16),
                                Text(
                                  '+${_combat.xpGained} XP  •  +${_combat.goldGained} Oro',
                                  style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, color: AppTheme.colorXP),
                                ),
                                if (_combat.loot.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Text('Botín Obtenido:', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8, runSpacing: 6,
                                    children: _combat.loot.map((l) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppTheme.getRarityColor(l.rarity).withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: AppTheme.getRarityColor(l.rarity).withOpacity(0.3)),
                                      ),
                                      child: Text(
                                        '${l.icon} ${l.name}',
                                        style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppTheme.getRarityColor(l.rarity)),
                                      ),
                                    )).toList(),
                                  ),
                                ],
                              ],
                              const SizedBox(height: 24),
                              Container(
                                decoration: AppTheme.primaryButtonGradient,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _claimRewards,
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                                      child: Text(
                                        _combat.isVictory ? 'RECLAMAR RECOMPENSAS' : 'SALIR',
                                        style: const TextStyle(fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // HP/Mana del jugador
                      if (!_combat.isCombatOver) ...[
                        const Spacer(),

                        // Log de combate
                        Container(
                          height: 100,
                          padding: const EdgeInsets.all(10),
                          decoration: AppTheme.glassPanel(),
                          child: ListView.builder(
                            reverse: true,
                            itemCount: _combat.log.length,
                            itemBuilder: (_, i) {
                              final idx = _combat.log.length - 1 - i;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  _combat.log[idx],
                                  style: TextStyle(fontSize: 12, color: i == 0 ? Colors.white : Colors.white38),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Barras HP/MP
                        Row(
                          children: [
                            const Text('❤️', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_combat.playerHp / _combat.playerMaxHp).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.colorSuccess),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${_combat.playerHp}/${_combat.playerMaxHp}', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Colors.white60)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Text('💧', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (_combat.playerMana / _combat.playerMaxMana).clamp(0.0, 1.0),
                                  backgroundColor: Colors.white.withOpacity(0.05),
                                  valueColor: const AlwaysStoppedAnimation(AppTheme.colorPrimary),
                                  minHeight: 10,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${_combat.playerMana}/${_combat.playerMaxMana}', style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: Colors.white60)),
                          ],
                        ),

                        if (_combat.playerStatus != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.colorWarning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.colorWarning.withOpacity(0.3)),
                            ),
                            child: Text(
                              '⚠️ ${_combat.playerStatus!.toUpperCase()} (${_combat.statusTurns} turnos)',
                              style: const TextStyle(fontFamily: 'Orbitron', fontSize: 10, color: AppTheme.colorWarning),
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Botones de acción
                        if (_combat.isPlayerTurn)
                          Row(
                            children: [
                              Expanded(child: _actionBtn('⚔️ Atacar', AppTheme.colorError, _playerAttack)),
                              const SizedBox(width: 8),
                              Expanded(child: _actionBtn('💥 Devastar\n(15 MP)', AppTheme.colorSecondary, _playerHeavyAttack)),
                              const SizedBox(width: 8),
                              Expanded(child: _actionBtn('💚 Curar\n(20 MP)', AppTheme.colorSuccess, _playerHeal)),
                            ],
                          )
                        else
                          const Center(
                            child: Text('Turno del enemigo...', style: TextStyle(fontFamily: 'Orbitron', fontSize: 12, color: Colors.white38)),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Orbitron', fontSize: 11, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ),
      ),
    );
  }
}
