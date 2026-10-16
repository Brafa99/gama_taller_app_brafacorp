import 'package:flutter/material.dart';

class AppThemeModel {
  final String name;
  final List<Color> backgroundGradient;
  final Color cardColor;
  final Color primaryColor;
  final Color accentColor;
  final Color textColor;
  final Color borderColor;
  final bool isNeon;

  AppThemeModel({
    required this.name,
    required this.backgroundGradient,
    required this.cardColor,
    required this.primaryColor,
    required this.accentColor,
    required this.textColor,
    required this.borderColor,
    this.isNeon = true,
  });
}

class AppThemes {
  static final List<AppThemeModel> themes = [
    // 1. Estilo Verde Oliva Cyber / Militar Neón
    AppThemeModel(
      name: "Oliva Cyber",
      backgroundGradient: [Color(0xFF0B120C), Color(0xFF142217), Color(0xFF070D08)],
      cardColor: Color(0xFF16251A),
      primaryColor: Color(0xFF39FF14), // Verde neón
      accentColor: Color(0xFF76FF03),
      textColor: Colors.white,
      borderColor: Color(0xFF39FF14),
    ),
    // 2. Estilo Ciberpunk Magenta / Violeta
    AppThemeModel(
      name: "Cyber Magenta",
      backgroundGradient: [Color(0xFF0F051D), Color(0xFF1F0D3D), Color(0xFF080210)],
      cardColor: Color(0xFF1C1033),
      primaryColor: Color(0xFFFF007F), // Magenta brillante
      accentColor: Color(0xFF9D00FF),
      textColor: Colors.white,
      borderColor: Color(0xFFFF007F),
    ),
    // 3. Estilo Azul Láser / Futurista
    AppThemeModel(
      name: "Blue Laser",
      backgroundGradient: [Color(0xFF020A18), Color(0xFF0B1E3F), Color(0xFF01040A)],
      cardColor: Color(0xFF0E2246),
      primaryColor: Color(0xFF00E5FF), // Cian eléctrico
      accentColor: Color(0xFF2979FF),
      textColor: Colors.white,
      borderColor: Color(0xFF00E5FF),
    ),
    // 4. Estilo Fuego Solar / Naranja Extremo
    AppThemeModel(
      name: "Solar Flare",
      backgroundGradient: [Color(0xFF1A0A02), Color(0xFF331604), Color(0xFF0D0401)],
      cardColor: Color(0xFF261105),
      primaryColor: Color(0xFFFF6D00), // Naranja intenso
      accentColor: Color(0xFFFFD600),
      textColor: Colors.white,
      borderColor: Color(0xFFFF6D00),
    ),
    // 5. Estilo Monocromático Titanio (Elegante Oscuro)
    AppThemeModel(
      name: "Titanium Dark",
      backgroundGradient: [Color(0xFF121212), Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
      cardColor: Color(0xFF1A1A1A),
      primaryColor: Color(0xFFE0E0E0), // Plata neón
      accentColor: Color(0xFFBDBDBD),
      textColor: Colors.white,
      borderColor: Color(0xFF757575),
    ),
  ];
}

// Notifier global estático o controlador de tema para toda la app
ValueNotifier<AppThemeModel> currentThemeNotifier = ValueNotifier<AppThemeModel>(AppThemes.themes[0]);