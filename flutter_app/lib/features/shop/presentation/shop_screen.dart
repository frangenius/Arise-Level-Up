import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_provider.dart';
import '../../../core/database/db_helper.dart';

/// Datos de la tienda del sistema
class ShopItem {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String type; // 'consumible' | 'arma' | 'armadura' | 'material'
  final String rarity;
  final int price;
  final Map<String, int>? statsBonus;

  const ShopItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.type,
    required this.rarity,
    required this.price,
    this.statsBonus,
  });
}

const _shopItems = [
  ShopItem(id: 'pocion_vida_s', name: 'Poción de Vida (S)', icon: '❤️', description: 'Restaura HP menor en combate.', type: 'consumible', rarity: 'comun', price: 50),
  ShopItem(id: 'pocion_vida_m', name: 'Poción de Vida (M)', icon: '💖', description: 'Restaura HP moderado en combate.', type: 'consumible', rarity: 'poco_comun', price: 150),
  ShopItem(id: 'pocion_mana', name: 'Poción de Maná', icon: '💧', description: 'Restaura 30 MP en combate.', type: 'consumible', rarity: 'comun', price: 80),
  ShopItem(id: 'pergamino_xp', name: 'Pergamino de XP', icon: '📜', description: '+50 XP al usarse. Solo una vez.', type: 'consumible', rarity: 'raro', price: 300),
  ShopItem(id: 'espada_hierro', name: 'Espada de Hierro', icon: '⚔️', description: '+8 ATK base. Arma cuerpo a cuerpo.', type: 'arma', rarity: 'poco_comun', price: 200, statsBonus: {'attack': 8}),
  ShopItem(id: 'daga_sombra', name: 'Daga de las Sombras', icon: '🗡️', description: '+15 ATK base. Hoja oscura.', type: 'arma', rarity: 'raro', price: 500, statsBonus: {'attack': 15}),
  ShopItem(id: 'arco_viento', name: 'Arco del Viento', icon: '🏹', description: '+12 ATK base. Ataque a distancia.', type: 'arma', rarity: 'raro', price: 450, statsBonus: {'attack': 12}),
  ShopItem(id: 'peto_cuero', name: 'Peto de Cuero', icon: '🛡️', description: '+5 DEF base. Armadura ligera.', type: 'armadura', rarity: 'comun', price: 120, statsBonus: {'defense': 5}),
  ShopItem(id: 'armadura_plata', name: 'Armadura de Plata', icon: '🪖', description: '+12 DEF base. Armadura media.', type: 'armadura', rarity: 'poco_comun', price: 350, statsBonus: {'defense': 12}),
  ShopItem(id: 'capa_invisible', name: 'Capa de Invisibilidad', icon: '🧥', description: '+8 DEF, +5% evasión. Material especial.', type: 'armadura', rarity: 'epico', price: 800, statsBonus: {'defense': 8}),
  ShopItem(id: 'cristal_mejora', name: 'Cristal de Mejora', icon: '💎', description: 'Material para mejorar equipamiento +1.', type: 'material', rarity: 'raro', price: 250),
  ShopItem(id: 'piedra_runa', name: 'Piedra Rúnica', icon: '🔮', description: 'Material para encantamientos avanzados.', type: 'material', rarity: 'epico', price: 600),
];

class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabs = ['Todo', 'Consumibles', 'Armas', 'Armaduras', 'Materiales'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<ShopItem> _filteredItems(int tabIdx) {
    switch (tabIdx) {
      case 1: return _shopItems.where((i) => i.type == 'consumible').toList();
      case 2: return _shopItems.where((i) => i.type == 'arma').toList();
      case 3: return _shopItems.where((i) => i.type == 'armadura').toList();
      case 4: return _shopItems.where((i) => i.type == 'material').toList();
      default: return _shopItems;
    }
  }

  Future<void> _buyItem(ShopItem item) async {
    final profile = ref.read(userProfileProvider);
    if (profile == null || profile.gold < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.colorError.withOpacity(0.9),
          content: const Text('⚠️ Oro insuficiente', style: TextStyle(fontFamily: 'Orbitron')),
        ),
      );
      return;
    }

    final success = await ref.read(userProfileProvider.notifier).spendGold(item.price);
    if (!success) return;

    await DbHelper.instance.insertInventoryItem({
      'item_id': '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
      'name': item.name,
      'type': item.type,
      'rarity': item.rarity,
      'icon': item.icon,
      'description': item.description,
      'quantity': 1,
      'equipped': 0,
      'upgrade_level': 0,
      'stats_json': '{}',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.colorSuccess.withOpacity(0.9),
          content: Text('✅ ${item.name} comprado!', style: const TextStyle(fontFamily: 'Orbitron')),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final gold = profile?.gold ?? 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('TIENDA'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                const Text('🟡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$gold',
                  style: const TextStyle(fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.colorGold),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
          labelColor: AppTheme.colorGold,
          unselectedLabelColor: Colors.white38,
          labelStyle: const TextStyle(fontFamily: 'Orbitron', fontSize: 10, fontWeight: FontWeight.w700),
          indicatorColor: AppTheme.colorGold,
          isScrollable: true,
          dividerColor: Colors.white.withOpacity(0.1),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(5, (tabIdx) {
          final items = _filteredItems(tabIdx);
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final item = items[i];
              final rarityColor = AppTheme.getRarityColor(item.rarity);
              final canAfford = gold >= item.price;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: rarityColor.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: rarityColor.withOpacity(0.08),
                        border: Border.all(color: rarityColor.withOpacity(0.25)),
                      ),
                      child: Center(child: Text(item.icon, style: const TextStyle(fontSize: 24))),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name, style: TextStyle(
                            fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w700, color: rarityColor,
                          )),
                          Text(item.description, style: const TextStyle(fontSize: 12, color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: rarityColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  item.rarity.replaceAll('_', ' ').toUpperCase(),
                                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 8, color: rarityColor, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                item.type.toUpperCase(),
                                style: const TextStyle(fontFamily: 'Orbitron', fontSize: 8, color: Colors.white30),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: canAfford ? () => _buyItem(item) : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: canAfford
                              ? AppTheme.colorGold.withOpacity(0.1)
                              : Colors.white.withOpacity(0.02),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: canAfford ? AppTheme.colorGold.withOpacity(0.4) : Colors.white10,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Text('🟡', style: TextStyle(fontSize: 12)),
                            Text(
                              '${item.price}',
                              style: TextStyle(
                                fontFamily: 'Orbitron', fontSize: 13, fontWeight: FontWeight.w900,
                                color: canAfford ? AppTheme.colorGold : Colors.white24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
