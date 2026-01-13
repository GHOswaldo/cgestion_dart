/// Servicio de gestión de temas (claro/oscuro).
/// 
/// Proporciona funcionalidad para cambiar entre temas claro y oscuro,
/// persistir la preferencia del usuario y definir los estilos visuales
/// de toda la aplicación mediante Material Design 3.
library;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Servicio que gestiona el tema de la aplicación.
/// 
/// Este servicio extiende [ChangeNotifier] para notificar a toda la
/// aplicación cuando cambia el tema, permitiendo actualizaciones
/// reactivas de la UI.
/// 
/// Funcionalidades principales:
/// - Alternar entre tema claro y oscuro
/// - Persistir preferencia del usuario en dispositivo
/// - Proporcionar configuraciones de tema Material Design 3
/// - Mantener consistencia visual en toda la app
class ThemeService extends ChangeNotifier {
  /// Indica si el tema oscuro está activo.
  /// Por defecto es false (tema claro).
  bool _isDarkMode = false;
  
  /// Getter público para verificar el estado del tema.
  bool get isDarkMode => _isDarkMode;
  
  /// Constructor que carga la preferencia de tema guardada.
  /// 
  /// Al inicializar el servicio, automáticamente intenta cargar
  /// la preferencia del usuario desde SharedPreferences.
  ThemeService() {
    _loadThemePreference();
  }
  
  /// Carga la preferencia de tema desde SharedPreferences.
  /// 
  /// Este método privado se llama automáticamente al inicializar
  /// el servicio. Lee el valor guardado de 'isDarkMode' y actualiza
  /// el estado. Si no hay valor guardado, usa false (tema claro).
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }
  
  /// Alterna entre tema claro y oscuro.
  /// 
  /// Proceso:
  /// 1. Invierte el valor de [_isDarkMode]
  /// 2. Guarda la nueva preferencia en SharedPreferences
  /// 3. Notifica a los listeners para actualizar la UI
  /// 
  /// La persistencia asegura que la preferencia se mantenga
  /// entre sesiones de la aplicación.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await themeService.toggleTheme();
  /// ```
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }
  
  /// Configuración del tema claro (light theme).
  /// 
  /// Define todos los estilos visuales para el modo claro usando
  /// Material Design 3 (useMaterial3: true).
  /// 
  /// Características del tema claro:
  /// - Color primario: Verde #34A853 (característico de la app)
  /// - Fondo: Gris muy claro #F8F9FA
  /// - Cards: Blanco con bordes grises
  /// - AppBar: Blanco sin elevación
  /// - Inputs: Fondo gris claro con bordes al hacer foco
  /// - Bordes redondeados (12-24px) para aspecto moderno
  /// - Sin elevaciones (diseño flat)
  /// 
  /// Este tema proporciona una experiencia limpia y luminosa.
  ThemeData get lightTheme {
    return ThemeData(
      // Usar Material Design 3
      useMaterial3: true,
      
      // Esquema de colores basado en verde
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF34A853),
        brightness: Brightness.light,
      ),
      
      // Color de fondo del scaffold
      scaffoldBackgroundColor: const Color(0xFFF8F9FA),
      
      // Estilo de cards
      cardTheme: CardThemeData(
        elevation: 0, // Sin sombra (diseño flat)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFFEEEEEE)),
        ),
        color: const Color(0xFFFFFFFF),
      ),
      
      // Estilo de AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false, // Título alineado a la izquierda
        backgroundColor: Color(0xFFFFFFFF),
        foregroundColor: Color(0xFF202124),
        surfaceTintColor: Color(0x00000000),
      ),
      
      // Estilo de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de botones con borde
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F3F4), // Gris muy claro
        // Bordes sin líneas (solo fondo)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Borde verde al hacer foco
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Estilo de diálogos
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 3,
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      
      // Estilo de barra de navegación inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Color(0xFFFFFFFF),
        selectedItemColor: Color(0xFF34A853), // Verde para seleccionado
        unselectedItemColor: Color(0xFF5F6368), // Gris para no seleccionado
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Estilo de botón flotante
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  /// Configuración del tema oscuro (dark theme).
  /// 
  /// Define todos los estilos visuales para el modo oscuro usando
  /// Material Design 3 (useMaterial3: true).
  /// 
  /// Características del tema oscuro:
  /// - Color primario: Verde #34A853 (mismo que tema claro)
  /// - Fondo: Negro #121212 (true black para OLED)
  /// - Cards: Gris oscuro #1E1E1E con bordes
  /// - AppBar: Gris oscuro sin elevación
  /// - Inputs: Gris oscuro #2C2C2C con bordes al hacer foco
  /// - Bordes redondeados (12-24px) para consistencia
  /// - Colores de texto adaptados para buena legibilidad
  /// 
  /// Este tema reduce el cansancio visual en ambientes oscuros y
  /// ahorra batería en pantallas OLED.
  ThemeData get darkTheme {
    return ThemeData(
      // Usar Material Design 3
      useMaterial3: true,
      
      // Esquema de colores basado en verde (modo oscuro)
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF34A853),
        brightness: Brightness.dark,
      ),
      
      // Color de fondo del scaffold (true black para OLED)
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      // Estilo de cards
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF424242)),
        ),
        color: const Color(0xFF1E1E1E), // Gris oscuro
      ),
      
      // Estilo de AppBar
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Color(0xFFFFFFFF),
        surfaceTintColor: Color(0x00000000),
      ),
      
      // Estilo de botones elevados
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de botones con borde
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de botones de texto
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Estilo de campos de texto
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2C), // Gris oscuro
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        // Borde verde al hacer foco (mismo que tema claro)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF34A853), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      
      // Estilo de diálogos
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 3,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      
      // Estilo de barra de navegación inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: Color(0xFF34A853), // Verde para seleccionado
        unselectedItemColor: Color(0xFF9AA0A6), // Gris claro para no seleccionado
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      ),
      
      // Estilo de botón flotante
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
