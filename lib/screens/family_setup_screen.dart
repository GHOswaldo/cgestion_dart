/// Pantalla de configuración de familia.
/// 
/// Esta pantalla se muestra cuando un usuario nuevo se autentica por primera vez
/// y no pertenece a ninguna familia. Permite al usuario elegir entre:
/// - Crear una nueva familia (convirtiéndose en administrador)
/// - Unirse a una familia existente mediante un código de invitación
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:gestor_alacena/widgets/main_navigation.dart';
import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';

/// Widget de pantalla de configuración de familia.
/// 
/// Proporciona la interfaz para que los usuarios nuevos puedan crear
/// o unirse a una familia antes de acceder a la aplicación principal.
class FamilySetupScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

/// Estado de la pantalla de configuración de familia.
/// 
/// Gestiona los formularios de creación y unión a familia, así como
/// el estado de carga durante las operaciones asíncronas.
class _FamilySetupScreenState extends State<FamilySetupScreen> {
  /// Controlador para el campo de texto del nombre de la familia.
  /// 
  /// Se usa cuando el usuario decide crear una nueva familia.
  final _familyNameController = TextEditingController();
  
  /// Controlador para el campo de texto del código de invitación.
  /// 
  /// Se usa cuando el usuario decide unirse a una familia existente.
  final _inviteCodeController = TextEditingController();
  
  /// Indica si se está procesando una operación asíncrona.
  /// 
  /// Cuando es `true`, se muestra un indicador de carga y se
  /// deshabilitan las interacciones del usuario.
  bool _isLoading = false;

  /// Libera los recursos de los controladores al destruir el widget.
  /// 
  /// Es importante liberar los controladores para evitar fugas de memoria.
  @override
  void dispose() {
    _familyNameController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  /// Crea una nueva familia con el nombre proporcionado por el usuario.
  /// 
  /// Proceso:
  /// 1. Valida que el nombre no esté vacío
  /// 2. Muestra indicador de carga
  /// 3. Llama a [AuthService.createFamily] con el nombre ingresado
  /// 4. Si tiene éxito: navega a [MainNavigation]
  /// 5. Si falla: muestra mensaje de error
  /// 
  /// El usuario que crea la familia automáticamente se convierte en
  /// administrador y puede generar códigos de invitación para otros miembros.
  Future<void> _createFamily() async {
    // Validación del nombre de familia
    if (_familyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el nombre de la familia')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final authService = context.read<AuthService>();
    final success = await authService.createFamily(_familyNameController.text);
    
    // Verifica que el widget aún esté montado
    if (!mounted) return;
    
    if (success) {
      // Navega a la aplicación principal tras crear la familia exitosamente
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Muestra error si no se pudo crear la familia
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al crear la familia')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  /// Une al usuario a una familia existente mediante un código de invitación.
  /// 
  /// Proceso:
  /// 1. Valida que el código no esté vacío
  /// 2. Muestra indicador de carga
  /// 3. Llama a [AuthService.joinFamily] con el código ingresado
  /// 4. Si tiene éxito: navega a [MainNavigation]
  /// 5. Si falla: muestra mensaje de error (código inválido)
  /// 
  /// El código de invitación es único por familia y puede ser compartido
  /// por el administrador para permitir que otros usuarios se unan.
  Future<void> _joinFamily() async {
    // Validación del código de invitación
    if (_inviteCodeController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de invitación')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final authService = context.read<AuthService>();
    final success = await authService.joinFamily(_inviteCodeController.text);
    
    // Verifica que el widget aún esté montado
    if (!mounted) return;
    
    if (success) {
      // Navega a la aplicación principal tras unirse exitosamente
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigation()),
      );
    } else {
      // Muestra error si el código es inválido o no existe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código de invitación inválido')),
      );
    }
    
    setState(() => _isLoading = false);
  }

  /// Muestra un diálogo modal para crear una nueva familia.
  /// 
  /// El diálogo contiene:
  /// - Campo de texto para ingresar el nombre de la familia
  /// - Botón de cancelar (cierra el diálogo)
  /// - Botón de crear (cierra el diálogo y ejecuta [_createFamily])
  /// 
  /// El campo de texto tiene autofocus para mejorar la experiencia del usuario.
  void _showCreateFamilyDialog() {
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear nueva Familia'),
        content: TextField(
          controller: _familyNameController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la Familia',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _createFamily();
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    );
  }

  /// Muestra un diálogo modal para unirse a una familia existente.
  /// 
  /// El diálogo contiene:
  /// - Campo de texto para ingresar el código de invitación
  /// - Botón de cancelar (cierra el diálogo)
  /// - Botón de unirse (cierra el diálogo y ejecuta [_joinFamily])
  /// 
  /// El campo de texto:
  /// - Tiene autofocus para mejorar la experiencia
  /// - No capitaliza automáticamente (los códigos son case-sensitive)
  /// - Muestra un ejemplo de formato en el hint
  void _showJoinFamilyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unirse a una Familia'),
        content: TextField(
          controller: _inviteCodeController,
          decoration: const InputDecoration(
            labelText: 'Código de invitación',
            border: OutlineInputBorder(),
            hintText: 'Ej: abc123de',
          ),
          autofocus: true,
          // Desactiva capitalización automática para códigos
          textCapitalization: TextCapitalization.none,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _joinFamily();
            },
            child: const Text('Unirse'),
          ),
        ],
      ),
    );
  }

  /// Construye la interfaz de la pantalla de configuración de familia.
  /// 
  /// La UI se adapta al estado de carga:
  /// - Si [_isLoading] es true: muestra un indicador de carga centrado
  /// - Si [_isLoading] es false: muestra las opciones de configuración
  /// 
  /// La pantalla incluye:
  /// - AppBar con título y botón de cambio de tema
  /// - Icono de familia
  /// - Título y descripción explicativa
  /// - Botón para crear nueva familia (color sólido, acción principal)
  /// - Botón para unirse a familia (outlined, acción secundaria)
  /// 
  /// El diseño es responsive y se adapta al tema actual (claro/oscuro).
  @override
  Widget build(BuildContext context) {
    // Obtiene el estado actual del tema
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Configurar Familia',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Botón para alternar entre tema claro y oscuro
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            tooltip: isDark ? 'Modo claro' : 'Modo oscuro',
            onPressed: () => context.read<ThemeService>().toggleTheme(),
          ),
        ],
      ),
      body: _isLoading
          // Muestra indicador de carga cuando se está procesando una operación
          ? const Center(child: CircularProgressIndicator())
          // Muestra la interfaz de configuración cuando no hay operaciones en curso
          : Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icono decorativo de familia
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        // ignore: deprecated_member_use
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.family_restroom_rounded,
                        size: 48,
                        color: Color(0xFF34A853),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Título principal
                    Text(
                      '¿Qué deseas hacer?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Descripción de las opciones disponibles
                    Text(
                      'Crea una nueva Familia o únete a una existente',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Botón principal: Crear nueva familia
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _showCreateFamilyDialog,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Crear una nueva Familia'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: const Color(0xFFFFFFFF),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Botón secundario: Unirse a familia existente
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _showJoinFamilyDialog,
                        icon: const Icon(Icons.group_add_rounded),
                        label: const Text('Unirse a una familia'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(18),
                          foregroundColor: const Color(0xFF34A853),
                          side: const BorderSide(color: Color(0xFF34A853)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
