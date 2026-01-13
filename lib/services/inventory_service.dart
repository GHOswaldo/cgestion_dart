/// Servicio de gestión de inventario.
/// 
/// Proporciona funcionalidad para administrar los productos en el inventario
/// de la familia, incluyendo carga de datos, actualización de cantidades,
/// búsqueda y registro de consumo.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo que representa un producto en el inventario.
/// 
/// Contiene toda la información de un producto almacenado en la alacena,
/// incluyendo detalles del catálogo, información personalizada y datos
/// de seguimiento como fechas y costos.
class InventoryItem {
  /// Identificador único del producto en el inventario.
  final String id;
  
  /// Código de barras del producto (opcional).
  /// Se obtiene al escanear productos del catálogo.
  final String? barcode;
  
  /// Nombre personalizado asignado por el usuario (opcional).
  /// Tiene prioridad sobre el nombre del catálogo al mostrarse.
  final String? customName;
  
  /// URL de imagen personalizada subida por el usuario (opcional).
  final String? customImageUrl;
  
  /// Cantidad disponible del producto.
  /// Se decrementa cuando se consume el producto.
  final double quantity;
  
  /// Unidad de medida del producto.
  /// Ejemplos: 'pz' (piezas), 'kg', 'lt', 'gr', etc.
  final String unit;
  
  /// Fecha en que se agregó el producto al inventario.
  /// Se usa para ordenar productos (más recientes primero).
  final DateTime purchaseDate;
  
  /// Fecha de caducidad del producto (opcional).
  /// Cuando está presente, se usa para alertas de productos próximos a vencer.
  final DateTime? expiryDate;
  
  /// Costo por unidad del producto.
  /// Se multiplica por la cantidad consumida al registrar en el log de consumo.
  final double costPerUnit;
  
  /// Nombre de la categoría del producto (ej: "Lácteos", "Carnes").
  /// Se obtiene de la relación con product_categories.
  final String? categoryName;
  
  /// ID de la categoría del producto.
  /// Se usa para registrar el consumo por categoría en las estadísticas.
  final int? categoryId;
  
  /// URL de la imagen del catálogo de productos.
  /// Se obtiene de la tabla product_catalog.
  final String? catalogImageUrl;

  /// Constructor del modelo InventoryItem.
  InventoryItem({
    required this.id,
    this.barcode,
    this.customName,
    this.customImageUrl,
    required this.quantity,
    required this.unit,
    required this.purchaseDate,
    this.expiryDate,
    required this.costPerUnit,
    this.categoryName,
    this.categoryId,
    this.catalogImageUrl,
  });

  /// Crea una instancia de InventoryItem desde un JSON.
  /// 
  /// Este factory constructor parsea la respuesta de Supabase que incluye
  /// joins con product_catalog y product_categories.
  /// 
  /// [json] Mapa con los datos del producto desde la base de datos.
  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      id: json['id'],
      barcode: json['barcode'],
      customName: json['custom_name'],
      customImageUrl: json['custom_image_url'],
      quantity: (json['quantity'] ?? 0).toDouble(),
      unit: json['unit'] ?? 'pz',
      purchaseDate: DateTime.parse(json['purchase_date']),
      expiryDate: json['expiry_date'] != null 
          ? DateTime.parse(json['expiry_date']) 
          : null,
      costPerUnit: (json['cost_per_unit'] ?? 0).toDouble(),
      // Acceso anidado a datos de categoría mediante join
      categoryName: json['product_catalog']?['product_categories']?['name'],
      categoryId: json['product_catalog']?['category_id'],
      catalogImageUrl: json['product_catalog']?['image_url'],
    );
  }

  /// Obtiene el nombre a mostrar del producto.
  /// 
  /// Lógica de prioridad:
  /// 1. Si existe customName y no está vacío: usa customName
  /// 2. Si no: retorna texto por defecto "Producto sin nombre"
  /// 
  /// El nombre del catálogo no se usa directamente aquí porque
  /// el usuario puede haber personalizado el nombre del producto.
  String get displayName {
    if (customName != null && customName!.isNotEmpty) {
      return customName!;
    }
    return 'Producto sin nombre';
  }

  /// Obtiene la URL de imagen a mostrar del producto.
  /// 
  /// Lógica de prioridad:
  /// 1. Si existe catalogImageUrl: usa imagen del catálogo (preferida)
  /// 2. Si no, pero existe customImageUrl: usa imagen personalizada
  /// 3. Si ninguna existe: retorna null (se mostrará un ícono por defecto)
  /// 
  /// Se prioriza la imagen del catálogo porque suele ser de mejor calidad.
  String? get imageUrl {
    return catalogImageUrl ?? customImageUrl;
  }
}

/// Servicio que gestiona el inventario de productos de la familia.
/// 
/// Este servicio extiende [ChangeNotifier] para notificar a los widgets
/// cuando cambia el estado del inventario, permitiendo actualizaciones
/// reactivas de la UI.
/// 
/// Funcionalidades principales:
/// - Cargar inventario desde Supabase con datos relacionados
/// - Actualizar cantidades de productos
/// - Eliminar productos del inventario
/// - Registrar consumo para estadísticas
/// - Búsqueda de productos por nombre
class InventoryService extends ChangeNotifier {
  /// Cliente de Supabase para operaciones de backend.
  final _supabase = Supabase.instance.client;
  
  /// Lista de productos actualmente en el inventario.
  List<InventoryItem> _items = [];
  
  /// Indica si se está cargando el inventario desde la base de datos.
  bool _isLoading = false;
  
  /// Getter público para acceder a la lista de productos.
  List<InventoryItem> get items => _items;
  
  /// Getter público para verificar el estado de carga.
  bool get isLoading => _isLoading;

  /// Carga el inventario completo de una familia desde Supabase.
  /// 
  /// Realiza un query complejo que incluye:
  /// - Datos del inventario (inventory_items)
  /// - Información del catálogo de productos (product_catalog)
  /// - Categorías de productos (product_categories)
  /// 
  /// Los productos se ordenan por fecha de compra descendente
  /// (más recientes primero).
  /// 
  /// [familyId] ID de la familia cuyo inventario se va a cargar.
  /// 
  /// Este método actualiza [_items] y notifica a los listeners
  /// dos veces: al inicio (con isLoading=true) y al finalizar
  /// (con isLoading=false y datos actualizados).
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await inventoryService.loadInventory(authService.familyId!);
  /// ```
  Future<void> loadInventory(String familyId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Query con joins para obtener información relacionada
      final response = await _supabase
          .from('inventory_items')
          .select('''
            *,
            product_catalog (
              name,
              category_id,
              image_url,
              product_categories (
                name
              )
            )
          ''')
          .eq('family_id', familyId)
          .order('purchase_date', ascending: false);
      
      // Convierte la respuesta JSON a objetos InventoryItem
      _items = (response as List)
          .map((item) => InventoryItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error cargando inventario: $e');
      _items = [];
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Actualiza la cantidad de un producto o lo elimina del inventario.
  /// 
  /// Comportamiento según la nueva cantidad:
  /// - Si newQuantity <= 0:
  ///   1. Registra el consumo completo en consumption_log (para estadísticas)
  ///   2. Elimina el producto del inventario
  /// - Si newQuantity > 0:
  ///   1. Actualiza la cantidad en la base de datos
  ///   2. Actualiza el objeto en la lista local
  /// 
  /// El registro de consumo incluye:
  /// - family_id: Para asociar el consumo a la familia
  /// - category_id: Para estadísticas por categoría
  /// - cost: Costo total del producto consumido (costPerUnit * quantity)
  /// 
  /// [itemId] ID del producto a actualizar.
  /// [newQuantity] Nueva cantidad del producto (0 para eliminar).
  /// [familyId] ID de la familia (necesario para el log de consumo).
  /// 
  /// Retorna `true` si la operación fue exitosa, `false` en caso contrario.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// // Actualizar cantidad
  /// await inventoryService.decrementQuantity(item.id, 5, familyId);
  /// 
  /// // Eliminar producto (consumo completo)
  /// await inventoryService.decrementQuantity(item.id, 0, familyId);
  /// ```
  Future<bool> decrementQuantity(String itemId, double newQuantity, String familyId) async {
    try {
      // Encuentra el producto en la lista local
      final item = _items.firstWhere((i) => i.id == itemId);
      
      if (newQuantity <= 0) {
        // Caso 1: Eliminar producto (consumo completo)
        
        // Registrar consumo solo si el producto tiene categoría
        if (item.categoryId != null) {
          await _supabase.from('consumption_log').insert({
            'family_id': familyId,
            'category_id': item.categoryId,
            'cost': item.costPerUnit * item.quantity, // Costo total del consumo
          });
        }
        
        // Eliminar del inventario en la base de datos
        await _supabase
            .from('inventory_items')
            .delete()
            .eq('id', itemId);
        
        // Eliminar de la lista local
        _items.removeWhere((i) => i.id == itemId);
      } else {
        // Caso 2: Actualizar cantidad
        
        // Actualizar en la base de datos
        await _supabase
            .from('inventory_items')
            .update({'quantity': newQuantity})
            .eq('id', itemId);
        
        // Actualizar en la lista local
        final index = _items.indexWhere((i) => i.id == itemId);
        if (index != -1) {
          // Crear nuevo objeto con la cantidad actualizada
          _items[index] = InventoryItem(
            id: item.id,
            barcode: item.barcode,
            customName: item.customName,
            customImageUrl: item.customImageUrl,
            quantity: newQuantity, // Nueva cantidad
            unit: item.unit,
            purchaseDate: item.purchaseDate,
            expiryDate: item.expiryDate,
            costPerUnit: item.costPerUnit,
            categoryName: item.categoryName,
            categoryId: item.categoryId,
            catalogImageUrl: item.catalogImageUrl,
          );
        }
      }
      
      // Notifica a los widgets que el inventario cambió
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error decrementando cantidad: $e');
      return false;
    }
  }

  /// Busca productos en el inventario por nombre.
  /// 
  /// Realiza una búsqueda case-insensitive que compara el query
  /// con el nombre de visualización del producto ([displayName]).
  /// 
  /// [query] Texto a buscar en los nombres de productos.
  /// 
  /// Retorna:
  /// - Si query está vacío: retorna todos los productos
  /// - Si query tiene texto: retorna solo productos que contienen el texto
  /// 
  /// La búsqueda se realiza sobre la lista en memoria (_items),
  /// no hace consultas a la base de datos.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final results = inventoryService.searchItems('leche');
  /// // Retorna productos con "leche" en su nombre
  /// ```
  List<InventoryItem> searchItems(String query) {
    if (query.isEmpty) return _items;
    
    final lowerQuery = query.toLowerCase();
    return _items.where((item) {
      return item.displayName.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
