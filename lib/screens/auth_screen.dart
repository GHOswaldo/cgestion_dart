/// Pantalla de autenticación de la aplicación.
/// 
/// Proporciona la interfaz de inicio de sesión mediante Google Sign-In.
/// Esta es la primera pantalla que ve el usuario si no está autenticado.
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestor_alacena/screens/family_setup_screen.dart';
import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';
import 'package:gestor_alacena/widgets/theme_switch.dart';
import 'package:gestor_alacena/widgets/main_navigation.dart';

/// Widget de pantalla de autenticación.
/// 
/// Permite a los usuarios iniciar sesión con su cuenta de Google y
/// navega automáticamente a la pantalla correspondiente según el estado
/// del usuario (configuración de familia o navegación principal).
class AuthScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

/// Estado de la pantalla de autenticación.
/// 
/// Maneja el proceso de inicio de sesión y la navegación posterior.
class _AuthScreenState extends State<AuthScreen> {
  /// Indica si se está procesando la autenticación.
  /// 
  /// Se usa para mostrar un indicador de carga y deshabilitar
  /// el botón de inicio de sesión durante el proceso.
  bool _isLoading = false;

  /// Maneja el proceso de inicio de sesión con Google.
  /// 
  /// Flujo de autenticación:
  /// 1. Muestra indicador de carga
  /// 2. Intenta iniciar sesión con Google mediante [AuthService]
  /// 3. Si tiene éxito:
  ///    - Si el usuario no tiene familia: navega a [FamilySetupScreen]
  ///    - Si el usuario tiene familia: navega a [MainNavigation]
  /// 4. Si falla: muestra mensaje de error
  /// 
  /// La navegación usa [pushReplacement] para evitar que el usuario
  /// pueda volver a la pantalla de autenticación con el botón atrás.
  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    
    // Obtiene el servicio de autenticación del contexto
    final authService = context.read<AuthService>();
    
    // Intenta iniciar sesión
    final success = await authService.signInWithGoogle();
    
    // Verifica que el widget aún esté montado antes de usar el contexto
    if (!mounted) return;
    
    if (success) {
      // Determina a qué pantalla navegar según el estado del usuario
      if (authService.familyId == null) {
        // Usuario nuevo sin familia: configurar familia
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const FamilySetupScreen()),
        );
      } else {
        // Usuario con familia existente: ir a la aplicación
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainNavigation()),
        );
      }
    } else {
      // Muestra mensaje de error si la autenticación falló
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al iniciar sesión')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  /// Construye la interfaz de la pantalla de autenticación.
  /// 
  /// La UI incluye:
  /// - AppBar con switch de tema
  /// - Logo de la aplicación
  /// - Título y descripción
  /// - Botón de "Continuar con Google" o indicador de carga
  /// - Mensaje de seguridad
  /// 
  /// El diseño se adapta al tema actual (claro/oscuro) mediante [ThemeService].
  @override
  Widget build(BuildContext context) {
    // Obtiene el estado actual del tema (claro/oscuro)
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Scaffold(
      // AppBar transparente con el switch de tema
      appBar: AppBar(
        backgroundColor: const Color(0x00000000),
        elevation: 0,
        actions: const [
          ThemeSwitch(),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo de la aplicación
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.kitchen_rounded,
                    size: 56,
                    color: Color(0xFF34A853),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Título de la aplicación
                Text(
                  'CGestion',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Descripción de la aplicación
                Text(
                  'Administra el inventario de tu familia\nde forma simple y organizada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 64),
                
                // Botón de Google Sign-In o indicador de carga
                if (_isLoading)
                  const CircularProgressIndicator(
                    color: Color(0xFF34A853),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    // Logo de Google desde CDN oficial
                    icon: Image.network(
                      'https://www.google.com/images/branding/googleg/1x/googleg_standard_color_128dp.png',
                      width: 24,
                      height: 24,
                    ),
                    label: const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      // Colores adaptativos según el tema
                      backgroundColor: isDark 
                          ? const Color(0xFF2C2C2C) 
                          : Colors.white,
                      foregroundColor: isDark 
                          ? Colors.white 
                          : const Color(0xFF202124),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isDark 
                              ? Colors.grey.shade700 
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                // Mensaje de seguridad
                Text(
                  'Tus datos están seguros.',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.grey[600] : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
