/// Servicio de autenticación y gestión de sesión.
/// 
/// Proporciona toda la funcionalidad relacionada con la autenticación de usuarios,
/// gestión de familias y sesión. Utiliza Google Sign-In para la autenticación
/// y Supabase para el almacenamiento de datos de usuario.
library;

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Servicio que gestiona la autenticación y el estado de la sesión del usuario.
/// 
/// Este servicio extiende [ChangeNotifier] para notificar a los widgets
/// cuando cambia el estado de autenticación o la información de la familia.
/// 
/// Funcionalidades principales:
/// - Autenticación con Google Sign-In
/// - Gestión de familias (crear, unirse, salir)
/// - Persistencia del estado de autenticación
/// - Generación y validación de códigos de invitación
class AuthService extends ChangeNotifier {
  /// Cliente de Supabase para operaciones de backend.
  final _supabase = Supabase.instance.client;
  
  /// Cliente de Google Sign-In configurado con el ID del cliente OAuth.
  /// 
  /// El serverClientId es necesario para la autenticación OAuth en Android.
  final _googleSignIn = GoogleSignIn(
    serverClientId: ''
  );
  
  /// Usuario actual autenticado en Supabase.
  /// 
  /// Retorna `null` si no hay usuario autenticado.
  User? get currentUser => _supabase.auth.currentUser;
  
  /// Indica si hay un usuario autenticado actualmente.
  /// 
  /// Retorna `true` si existe un usuario activo, `false` en caso contrario.
  bool get isAuthenticated => currentUser != null;
  
  /// ID de la familia a la que pertenece el usuario actual.
  /// 
  /// Es `null` si el usuario no pertenece a ninguna familia.
  String? _familyId;
  
  /// Getter público para el ID de la familia.
  String? get familyId => _familyId;
  
  /// Verifica si el usuario está autenticado y carga su información.
  /// 
  /// Este método debe llamarse al iniciar la aplicación (generalmente en
  /// el SplashScreen) para restaurar la sesión del usuario si existe.
  /// 
  /// Retorna `true` si el usuario está autenticado, `false` en caso contrario.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final isAuth = await authService.checkAuthentication();
  /// if (isAuth) {
  ///   // Navegar a pantalla principal
  /// } else {
  ///   // Navegar a pantalla de login
  /// }
  /// ```
  Future<bool> checkAuthentication() async {
    if (currentUser != null) {
      await _loadFamilyId();
      return true;
    }
    return false;
  }
  
  /// Carga el ID de familia del usuario desde la base de datos.
  /// 
  /// Este método es privado y se llama automáticamente después de:
  /// - Verificar la autenticación
  /// - Iniciar sesión
  /// - Crear una familia
  /// - Unirse a una familia
  /// 
  /// Si ocurre un error, solo se imprime en consola y no se propaga
  /// para evitar interrumpir el flujo de autenticación.
  Future<void> _loadFamilyId() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('family_id')
          .eq('id', currentUser!.id)
          .single();
      
      _familyId = response['family_id'];
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando family_id: $e');
    }
  }
  
  /// Inicia sesión con Google Sign-In.
  /// 
  /// Proceso de autenticación:
  /// 1. Abre el selector de cuenta de Google
  /// 2. Obtiene los tokens de autenticación
  /// 3. Autentica al usuario en Supabase usando los tokens
  /// 4. Carga la información de la familia del usuario
  /// 
  /// Retorna `true` si la autenticación fue exitosa, `false` en caso contrario.
  /// 
  /// Posibles casos de fallo:
  /// - Usuario cancela el inicio de sesión
  /// - Error de red
  /// - Tokens inválidos
  /// - Error en Supabase
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final success = await authService.signInWithGoogle();
  /// if (success) {
  ///   print('Usuario autenticado: ${authService.currentUser?.email}');
  /// }
  /// ```
  Future<bool> signInWithGoogle() async {
    try {
      // Paso 1: Obtener cuenta de Google
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false; // Usuario canceló
      
      // Paso 2: Obtener tokens de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      // Paso 3: Autenticar en Supabase con los tokens
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );
      
      // Paso 4: Cargar información adicional si la autenticación fue exitosa
      if (response.user != null) {
        await _loadFamilyId();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error en Google Sign In: $e');
      return false;
    }
  }
  
  /// Crea una nueva familia con el usuario actual como administrador.
  /// 
  /// Proceso:
  /// 1. Inserta un nuevo registro en la tabla `families` con el nombre proporcionado
  /// 2. Actualiza el perfil del usuario para asociarlo a la familia
  /// 3. Establece el rol del usuario como 'admin'
  /// 4. Actualiza el estado local del servicio
  /// 
  /// [familyName] Nombre de la familia a crear.
  /// 
  /// Retorna `true` si la familia se creó exitosamente, `false` en caso contrario.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final success = await authService.createFamily('Familia García');
  /// if (success) {
  ///   print('Familia creada con ID: ${authService.familyId}');
  /// }
  /// ```
  Future<bool> createFamily(String familyName) async {
    try {
      // Crear registro de familia
      final response = await _supabase
          .from('families')
          .insert({'name': familyName})
          .select()
          .single();
      
      final familyId = response['id'];
      
      // Asociar usuario a la familia como administrador
      await _supabase
          .from('profiles')
          .update({
            'family_id': familyId,
            'role': 'admin',
          })
          .eq('id', currentUser!.id);
      
      _familyId = familyId;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error creando familia: $e');
      return false;
    }
  }
  
  /// Permite al usuario unirse a una familia existente mediante un código de invitación.
  /// 
  /// Proceso:
  /// 1. Busca la familia con el código de invitación proporcionado
  /// 2. Actualiza el perfil del usuario para asociarlo a la familia encontrada
  /// 3. Actualiza el estado local del servicio
  /// 
  /// [inviteCode] Código de invitación único de la familia.
  /// 
  /// Retorna `true` si se unió exitosamente, `false` en caso contrario.
  /// 
  /// Posibles casos de error:
  /// - Código de invitación inválido o no existe
  /// - Error de red
  /// - Error al actualizar el perfil
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final success = await authService.joinFamily('ABC123XYZ');
  /// if (success) {
  ///   print('Te has unido a la familia');
  /// }
  /// ```
  Future<bool> joinFamily(String inviteCode) async {
    try {
      // Buscar familia por código de invitación
      final response = await _supabase
          .from('families')
          .select('id')
          .eq('invite_code', inviteCode)
          .single();
      
      final familyId = response['id'];
      
      // Asociar usuario a la familia
      await _supabase
          .from('profiles')
          .update({'family_id': familyId})
          .eq('id', currentUser!.id);
      
      _familyId = familyId;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error uniéndose a familia: $e');
      return false;
    }
  }
  
  /// Obtiene el código de invitación de la familia actual.
  /// 
  /// Este código puede compartirse con otros usuarios para que se unan a la familia.
  /// Requiere que el usuario actual pertenezca a una familia ([familyId] no null).
  /// 
  /// Retorna el código de invitación o `null` si ocurre un error o el usuario
  /// no pertenece a ninguna familia.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final code = await authService.getInviteCode();
  /// if (code != null) {
  ///   print('Comparte este código: $code');
  /// }
  /// ```
  Future<String?> getInviteCode() async {
    try {
      final response = await _supabase
          .from('families')
          .select('invite_code')
          .eq('id', _familyId!)
          .single();
      
      return response['invite_code'];
    } catch (e) {
      debugPrint('Error obteniendo código de invitación: $e');
      return null;
    }
  }
  
  /// Cierra la sesión del usuario actual.
  /// 
  /// Proceso:
  /// 1. Cierra sesión en Google Sign-In
  /// 2. Cierra sesión en Supabase
  /// 3. Limpia el estado local (familyId)
  /// 4. Notifica a los listeners del cambio
  /// 
  /// Después de llamar este método, el usuario será redirigido a la
  /// pantalla de autenticación.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await authService.signOut();
  /// // Navegar a pantalla de login
  /// ```
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
    _familyId = null;
    notifyListeners();
  }
  
  /// Permite al usuario salir de su familia actual.
  /// 
  /// Este método elimina la asociación del usuario con su familia,
  /// pero no elimina su cuenta ni cierra su sesión. El usuario puede
  /// posteriormente crear una nueva familia o unirse a otra.
  /// 
  /// Retorna `true` si se salió exitosamente, `false` en caso contrario.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final success = await authService.leaveFamily();
  /// if (success) {
  ///   // Navegar a pantalla de configuración de familia
  /// }
  /// ```
  Future<bool> leaveFamily() async {
    try {
      await _supabase
          .from('profiles')
          .update({'family_id': null})
          .eq('id', currentUser!.id);
      
      _familyId = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error saliendo de familia: $e');
      return false;
    }
  }
}
