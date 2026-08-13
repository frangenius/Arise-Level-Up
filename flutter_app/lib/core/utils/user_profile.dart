import 'package:hive/hive.dart';

/// Modelo del perfil del usuario almacenado en Hive (acceso instantáneo)
/// Campos enriquecidos, matching con el diseño del sistema.
class UserProfile {
  final String name;
  final String selectedAvatar; // 'knight' | 'mage'
  final String userClass;      // 'guerrero' | 'estratega' | 'desafiante' | 'explorador'
  final int level;
  final int xp;
  final int gold;
  final int currentStreak;
  final int maxStreak;
  final int daysActive;
  final int energy;            // 0-5 (energía semanal de portales)
  final String lastLoginDate;  // YYYY-MM-DD
  final String createdDate;    // YYYY-MM-DD
  final String activeTitle;
  final List<String> unlockedTitles;
  final List<String> equippedItems; // IDs de items equipados
  final List<String> companions;    // IDs de compañeros activos
  final Map<String, int> stats;     // { strength, intelligence, discipline, spirit, defense }
  final Map<String, bool> settings;
  final int totalMissionsCompleted;
  final int totalTimeTrained;       // minutos totales de entrenamiento

  const UserProfile({
    required this.name,
    this.selectedAvatar = 'knight',
    this.userClass = 'guerrero',
    this.level = 1,
    this.xp = 0,
    this.gold = 300,
    this.currentStreak = 0,
    this.maxStreak = 0,
    this.daysActive = 1,
    this.energy = 5,
    this.lastLoginDate = '',
    this.createdDate = '',
    this.activeTitle = 'principiante',
    this.unlockedTitles = const ['principiante'],
    this.equippedItems = const ['espada_entrenamiento', 'armadura_entrenamiento'],
    this.companions = const [],
    this.stats = const {
      'strength': 10,
      'intelligence': 10,
      'discipline': 10,
      'spirit': 10,
      'defense': 10,
    },
    this.settings = const {
      'scalingEnabled': true,
      'pauseAllowed': false,
    },
    this.totalMissionsCompleted = 0,
    this.totalTimeTrained = 0,
  });

  UserProfile copyWith({
    String? name,
    String? selectedAvatar,
    String? userClass,
    int? level,
    int? xp,
    int? gold,
    int? currentStreak,
    int? maxStreak,
    int? daysActive,
    int? energy,
    String? lastLoginDate,
    String? createdDate,
    String? activeTitle,
    List<String>? unlockedTitles,
    List<String>? equippedItems,
    List<String>? companions,
    Map<String, int>? stats,
    Map<String, bool>? settings,
    int? totalMissionsCompleted,
    int? totalTimeTrained,
  }) {
    return UserProfile(
      name: name ?? this.name,
      selectedAvatar: selectedAvatar ?? this.selectedAvatar,
      userClass: userClass ?? this.userClass,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      gold: gold ?? this.gold,
      currentStreak: currentStreak ?? this.currentStreak,
      maxStreak: maxStreak ?? this.maxStreak,
      daysActive: daysActive ?? this.daysActive,
      energy: energy ?? this.energy,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      createdDate: createdDate ?? this.createdDate,
      activeTitle: activeTitle ?? this.activeTitle,
      unlockedTitles: unlockedTitles ?? this.unlockedTitles,
      equippedItems: equippedItems ?? this.equippedItems,
      companions: companions ?? this.companions,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      totalMissionsCompleted: totalMissionsCompleted ?? this.totalMissionsCompleted,
      totalTimeTrained: totalTimeTrained ?? this.totalTimeTrained,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'selectedAvatar': selectedAvatar,
    'userClass': userClass,
    'level': level,
    'xp': xp,
    'gold': gold,
    'currentStreak': currentStreak,
    'maxStreak': maxStreak,
    'daysActive': daysActive,
    'energy': energy,
    'lastLoginDate': lastLoginDate,
    'createdDate': createdDate,
    'activeTitle': activeTitle,
    'unlockedTitles': unlockedTitles,
    'equippedItems': equippedItems,
    'companions': companions,
    'stats': stats,
    'settings': settings,
    'totalMissionsCompleted': totalMissionsCompleted,
    'totalTimeTrained': totalTimeTrained,
  };

  factory UserProfile.fromMap(Map<dynamic, dynamic> map) => UserProfile(
    name: map['name'] ?? 'Hunter',
    selectedAvatar: map['selectedAvatar'] ?? 'knight',
    userClass: map['userClass'] ?? 'guerrero',
    level: map['level'] ?? 1,
    xp: map['xp'] ?? 0,
    gold: map['gold'] ?? 300,
    currentStreak: map['currentStreak'] ?? 0,
    maxStreak: map['maxStreak'] ?? 0,
    daysActive: map['daysActive'] ?? 1,
    energy: map['energy'] ?? 5,
    lastLoginDate: map['lastLoginDate'] ?? '',
    createdDate: map['createdDate'] ?? '',
    activeTitle: map['activeTitle'] ?? 'principiante',
    unlockedTitles: List<String>.from(map['unlockedTitles'] ?? ['principiante']),
    equippedItems: List<String>.from(map['equippedItems'] ?? ['espada_entrenamiento', 'armadura_entrenamiento']),
    companions: List<String>.from(map['companions'] ?? []),
    stats: Map<String, int>.from(map['stats'] ?? {'strength': 10, 'intelligence': 10, 'discipline': 10, 'spirit': 10, 'defense': 10}),
    settings: Map<String, bool>.from(map['settings'] ?? {'scalingEnabled': true, 'pauseAllowed': false}),
    totalMissionsCompleted: map['totalMissionsCompleted'] ?? 0,
    totalTimeTrained: map['totalTimeTrained'] ?? 0,
  );

  /// Guardar el perfil en Hive
  Future<void> save() async {
    final box = Hive.box('user_profile');
    await box.put('data', toMap());
  }

  /// Cargar perfil desde Hive (devuelve null si no existe aún)
  static UserProfile? load() {
    final box = Hive.box('user_profile');
    final data = box.get('data');
    if (data == null) return null;
    return UserProfile.fromMap(data as Map);
  }

  /// XP necesario para el siguiente nivel (fórmula del sistema)
  int get xpForNextLevel => 100 + 10 * (level - 1) * (level + 6);

  /// Calcular el rango de cazador actual basado en nivel y misiones completadas
  String get hunterRank {
    if (level >= 1500) return 'Monarch';
    if (level >= 1000) return 'National Hunter';
    if (level >= 750) return 'SSS';
    if (level >= 500) return 'SS';
    if (level >= 300) return 'S';
    if (level >= 150) return 'A';
    if (level >= 75) return 'B';
    if (level >= 30) return 'C';
    if (level >= 10) return 'D';
    return 'E';
  }

  /// Calcular el Poder de Ataque (AP) total incluyendo clase y equipamiento
  int calculateAP({List<Map<String, dynamic>> equippedItemsData = const []}) {
    final str = stats['strength'] ?? 10;
    final def = stats['defense'] ?? 10;

    double classBonusStr = 0;
    double classBonusDef = 0;

    switch (userClass) {
      case 'guerrero':
        classBonusStr = str * 0.20;
        classBonusDef = def * 0.10;
        break;
      case 'estratega':
        // Bono de XP, no de AP directo
        break;
      case 'desafiante':
        // Bono de Oro
        break;
      case 'explorador':
        // Bono de velocidad y evasión
        break;
    }

    int weaponBonus = 0;
    int armorBonus = 0;

    for (final item in equippedItemsData) {
      if (item['type'] == 'arma') {
        weaponBonus += (item['stats_attack'] ?? 0) as int;
        weaponBonus += ((item['upgrade_level'] ?? 0) as int) * 5;
      }
      if (item['type'] == 'armadura') {
        armorBonus += (item['stats_defense'] ?? 0) as int;
        armorBonus += ((item['upgrade_level'] ?? 0) as int) * 3;
      }
    }

    return (str + classBonusStr + def + classBonusDef + weaponBonus + armorBonus).round();
  }
}
