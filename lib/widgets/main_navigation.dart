/// Navegación principal de la aplicación.
/// 
/// Proporciona la estructura de navegación principal mediante una barra de
/// navegación inferior (BottomNavigationBar) que permite al usuario cambiar
/// entre las cuatro secciones principales de la aplicación.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:gestor_alacena/screens/inventory_screen.dart';
import 'package:gestor_alacena/screens/shopping_list_screen.dart';
import 'package:gestor_alacena/screens/statistics_screen.dart';
import 'package:gestor_alacena/screens/settings_screen.dart';

/// Widget de navegación principal con pestañas inferiores.
/// 
/// Esta pantalla se muestra después de que el usuario se autentica exitosamente
/// y pertenece a una familia. Coordina la navegación entre las cuatro secciones
/// principales de la aplicación usando un [BottomNavigationBar].
/// 
/// Las secciones disponibles son:
/// 1. Inventario - Gestión de productos en la alacena
/// 2. Lista de Compras - Productos que se necesitan comprar
/// 3. Estadísticas - Análisis de gastos e inventario
/// 4. Ajustes - Configuración de la aplicación y familia
class MainNavigation extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

/// Estado de la navegación principal.
/// 
/// Gestiona el índice de la pestaña actualmente seleccionada y coordina
/// la visualización de las pantallas correspondientes.
class _MainNavigationState extends State<MainNavigation> {
  /// Índice de la pantalla actualmente seleccionada.
  /// 
  /// Valores posibles:
  /// - 0: Inventario (pantalla por defecto)
  /// - 1: Lista de Compras
  /// - 2: Estadísticas
  /// - 3: Ajustes
  int _currentIndex = 0;

  /// Lista de pantallas que corresponden a cada pestaña de navegación.
  /// 
  /// El orden de las pantallas debe coincidir con el orden de los items
  /// en el [BottomNavigationBar]. Se usa [IndexedStack] para mantener
  /// el estado de cada pantalla cuando el usuario navega entre ellas.
  /// 
  /// Ventaja de [IndexedStack]:
  /// - Preserva el estado de las pantallas (scroll, formularios, etc.)
  /// - No reconstruye las pantallas al cambiar de pestaña
  /// - Mejora el rendimiento al evitar reconstrucciones innecesarias
  final List<Widget> _screens = [
    const InventoryScreen(),      // Índice 0
    const ShoppingListScreen(),   // Índice 1
    const StatisticsScreen(),     // Índice 2
    const SettingsScreen(),       // Índice 3
  ];

  /// Construye la interfaz de navegación principal.
  /// 
  /// Componentes:
  /// - [IndexedStack]: Contiene todas las pantallas y muestra solo la activa
  /// - [BottomNavigationBar]: Barra de navegación inferior con 4 pestañas
  /// 
  /// La barra de navegación incluye:
  /// - Iconos outlined para estado inactivo
  /// - Iconos rounded para estado activo
  /// - Color verde (#34A853) para elementos seleccionados
  /// - Sombra sutil en la parte superior para separación visual
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack mantiene todas las pantallas en memoria
      // y solo muestra la que corresponde al índice actual
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // Decoración con sombra para dar profundidad visual
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5), // Sombra hacia arriba
            ),
          ],
        ),
        child: BottomNavigationBar(
          // Índice de la pestaña actualmente seleccionada
          currentIndex: _currentIndex,
          
          // Callback que se ejecuta cuando el usuario toca una pestaña
          onTap: (index) => setState(() => _currentIndex = index),
          
          // Tipo fixed mantiene todas las pestañas visibles con tamaño uniforme
          type: BottomNavigationBarType.fixed,
          
          // Colores de los elementos
          selectedItemColor: const Color(0xFF34A853),    // Verde para seleccionado
          unselectedItemColor: const Color(0xFF5F6368),  // Gris para no seleccionado
          
          // Tamaños de fuente uniformes
          selectedFontSize: 12,
          unselectedFontSize: 12,
          
          // Etiqueta seleccionada en negrita para mayor énfasis
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          
          // Definición de las 4 pestañas de navegación
          items: const [
            // Pestaña 1: Inventario
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2_rounded),
              label: 'Inventario',
            ),
            
            // Pestaña 2: Lista de Compras
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart_rounded),
              label: 'Lista de Compras',
            ),
            
            // Pestaña 3: Estadísticas
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics_rounded),
              label: 'Estadísticas',
            ),
            
            // Pestaña 4: Ajustes
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }
}
