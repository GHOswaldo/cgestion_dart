/// Pantalla de splash (carga inicial).
/// 
/// Primera pantalla que se muestra al iniciar la aplicación.
/// Verifica el estado de autenticación del usuario y navega a la
/// pantalla correspondiente (autenticación o navegación principal).
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestor_alacena/screens/auth_screen.dart';
import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/widgets/main_navigation.dart';

/// Widget de la pantalla de splash.
/// 
/// Muestra el logo de la aplicación con un indicador de carga
/// mientras verifica si el usuario está autenticado. Esta pantalla
/// proporciona una transición suave al inicio de la aplicación.
class SplashScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// Estado de la pantalla de splash.
/// 
/// Gestiona la verificación de autenticación y la navegación inicial.
class _SplashScreenState extends State<SplashScreen> {
  /// Inicializa el estado y comienza la verificación de autenticación.
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  /// Verifica el estado de autenticación y navega a la pantalla apropiada.
  /// 
  /// Flujo de verificación:
  /// 1. Espera 3 segundos mostrando el logo (para dar tiempo a cargar servicios)
  /// 2. Verifica si el usuario está autenticado usando [AuthService]
  /// 3. Navega según el resultado:
  ///    - Autenticado: → [MainNavigation]
  ///    - No autenticado: → [AuthScreen]
  /// 
  /// Usa [pushReplacement] para evitar que el usuario pueda volver
  /// al splash screen con el botón de retroceso.
  /// 
  /// Las verificaciones de [mounted] previenen errores si el widget
  /// se destruye durante operaciones asíncronas.
  Future<void> _checkAuth() async {
    // Esperar 3 segundos para mostrar el logo y permitir inicialización
    await Future.delayed(const Duration(seconds: 3));
    
    // Verificar que el widget aún esté montado después del delay
    if (!mounted) return;
    
    // Obtener el servicio de autenticación
    final authService = context.read<AuthService>();
    
    // Verificar si hay una sesión activa y cargar datos del usuario
    final isAuthenticated = await authService.checkAuthentication();
    
    // Verificar nuevamente que el widget aún esté montado
    if (!mounted) return;
    
    // Navegar según el estado de autenticación
    if (isAuthenticated) {
      // Usuario autenticado: ir a navegación principal
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Usuario no autenticado: ir a pantalla de login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthScreen()),
      );
    }
  }

  /// Construye la interfaz de la pantalla de splash.
  /// 
  /// La pantalla muestra:
  /// - Fondo verde (color principal de la app)
  /// - Icono de cocina (logo de la app)
  /// - Nombre de la aplicación
  /// - Indicador de carga circular
  /// 
  /// El diseño es simple y centrado, proporcionando una experiencia
  /// de carga profesional mientras se inicializa la aplicación.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Fondo verde característico de la app
      backgroundColor: const Color(0xFF34A853),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo de la aplicación
            Image.asset(
              'assets/icons/logo_wo_bg.png',
              width: 300,
              height: 300,
              fit: BoxFit.contain
            ),
            const SizedBox(height: 30),
            // Nombre de la aplicación
            const Text(
              'CGestion',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(9, 64, 51, 1),
              ),
            ),
            const SizedBox(height: 48),
            // Indicador de carga
            const CircularProgressIndicator(
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
