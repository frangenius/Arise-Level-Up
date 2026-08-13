import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Colores principales del sistema (Solo Leveling vibe)
  static const Color bgMain = Color(0xFF02040a);
  static const Color bgGradientStart = Color(0xFF060b19);
  static const Color colorPrimary = Color(0xFF3B82F6);    // Azul eléctrico
  static const Color colorSecondary = Color(0xFF7C3AED);   // Violeta
  static const Color colorXP = Color(0xFF06B6D4);          // Celeste brillante
  static const Color colorSuccess = Color(0xFF10B981);     // Verde
  static const Color colorWarning = Color(0xFFF59E0B);     // Naranja
  static const Color colorError = Color(0xFFEF4444);       // Rojo
  static const Color colorGold = Color(0xFFFACC15);        // Amarillo oro

  // Colores de atributos
  static const Color colorStrength = Color(0xFFEF4444);    // Rojo fuego
  static const Color colorIntelligence = Color(0xFF3B82F6);// Azul eléctrico
  static const Color colorDiscipline = Color(0xFFFACC15);  // Dorado
  static const Color colorSpirit = Color(0xFF10B981);      // Verde esmeralda
  static const Color colorDefense = Color(0xFF9CA3AF);     // Gris plateado

  // Colores de rareza de objetos
  static const Color rarityComun = Color(0xFF9CA3AF);
  static const Color rarityPocoComun = Color(0xFF10B981);
  static const Color rarityRaro = Color(0xFF3B82F6);
  static const Color rarityEpico = Color(0xFF7C3AED);
  static const Color rarityLegendario = Color(0xFFF59E0B);
  static const Color rarityMitico = Color(0xFFEF4444);
  static const Color rarityUnico = Color(0xFFF472B6);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgMain,
      
      colorScheme: const ColorScheme.dark(
        primary: colorPrimary,
        secondary: colorSecondary,
        surface: Color(0xFF060b19),
        error: colorError,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),

      // Tipografía: Orbitron para títulos, Rajdhani para cuerpo
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 2,
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
        displaySmall: GoogleFonts.orbitron(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1,
        ),
        headlineLarge: GoogleFonts.orbitron(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 0.8,
        ),
        bodyLarge: GoogleFonts.rajdhani(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyMedium: GoogleFonts.rajdhani(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white70,
        ),
        bodySmall: GoogleFonts.rajdhani(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: Colors.white54,
        ),
        labelLarge: GoogleFonts.orbitron(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: 1.2,
        ),
      ),

      // AppBar transparente
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.orbitron(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 1.5,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // Navegación inferior estilizada
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF030608),
        indicatorColor: colorPrimary.withOpacity(0.2),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.orbitron(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: colorPrimary,
            );
          }
          return GoogleFonts.orbitron(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white38,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: colorPrimary, size: 24);
          }
          return const IconThemeData(color: Colors.white38, size: 22);
        }),
      ),

      // Botones elevados con gradiente
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.orbitron(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),

      // Inputs de texto estilizados
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.15)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: colorPrimary, width: 1.5),
        ),
        labelStyle: GoogleFonts.orbitron(
          fontSize: 12,
          color: Colors.white60,
          letterSpacing: 0.8,
        ),
        hintStyle: GoogleFonts.rajdhani(
          fontSize: 16,
          color: Colors.white38,
        ),
      ),

      // Cards con glassmorphism
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(0.03),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
        ),
        elevation: 0,
      ),

      // Chips de rareza y dificultad
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white.withOpacity(0.05),
        labelStyle: GoogleFonts.orbitron(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Dividers sutiles
      dividerTheme: DividerThemeData(
        color: Colors.white.withOpacity(0.07),
        thickness: 1,
      ),
    );
  }

  // Decoración de panel de cristal (glassmorphism) reutilizable
  static BoxDecoration glassPanel({
    bool neonBorder = false,
    bool violetBorder = false,
    Color? customBorderColor,
    double borderRadius = 12,
  }) {
    Color borderColor = Colors.white.withOpacity(0.08);
    List<BoxShadow> shadows = [];

    if (neonBorder) {
      borderColor = colorPrimary.withOpacity(0.3);
      shadows = [
        BoxShadow(
          color: colorPrimary.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: -2,
        ),
      ];
    } else if (violetBorder) {
      borderColor = colorSecondary.withOpacity(0.3);
      shadows = [
        BoxShadow(
          color: colorSecondary.withOpacity(0.2),
          blurRadius: 15,
          spreadRadius: -2,
        ),
      ];
    } else if (customBorderColor != null) {
      borderColor = customBorderColor.withOpacity(0.4);
    }

    return BoxDecoration(
      color: const Color(0xFF060b19).withOpacity(0.65),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: borderColor, width: 1),
      boxShadow: shadows,
    );
  }

  // Decoración de gradiente de fondo principal
  static BoxDecoration get mainGradient => const BoxDecoration(
    gradient: RadialGradient(
      center: Alignment.center,
      radius: 1.5,
      colors: [Color(0xFF060b19), Color(0xFF010307)],
    ),
  );

  // Gradiente para botón principal (azul a violeta)
  static Decoration get primaryButtonGradient => BoxDecoration(
    gradient: const LinearGradient(
      colors: [colorPrimary, colorSecondary],
    ),
    borderRadius: BorderRadius.circular(8),
    boxShadow: [
      BoxShadow(
        color: colorSecondary.withOpacity(0.4),
        blurRadius: 15,
        spreadRadius: -4,
      ),
    ],
  );

  // Obtener color por atributo
  static Color getAttributeColor(String attribute) {
    switch (attribute.toLowerCase()) {
      case 'strength': return colorStrength;
      case 'intelligence': return colorIntelligence;
      case 'discipline': return colorDiscipline;
      case 'spirit': return colorSpirit;
      case 'defense': return colorDefense;
      default: return colorPrimary;
    }
  }

  // Obtener color por rareza de objeto
  static Color getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'comun': return rarityComun;
      case 'poco_comun': return rarityPocoComun;
      case 'raro': return rarityRaro;
      case 'epico': return rarityEpico;
      case 'legendario': return rarityLegendario;
      case 'mitico': return rarityMitico;
      case 'unico': return rarityUnico;
      default: return rarityComun;
    }
  }

  // Obtener color por dificultad de misión
  static Color getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'muy_facil': return colorSuccess;
      case 'facil': return colorPrimary;
      case 'normal': return colorWarning;
      case 'dificil': return colorError;
      case 'extrema': return colorSecondary;
      default: return colorPrimary;
    }
  }
}
