/// Punto de entrada principal de la aplicación Gestor de Alacena.
/// 
/// Esta aplicación Flutter permite a las familias gestionar el inventario
/// de su alacena, crear listas de compras y llevar un control de gastos
/// y estadísticas. Utiliza Supabase como backend y Google Sign-In para
/// la autenticación.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/inventory_service.dart';
import 'services/shopping_list_service.dart';
import 'services/statistics_service.dart';
import 'services/theme_service.dart';

/// Función principal que inicializa la aplicación.
/// 
/// Realiza las siguientes tareas:
/// - Asegura que los bindings de Flutter estén inicializados
/// - Inicializa la conexión con Supabase usando las credenciales del proyecto
/// - Ejecuta la aplicación MyApp
void main() async {
  // Asegura que los bindings de Flutter estén inicializados antes de
  // ejecutar código asíncrono
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Supabase con la URL del proyecto y la clave anónima
  await Supabase.initialize(
    url: '',
    anonKey: '',
  );
  
  runApp(const MyApp());
}

/// Widget raíz de la aplicación.
/// 
/// Configura el árbol de providers usando el patrón Provider para el manejo
/// de estado y define el tema de la aplicación. Todos los servicios están
/// disponibles en todo el árbol de widgets mediante [ChangeNotifierProvider].
class MyApp extends StatelessWidget {
  /// Constructor const para optimizar el rendimiento.
  const MyApp({super.key});

  /// Construye el widget raíz de la aplicación.
  /// 
  /// Configura:
  /// - [MultiProvider]: Provee todos los servicios necesarios a la aplicación
  /// - [MaterialApp]: Configura el tema, título y pantalla inicial
  /// - [Consumer<ThemeService>]: Escucha cambios en el servicio de tema
  /// 
  /// Los servicios disponibles son:
  /// - [ThemeService]: Gestión de tema claro/oscuro
  /// - [AuthService]: Autenticación y gestión de sesión
  /// - [InventoryService]: Gestión del inventario de la alacena
  /// - [ShoppingListService]: Gestión de listas de compras
  /// - [StatisticsService]: Cálculo y gestión de estadísticas
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Servicio de temas (debe ser el primero para que esté disponible inmediatamente)
        ChangeNotifierProvider(create: (_) => ThemeService()),
        
        // Servicio de autenticación
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Servicios de funcionalidad principal
        ChangeNotifierProvider(create: (_) => InventoryService()),
        ChangeNotifierProvider(create: (_) => ShoppingListService()),
        ChangeNotifierProvider(create: (_) => StatisticsService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            // Título de la aplicación (se muestra en el task switcher de Android)
            title: 'CGestion',
            
            // Oculta el banner de debug en modo debug
            debugShowCheckedModeBanner: false,
            
            // Configuración de temas
            theme: themeService.lightTheme,
            darkTheme: themeService.darkTheme,
            themeMode: themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            
            // Pantalla inicial (splash screen que verifica autenticación)
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
