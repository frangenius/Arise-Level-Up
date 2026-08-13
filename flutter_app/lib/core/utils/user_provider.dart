import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/user_profile.dart';
import '../database/db_helper.dart';

/// Notifier global del perfil del usuario.
/// Maneja subida de nivel, ganancias de XP/oro, actualización de estadísticas.
class UserProfileNotifier extends Notifier<UserProfile?> {
  @override
  UserProfile? build() {
    // Cargar perfil desde Hive al iniciar
    return UserProfile.load();
  }

  /// Guardar un nuevo perfil (onboarding completado)
  Future<void> saveProfile(UserProfile profile) async {
    await profile.save();
    state = profile;
  }

  /// Agregar XP y verificar subida de nivel
  Future<bool> addXP(int amount) async {
    if (state == null) return false;

    bool leveledUp = false;
    int newXP = state!.xp + amount;
    int newLevel = state!.level;

    while (newXP >= (100 + 10 * (newLevel - 1) * (newLevel + 6))) {
      newXP -= (100 + 10 * (newLevel - 1) * (newLevel + 6));
      newLevel++;
      leveledUp = true;
    }

    final updated = state!.copyWith(xp: newXP, level: newLevel);
    await updated.save();
    state = updated;
    return leveledUp;
  }

  /// Agregar oro
  Future<void> addGold(int amount) async {
    if (state == null) return;
    final updated = state!.copyWith(gold: state!.gold + amount);
    await updated.save();
    state = updated;
  }

  /// Gastar oro (verifica que haya suficiente)
  Future<bool> spendGold(int amount) async {
    if (state == null || state!.gold < amount) return false;
    final updated = state!.copyWith(gold: state!.gold - amount);
    await updated.save();
    state = updated;
    return true;
  }

  /// Incrementar atributo específico
  Future<void> incrementStat(String attribute, int amount) async {
    if (state == null) return;
    final newStats = Map<String, int>.from(state!.stats);
    newStats[attribute] = (newStats[attribute] ?? 10) + amount;
    
    final updated = state!.copyWith(stats: newStats);
    await updated.save();
    state = updated;

    // Registrar en el historial de atributos
    await DbHelper.instance.insertAttributeHistory(
      attribute,
      amount,
      '+$amount ${attribute.substring(0, 1).toUpperCase()}${attribute.substring(1)}',
    );
  }

  /// Actualizar racha
  Future<void> updateStreak(bool missionCompleted) async {
    if (state == null) return;
    int newStreak = missionCompleted ? state!.currentStreak + 1 : 0;
    int newMaxStreak = newStreak > state!.maxStreak ? newStreak : state!.maxStreak;
    
    final updated = state!.copyWith(
      currentStreak: newStreak,
      maxStreak: newMaxStreak,
    );
    await updated.save();
    state = updated;
  }

  /// Gastar energía para portal
  Future<bool> spendEnergy() async {
    if (state == null || state!.energy < 1) return false;
    final updated = state!.copyWith(energy: state!.energy - 1);
    await updated.save();
    state = updated;
    return true;
  }

  /// Recargar energía semanal (sábados)
  Future<void> rechargeEnergy() async {
    if (state == null) return;
    final updated = state!.copyWith(energy: 5);
    await updated.save();
    state = updated;
  }

  /// Equipar/desequipar un objeto
  Future<void> equipItem(String itemId) async {
    if (state == null) return;
    final equipped = List<String>.from(state!.equippedItems);
    if (equipped.contains(itemId)) {
      equipped.remove(itemId);
    } else {
      equipped.add(itemId);
    }
    final updated = state!.copyWith(equippedItems: equipped);
    await updated.save();
    state = updated;
  }

  /// Actualizar fecha de último login y verificar si se necesita reset diario
  Future<bool> checkDailyReset() async {
    if (state == null) return false;
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    if (state!.lastLoginDate == todayStr) return false;

    // Calcular días de inactividad
    bool needsRecovery = false;
    if (state!.lastLoginDate.isNotEmpty) {
      final lastLogin = DateTime.tryParse(state!.lastLoginDate);
      if (lastLogin != null) {
        final diff = today.difference(lastLogin).inDays;
        needsRecovery = diff >= 3;
      }
    }

    final updated = state!.copyWith(
      lastLoginDate: todayStr,
      daysActive: state!.daysActive + 1,
    );
    await updated.save();
    state = updated;
    return needsRecovery;
  }

  /// Cambiar clase del personaje
  Future<void> changeClass(String newClass) async {
    if (state == null) return;
    final updated = state!.copyWith(userClass: newClass);
    await updated.save();
    state = updated;
  }

  /// Incrementar contador total de misiones
  Future<void> incrementTotalMissions() async {
    if (state == null) return;
    final updated = state!.copyWith(
      totalMissionsCompleted: state!.totalMissionsCompleted + 1,
    );
    await updated.save();
    state = updated;
  }

  /// Desbloquear un título
  Future<void> unlockTitle(String titleId) async {
    if (state == null) return;
    if (state!.unlockedTitles.contains(titleId)) return;
    
    final titles = List<String>.from(state!.unlockedTitles)..add(titleId);
    final updated = state!.copyWith(unlockedTitles: titles);
    await updated.save();
    state = updated;
  }

  /// Establecer título activo
  Future<void> setActiveTitle(String titleId) async {
    if (state == null) return;
    if (!state!.unlockedTitles.contains(titleId)) return;
    final updated = state!.copyWith(activeTitle: titleId);
    await updated.save();
    state = updated;
  }
}

/// Provider global del perfil del usuario
final userProfileProvider = NotifierProvider<UserProfileNotifier, UserProfile?>(
  UserProfileNotifier.new,
);
