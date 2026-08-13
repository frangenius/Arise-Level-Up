import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/user_provider.dart';
import '../../core/database/db_helper.dart';

/// Pantalla de Inventario: muestra objetos equipados y no equipados con rareza
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('INVENTARIO')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: DbHelper.instance.getInventory(),
        builder: (ctx, snapshot) {
          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return const Center(
              child: Text(
                '🎒  Tu inventario está vacío.\nCompleta misiones para obtener objetos.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 14),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) => _ItemCard(item: items[i], onTap: () {}),
          );
        },
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _ItemCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final rarity = item['rarity'] as String;
    final rarityColor = AppTheme.getRarityColor(rarity);
    final equipped = (item['equipped'] as int) == 1;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: rarityColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: rarityColor.withOpacity(equipped ? 0.6 : 0.25),
            width: equipped ? 1.5 : 1,
          ),
          boxShadow: equipped
              ? [BoxShadow(color: rarityColor.withOpacity(0.2), blurRadius: 8)]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (equipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: rarityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'EQUIPADO',
                  style: TextStyle(fontFamily: 'Orbitron', fontSize: 8, color: rarityColor, fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(height: 4),
            Text(item['icon'] as String, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                item['name'] as String,
                style: TextStyle(fontFamily: 'Orbitron', fontSize: 9, color: rarityColor, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if ((item['upgrade_level'] as int) > 0)
              Text(
                '+${item['upgrade_level']}',
                style: const TextStyle(fontFamily: 'Orbitron', fontSize: 11, color: AppTheme.colorGold, fontWeight: FontWeight.w900),
              ),
          ],
        ),
      ),
    );
  }
}
