import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/user_provider.dart';
import '../../../core/database/db_helper.dart';

/// Pantalla de estadísticas con Radar Chart animado personalizado y historial
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    if (profile == null) return const SizedBox();

    final stats = profile.stats;
    final maxStat = stats.values.reduce(max).toDouble();
    final chartMax = (maxStat * 1.3).clamp(50.0, 10000.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('ESTADÍSTICAS')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radar Chart personalizado
            Container(
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassPanel(neonBorder: true),
              child: Column(
                children: [
                  Text('RADAR DE ATRIBUTOS', style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.white60, fontSize: 11, letterSpacing: 2,
                  )),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 280,
                    child: CustomPaint(
                      painter: RadarChartPainter(
                        values: [
                          (stats['strength'] ?? 10).toDouble(),
                          (stats['intelligence'] ?? 10).toDouble(),
                          (stats['discipline'] ?? 10).toDouble(),
                          (stats['spirit'] ?? 10).toDouble(),
                          (stats['defense'] ?? 10).toDouble(),
                        ],
                        labels: ['STR', 'INT', 'DIS', 'SPI', 'DEF'],
                        colors: [
                          AppTheme.colorStrength,
                          AppTheme.colorIntelligence,
                          AppTheme.colorDiscipline,
                          AppTheme.colorSpirit,
                          AppTheme.colorDefense,
                        ],
                        maxValue: chartMax,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Resumen en números
            Text('VALORES ACTUALES', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white60, fontSize: 11, letterSpacing: 2,
            )),
            const SizedBox(height: 8),

            ...['strength', 'intelligence', 'discipline', 'spirit', 'defense'].map((attr) {
              final val = stats[attr] ?? 10;
              final color = AppTheme.getAttributeColor(attr);
              final labels = {
                'strength': '💪 Fuerza', 'intelligence': '🧠 Inteligencia',
                'discipline': '⏱️ Disciplina', 'spirit': '🧘 Espíritu', 'defense': '🛡️ Defensa',
              };
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: AppTheme.glassPanel(),
                child: Row(
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(labels[attr] ?? attr, style: Theme.of(context).textTheme.bodyMedium),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (val / chartMax).clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.04),
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('$val', style: TextStyle(
                      fontFamily: 'Orbitron', fontSize: 16, fontWeight: FontWeight.w900, color: color,
                    )),
                  ],
                ),
              );
            }),

            const SizedBox(height: 16),

            // Estadísticas generales
            Text('RESUMEN GENERAL', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white60, fontSize: 11, letterSpacing: 2,
            )),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassPanel(),
              child: Column(
                children: [
                  _infoRow(context, 'Nivel', '${profile.level}', AppTheme.colorPrimary),
                  _infoRow(context, 'Rango', profile.hunterRank, AppTheme.colorGold),
                  _infoRow(context, 'Racha Actual', '${profile.currentStreak} días', AppTheme.colorWarning),
                  _infoRow(context, 'Racha Máxima', '${profile.maxStreak} días', AppTheme.colorWarning),
                  _infoRow(context, 'Días Activos', '${profile.daysActive}', AppTheme.colorSuccess),
                  _infoRow(context, 'Misiones Completadas', '${profile.totalMissionsCompleted}', AppTheme.colorXP),
                  _infoRow(context, 'Oro Acumulado', '${profile.gold}', AppTheme.colorGold),
                  _infoRow(context, 'AP Total', '${profile.calculateAP()}', AppTheme.colorError),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Historial reciente
            Text('HISTORIAL RECIENTE', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.white60, fontSize: 11, letterSpacing: 2,
            )),
            const SizedBox(height: 8),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: DbHelper.instance.getAttributeHistory(limit: 15),
              builder: (ctx, snapshot) {
                final history = snapshot.data ?? [];
                if (history.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.glassPanel(),
                    child: const Center(
                      child: Text('Sin historial aún. Completa misiones para registrar progreso.',
                          textAlign: TextAlign.center, style: TextStyle(color: Colors.white38)),
                    ),
                  );
                }
                return Container(
                  decoration: AppTheme.glassPanel(),
                  child: Column(
                    children: history.map((h) {
                      final attr = h['attribute'] as String;
                      final color = AppTheme.getAttributeColor(attr);
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 4, height: 28,
                              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(h['description'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  Text(h['date'] as String, style: const TextStyle(color: Colors.white30, fontSize: 11)),
                                ],
                              ),
                            ),
                            Text('+${h['amount']}', style: TextStyle(
                              fontFamily: 'Orbitron', fontSize: 14, fontWeight: FontWeight.w700, color: color,
                            )),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(value, style: TextStyle(fontFamily: 'Orbitron', fontSize: 15, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

// ========================================================
// RADAR CHART CUSTOM PAINTER
// ========================================================

class RadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> labels;
  final List<Color> colors;
  final double maxValue;

  RadarChartPainter({
    required this.values,
    required this.labels,
    required this.colors,
    required this.maxValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final sides = values.length;
    final angle = 2 * pi / sides;

    // Dibujar las guías (anillos concéntricos)
    for (int ring = 1; ring <= 4; ring++) {
      final ringRadius = radius * ring / 4;
      final ringPath = Path();
      for (int i = 0; i < sides; i++) {
        final a = -pi / 2 + angle * i;
        final x = center.dx + ringRadius * cos(a);
        final y = center.dy + ringRadius * sin(a);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Dibujar las líneas radiales
    for (int i = 0; i < sides; i++) {
      final a = -pi / 2 + angle * i;
      final x = center.dx + radius * cos(a);
      final y = center.dy + radius * sin(a);
      canvas.drawLine(center, Offset(x, y), Paint()
        ..color = Colors.white.withOpacity(0.06)
        ..strokeWidth = 1);
    }

    // Dibujar el polígono de datos
    final dataPath = Path();
    final dataPoints = <Offset>[];
    for (int i = 0; i < sides; i++) {
      final a = -pi / 2 + angle * i;
      final ratio = (values[i] / maxValue).clamp(0.0, 1.0);
      final r = radius * ratio;
      final x = center.dx + r * cos(a);
      final y = center.dy + r * sin(a);
      dataPoints.add(Offset(x, y));
      if (i == 0) {
        dataPath.moveTo(x, y);
      } else {
        dataPath.lineTo(x, y);
      }
    }
    dataPath.close();

    // Rellenar polígono
    canvas.drawPath(dataPath, Paint()
      ..color = AppTheme.colorPrimary.withOpacity(0.15)
      ..style = PaintingStyle.fill);

    // Borde del polígono
    canvas.drawPath(dataPath, Paint()
      ..color = AppTheme.colorPrimary.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Puntos en los vértices + labels
    for (int i = 0; i < sides; i++) {
      final pt = dataPoints[i];
      final color = colors[i];

      // Punto
      canvas.drawCircle(pt, 5, Paint()..color = color);
      canvas.drawCircle(pt, 5, Paint()
        ..color = color.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Label
      final a = -pi / 2 + angle * i;
      final labelRadius = radius + 20;
      final lx = center.dx + labelRadius * cos(a);
      final ly = center.dy + labelRadius * sin(a);

      final textPainter = TextPainter(
        text: TextSpan(
          text: '${labels[i]}\n${values[i].round()}',
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.3,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();

      textPainter.paint(canvas, Offset(lx - textPainter.width / 2, ly - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
