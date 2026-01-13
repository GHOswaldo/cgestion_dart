/// Widget de switch para cambiar entre temas.
/// 
/// Proporciona un botón de icono en el AppBar que permite al usuario
/// alternar entre tema claro y oscuro. El icono cambia dinámicamente
/// según el tema actual (sol para modo claro, luna para modo oscuro).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestor_alacena/services/theme_service.dart';

/// Widget de switch de tema reutilizable.
/// 
/// Este widget escucha los cambios en [ThemeService] y actualiza
/// automáticamente su apariencia cuando cambia el tema. Se usa
/// típicamente en el AppBar de las pantallas principales.
/// 
/// Es un StatelessWidget porque todo el estado se gestiona mediante
/// el provider [ThemeService].
class ThemeSwitch extends StatelessWidget {
  /// Constructor const para optimizar el rendimiento.
  const ThemeSwitch({super.key});

  /// Construye el widget del switch de tema.
  /// 
  /// Usa [Consumer<ThemeService>] para escuchar cambios en el tema
  /// y actualizar automáticamente la UI cuando el usuario cambia
  /// entre modo claro y oscuro.
  /// 
  /// El widget muestra:
  /// - Icono de luna (dark_mode) cuando está en tema claro
  /// - Icono de sol (light_mode) cuando está en tema oscuro
  /// 
  /// Esta inversión es intuitiva porque el icono representa el
  /// estado al que se cambiará al presionar el botón, no el estado actual.
  /// 
  /// Ejemplo de uso en un AppBar:
  /// ```dart
  /// AppBar(
  ///   title: const Text('Mi Pantalla'),
  ///   actions: const [
  ///     ThemeSwitch(),
  ///   ],
  /// )
  /// ```
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Padding(
          // Padding a la derecha para separación del borde
          padding: const EdgeInsets.only(right: 8.0),
          child: IconButton(
            // Icono dinámico según el tema actual
            icon: Icon(
              themeService.isDarkMode 
                  ? Icons.light_mode_rounded  // Sol (cambiar a claro)
                  : Icons.dark_mode_rounded,  // Luna (cambiar a oscuro)
            ),
            // Tooltip descriptivo para accesibilidad
            tooltip: themeService.isDarkMode 
                ? 'Modo claro' 
                : 'Modo oscuro',
            // Acción al presionar: alternar tema
            onPressed: () => themeService.toggleTheme(),
          ),
        );
      },
    );
  }
}
