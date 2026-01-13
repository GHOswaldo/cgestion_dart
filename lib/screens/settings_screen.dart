/// Pantalla de ajustes y configuración.
///
/// Permite a los usuarios gestionar su perfil, configuración de la aplicación,
/// opciones de familia (invitar miembros, salir de familia) y opciones de cuenta
/// (cerrar sesión). Incluye visualización del perfil del usuario con foto y
/// múltiples diálogos de confirmación para acciones importantes.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';
import 'package:gestor_alacena/widgets/theme_switch.dart';
import 'package:gestor_alacena/screens/auth_screen.dart';

/// Widget de la pantalla de ajustes.
///
/// Cuarta pestaña de la navegación principal que proporciona acceso
/// a todas las configuraciones de la aplicación y gestión de cuenta.
///
/// Es un StatelessWidget porque todo el estado se gestiona mediante
/// providers (AuthService y ThemeService).
class SettingsScreen extends StatelessWidget {
  /// Constructor const para optimizar el rendimiento.
  const SettingsScreen({super.key});

  /// Muestra un diálogo con el código de invitación de la familia.
  ///
  /// El diálogo incluye:
  /// - Código de invitación en grande con gradiente verde
  /// - Botón para copiar el código al portapapeles
  /// - Botón para cerrar el diálogo
  ///
  /// Si ocurre un error al obtener el código, muestra un SnackBar
  /// en lugar del diálogo.
  ///
  /// [context] Contexto de construcción para mostrar el diálogo.
  ///
  /// Ejemplo de uso:
  /// ```dart
  /// onTap: () => _showInviteDialog(context)
  /// ```
  void _showInviteDialog(BuildContext context) async {
    final authService = context.read<AuthService>();
    final isDark = context.read<ThemeService>().isDarkMode;

    // Obtener código de invitación de la familia
    final inviteCode = await authService.getInviteCode();

    // Verificar que el widget aún esté montado después de la operación async
    if (!context.mounted) return;

    if (inviteCode != null) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E1E1E)
              : const Color(0xFFFFFFFF),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icono decorativo de familia
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.family_restroom_rounded,
                    size: 32,
                    color: Color(0xFF34A853),
                  ),
                ),
                const SizedBox(height: 20),
                // Título del diálogo
                Text(
                  'Código de invitación',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFFFFFFF)
                        : const Color(0xFF202124),
                  ),
                ),
                const SizedBox(height: 12),
                // Instrucciones
                Text(
                  'Comparte este código con tu familia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? const Color(0xFFBDBDBD)
                        : const Color(0xFF757575),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                // Código de invitación destacado
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF34A853), Color(0xFF2E8B44)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    inviteCode,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFFFFFF),
                      letterSpacing: 6, // Espaciado para facilitar lectura
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Botones de acción
                Row(
                  children: [
                    // Botón cerrar
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: isDark
                                ? const Color(0xFF616161)
                                : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: const Text('Cerrar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón copiar al portapapeles
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Copiar código al portapapeles
                          Clipboard.setData(ClipboardData(text: inviteCode));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Código copiado al portapapeles'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text('Copiar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: const Color(0xFFFFFFFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mostrar error si no se pudo obtener el código
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error obteniendo código de invitación'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Muestra un diálogo de confirmación para salir de la familia.
  ///
  /// Esta acción es permanente y tiene las siguientes consecuencias:
  /// - El usuario pierde acceso al inventario compartido
  /// - Se cierra la sesión automáticamente
  /// - El usuario debe crear/unirse a otra familia para volver a usar la app
  ///
  /// El diálogo usa iconografía y colores rojos para indicar que es
  /// una acción destructiva.
  ///
  /// [context] Contexto de construcción para mostrar el diálogo.
  void _showLeaveConfirmation(BuildContext context) {
    final isDark = context.read<ThemeService>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de advertencia
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  size: 36,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              // Título
              Text(
                'Salir de tu familia',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 12),
              // Mensaje de advertencia con consecuencias
              Text(
                '¿Estás seguro de que deseas salir de tu familia?\n\nPerderás acceso a todo el inventario compartido y tu sesión se cerrará.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF757575),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              // Botones de acción
              Row(
                children: [
                  // Botón cancelar
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF616161)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón confirmar (destructivo)
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF44336),
                        foregroundColor: const Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        Navigator.of(context).pop();

                        final authService = context.read<AuthService>();
                        // Salir de la familia
                        await authService.leaveFamily();
                        // Cerrar sesión automáticamente
                        await authService.signOut();

                        if (context.mounted) {
                          // Navegar a pantalla de autenticación y limpiar stack
                          Navigator.of(
                            context,
                            rootNavigator: true,
                          ).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const AuthScreen(),
                            ),
                            (route) =>
                                false, // Eliminar todas las rutas anteriores
                          );
                        }
                      },
                      child: const Text(
                        'Salir',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra un diálogo de confirmación para cerrar sesión.
  ///
  /// Esta acción cierra la sesión del usuario pero mantiene su
  /// asociación con la familia. El usuario puede volver a iniciar
  /// sesión y tendrá acceso al mismo inventario.
  ///
  /// El diálogo usa iconografía y colores naranjas para indicar
  /// que es una acción importante pero no destructiva.
  ///
  /// [context] Contexto de construcción para mostrar el diálogo.
  void _showLogoutConfirmation(BuildContext context) {
    final isDark = context.read<ThemeService>().isDarkMode;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: isDark
            ? const Color(0xFF1E1E1E)
            : const Color(0xFFFFFFFF),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de salida
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.exit_to_app_rounded,
                  size: 32,
                  color: Color(0xFFFF9800),
                ),
              ),
              const SizedBox(height: 20),
              // Título
              Text(
                'Cerrar sesión',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: isDark
                      ? const Color(0xFFFFFFFF)
                      : const Color(0xFF202124),
                ),
              ),
              const SizedBox(height: 12),
              // Mensaje de confirmación
              Text(
                '¿Estás seguro de que deseas cerrar sesión?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF757575),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),
              // Botones de acción
              Row(
                children: [
                  // Botón cancelar
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                          color: isDark
                              ? const Color(0xFF616161)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Botón confirmar
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final authService = context.read<AuthService>();
                        await authService.signOut();

                        if (!context.mounted) return;

                        // Navegar a pantalla de autenticación y limpiar stack
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        'Cerrar sesión',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Construye la interfaz principal de la pantalla de ajustes.
  ///
  /// La pantalla se organiza en secciones:
  ///
  /// 1. **Tarjeta de perfil**:
  ///    - Foto de perfil (avatar de Google o icono por defecto)
  ///    - Nombre completo del usuario
  ///    - Correo electrónico
  ///
  /// 2. **Apariencia**:
  ///    - Toggle de tema claro/oscuro
  ///
  /// 3. **Familia**:
  ///    - Invitar a tu familia (mostrar código)
  ///    - Salir de tu familia (acción destructiva)
  ///
  /// 4. **Cuenta**:
  ///    - Cerrar sesión
  ///
  /// 5. **Información de la app**:
  ///    - Icono
  ///    - Nombre de la app
  ///    - Versión
  ///
  /// Todas las opciones usan el widget [_buildOptionTile] para
  /// mantener consistencia visual.
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ajustes',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [ThemeSwitch()],
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final user = authService.currentUser;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ===== TARJETA DE PERFIL =====
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF424242)
                        : const Color(0xFFEEEEEE),
                  ),
                ),
                child: Row(
                  children: [
                    // Avatar del usuario
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(32),
                        // Mostrar foto de Google si está disponible
                        image: user?.userMetadata?['avatar_url'] != null
                            ? DecorationImage(
                                image: NetworkImage(
                                  user!.userMetadata!['avatar_url'],
                                ),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      // Icono por defecto si no hay foto
                      child: user?.userMetadata?['avatar_url'] == null
                          ? const Icon(
                              Icons.person_rounded,
                              size: 32,
                              color: Color(0xFF34A853),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    // Información del usuario
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre del usuario
                          Text(
                            user?.userMetadata?['full_name'] ?? 'Usuario',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF202124),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Correo electrónico
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? const Color(0xFFBDBDBD)
                                  : const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== SECCIÓN: APARIENCIA =====
              Text(
                'Apariencia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 12),

              // Opción: Cambiar tema
              _buildOptionTile(
                context,
                icon: isDark
                    ? Icons.light_mode_rounded
                    : Icons.dark_mode_rounded,
                iconColor: isDark
                    ? const Color(0xFFFFC107)
                    : const Color(0xFF5F6368),
                title: isDark ? 'Modo claro' : 'Modo oscuro',
                subtitle: 'Cambiar tema de la aplicación',
                onTap: () => context.read<ThemeService>().toggleTheme(),
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // ===== SECCIÓN: FAMILIA =====
              Text(
                'Familia',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? const Color(0xFFBDBDBD)
                      : const Color(0xFF757575),
                ),
              ),
              const SizedBox(height: 12),

              // Opción: Invitar a la familia
              _buildOptionTile(
                context,
                icon: Icons.person_add_rounded,
                iconColor: const Color(0xFF34A853),
                title: 'Invitar a tu familia',
                subtitle: 'Comparte el código de invitación',
                onTap: () => _showInviteDialog(context),
                isDark: isDark,
              ),

              const SizedBox(height: 8),

              // Opción: Salir de la familia (destructiva)
              _buildOptionTile(
                context,
                icon: Icons.logout_rounded,
                iconColor: Colors.red,
                title: 'Salir de tu familia',
                subtitle: 'Perderás acceso al inventario compartido',
                onTap: () => _showLeaveConfirmation(context),
                isDark: isDark,
              ),

              const SizedBox(height: 24),

              // ===== SECCIÓN: CUENTA =====
              Text(
                'Cuenta',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),

              // Opción: Cerrar sesión
              _buildOptionTile(
                context,
                icon: Icons.exit_to_app_rounded,
                iconColor: Colors.orange,
                title: 'Cerrar sesión',
                subtitle: 'Salir de tu cuenta',
                onTap: () => _showLogoutConfirmation(context),
                isDark: isDark,
              ),

              const SizedBox(height: 40),

              // ===== INFORMACIÓN DE LA APP =====
              Center(
                child: Column(
                  children: [
                    // Logo de la app
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Image.asset(
                        'assets/icons/logo_wo_bg.png',
                        width: 32,
                        height: 32,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Nombre de la app
                    Text(
                      'CGestion',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Versión
                    Text(
                      'Beta 8.3.1',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          );
        },
      ),
    );
  }

  /// Construye un tile de opción reutilizable con estilo consistente.
  ///
  /// Cada tile incluye:
  /// - Icono con fondo de color
  /// - Título en negrita
  /// - Subtítulo descriptivo
  /// - Icono de chevron a la derecha
  /// - Efecto de tap
  ///
  /// [context] Contexto de construcción.
  /// [icon] Icono a mostrar.
  /// [iconColor] Color del icono y fondo.
  /// [title] Título principal del tile.
  /// [subtitle] Descripción secundaria.
  /// [onTap] Callback al tocar el tile.
  /// [isDark] Indica si el tema es oscuro.
  ///
  /// Retorna un [Container] con [ListTile] estilizado.
  Widget _buildOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF424242) : const Color(0xFFEEEEEE),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Icono con fondo de color
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        // Título
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
          ),
        ),
        // Subtítulo
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
          ),
        ),
        // Indicador visual de navegación
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: isDark ? const Color(0xFF757575) : const Color(0xFFBDBDBD),
        ),
      ),
    );
  }
}
