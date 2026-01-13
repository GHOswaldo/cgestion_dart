/// Servicio de gestión de lista de compras.
/// 
/// Proporciona funcionalidad para administrar la lista de productos que
/// la familia necesita comprar, incluyendo el registro de productos en
/// el inventario, gestión del catálogo de productos y subida de imágenes.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo que representa un producto en la lista de compras.
/// 
/// Contiene la información básica de un producto pendiente de compra,
/// incluyendo su estado de verificación (checked/unchecked).
class ShoppingListItem {
  /// Identificador único del producto en la lista.
  final String id;
  
  /// Nombre del producto a comprar.
  final String productName;
  
  /// Indica si el producto fue marcado como verificado.
  /// Útil para marcar productos ya comprados antes de registrarlos.
  final bool isChecked;
  
  /// Fecha y hora en que se agregó el producto a la lista.
  final DateTime createdAt;

  /// Constructor del modelo ShoppingListItem.
  ShoppingListItem({
    required this.id,
    required this.productName,
    required this.isChecked,
    required this.createdAt,
  });

  /// Crea una instancia de ShoppingListItem desde un JSON.
  /// 
  /// [json] Mapa con los datos del producto desde la base de datos.
  factory ShoppingListItem.fromJson(Map<String, dynamic> json) {
    return ShoppingListItem(
      id: json['id'],
      productName: json['product_name'],
      isChecked: json['is_checked'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}

/// Modelo que representa una categoría de productos.
/// 
/// Las categorías se usan para organizar productos y generar
/// estadísticas de consumo por tipo de producto (ej: Lácteos, Carnes).
class ProductCategory {
  /// Identificador único de la categoría.
  final int id;
  
  /// Nombre descriptivo de la categoría.
  final String name;

  /// Constructor del modelo ProductCategory.
  ProductCategory({required this.id, required this.name});

  /// Crea una instancia de ProductCategory desde un JSON.
  /// 
  /// [json] Mapa con los datos de la categoría desde la base de datos.
  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: json['id'],
      name: json['name'],
    );
  }
}

/// Modelo que representa un producto en el catálogo compartido.
/// 
/// El catálogo de productos es una base de datos compartida entre todas
/// las familias que permite reutilizar información de productos ya registrados,
/// identificados por su código de barras.
class CatalogProduct {
  /// Código de barras único del producto.
  final String barcode;
  
  /// Nombre del producto.
  final String name;
  
  /// ID de la categoría a la que pertenece (opcional).
  final int? categoryId;
  
  /// URL de la imagen del producto (opcional).
  /// Se almacena en Supabase Storage.
  final String? imageUrl;

  /// Constructor del modelo CatalogProduct.
  CatalogProduct({
    required this.barcode,
    required this.name,
    this.categoryId,
    this.imageUrl,
  });

  /// Crea una instancia de CatalogProduct desde un JSON.
  /// 
  /// [json] Mapa con los datos del producto del catálogo.
  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      barcode: json['barcode'],
      name: json['name'],
      categoryId: json['category_id'],
      imageUrl: json['image_url'],
    );
  }
}

/// Servicio que gestiona la lista de compras y el catálogo de productos.
/// 
/// Este servicio extiende [ChangeNotifier] para notificar a los widgets
/// cuando cambia el estado de la lista de compras.
/// 
/// Funcionalidades principales:
/// - Gestión de lista de compras (agregar, eliminar, marcar)
/// - Carga de categorías de productos
/// - Búsqueda en catálogo por código de barras
/// - Subida de imágenes de productos
/// - Registro de productos comprados en el inventario
class ShoppingListService extends ChangeNotifier {
  /// Cliente de Supabase para operaciones de backend.
  final _supabase = Supabase.instance.client;
  
  /// Lista de productos pendientes de compra.
  List<ShoppingListItem> _items = [];
  
  /// Lista de categorías disponibles para clasificar productos.
  List<ProductCategory> _categories = [];
  
  /// Indica si se está cargando información desde la base de datos.
  bool _isLoading = false;
  
  /// Getter público para acceder a la lista de compras.
  List<ShoppingListItem> get items => _items;
  
  /// Getter público para acceder a las categorías.
  List<ProductCategory> get categories => _categories;
  
  /// Getter público para verificar el estado de carga.
  bool get isLoading => _isLoading;

  /// Carga la lista de compras de una familia desde Supabase.
  /// 
  /// Los productos se ordenan por fecha de creación descendente
  /// (más recientes primero).
  /// 
  /// [familyId] ID de la familia cuya lista de compras se va a cargar.
  /// 
  /// Este método actualiza [_items] y notifica a los listeners
  /// dos veces: al inicio (con isLoading=true) y al finalizar
  /// (con isLoading=false y datos actualizados).
  Future<void> loadShoppingList(String familyId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final response = await _supabase
          .from('shopping_list_items')
          .select()
          .eq('family_id', familyId)
          .order('created_at', ascending: false);
      
      _items = (response as List)
          .map((item) => ShoppingListItem.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error cargando lista de compras: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Carga todas las categorías de productos disponibles.
  /// 
  /// Las categorías son compartidas entre todas las familias
  /// y se usan para clasificar productos y generar estadísticas.
  /// 
  /// Este método se llama generalmente al inicializar la pantalla
  /// de lista de compras para tener las categorías disponibles
  /// al registrar productos.
  Future<void> loadCategories() async {
    try {
      final response = await _supabase
          .from('product_categories')
          .select();
      
      _categories = (response as List)
          .map((cat) => ProductCategory.fromJson(cat))
          .toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error cargando categorías: $e');
    }
  }

  /// Busca un producto en el catálogo por su código de barras.
  /// 
  /// El catálogo compartido permite reutilizar información de productos
  /// que ya fueron registrados por cualquier familia, evitando duplicar
  /// datos como nombre, categoría e imagen.
  /// 
  /// [barcode] Código de barras del producto a buscar.
  /// 
  /// Retorna:
  /// - [CatalogProduct] si se encuentra el producto en el catálogo
  /// - `null` si no existe o ocurre un error
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final product = await service.getProductByBarcode('7501234567890');
  /// if (product != null) {
  ///   print('Producto encontrado: ${product.name}');
  /// }
  /// ```
  Future<CatalogProduct?> getProductByBarcode(String barcode) async {
    try {
      final response = await _supabase
          .from('product_catalog')
          .select()
          .eq('barcode', barcode)
          .maybeSingle();
      
      if (response != null) {
        return CatalogProduct.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error buscando producto por código: $e');
      return null;
    }
  }

  /// Agrega un nuevo producto a la lista de compras.
  /// 
  /// [familyId] ID de la familia que agrega el producto.
  /// [productName] Nombre del producto a comprar.
  /// [userId] ID del usuario que agregó el producto (para auditoría).
  /// 
  /// Retorna `true` si el producto se agregó exitosamente,
  /// `false` en caso contrario.
  /// 
  /// Después de agregar el producto, recarga automáticamente
  /// la lista completa para reflejar el cambio en la UI.
  Future<bool> addItem(String familyId, String productName, String userId) async {
    try {
      await _supabase
          .from('shopping_list_items')
          .insert({
            'family_id': familyId,
            'product_name': productName,
            'added_by': userId,
          });
      
      // Recargar lista para incluir el nuevo producto
      await loadShoppingList(familyId);
      return true;
    } catch (e) {
      debugPrint('Error agregando producto: $e');
      return false;
    }
  }

  /// Marca o desmarca un producto como verificado.
  /// 
  /// Esta funcionalidad permite a los usuarios marcar productos
  /// mientras compran, para llevar un control de lo que ya tienen.
  /// 
  /// [itemId] ID del producto a actualizar.
  /// [isChecked] Nuevo estado del checkbox (true = marcado).
  /// 
  /// Retorna `true` si la actualización fue exitosa,
  /// `false` en caso contrario.
  /// 
  /// La actualización se realiza tanto en la base de datos
  /// como en la lista local para una respuesta inmediata en la UI.
  Future<bool> toggleCheck(String itemId, bool isChecked) async {
    try {
      // Actualizar en la base de datos
      await _supabase
          .from('shopping_list_items')
          .update({'is_checked': isChecked})
          .eq('id', itemId);
      
      // Actualizar en la lista local
      final index = _items.indexWhere((i) => i.id == itemId);
      if (index != -1) {
        _items[index] = ShoppingListItem(
          id: _items[index].id,
          productName: _items[index].productName,
          isChecked: isChecked,
          createdAt: _items[index].createdAt,
        );
        notifyListeners();
      }
      
      return true;
    } catch (e) {
      debugPrint('Error actualizando check: $e');
      return false;
    }
  }

  /// Elimina un producto de la lista de compras.
  /// 
  /// [itemId] ID del producto a eliminar.
  /// 
  /// Retorna `true` si el producto se eliminó exitosamente,
  /// `false` en caso contrario.
  /// 
  /// La eliminación se realiza tanto en la base de datos
  /// como en la lista local.
  Future<bool> deleteItem(String itemId) async {
    try {
      await _supabase
          .from('shopping_list_items')
          .delete()
          .eq('id', itemId);
      
      _items.removeWhere((i) => i.id == itemId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error eliminando producto: $e');
      return false;
    }
  }

  /// Sube una imagen de producto a Supabase Storage.
  /// 
  /// Las imágenes se almacenan en el bucket 'product-images' con un
  /// nombre único basado en el código de barras y timestamp.
  /// 
  /// [barcode] Código de barras del producto (usado en el nombre del archivo).
  /// [imageBytes] Bytes de la imagen a subir.
  /// 
  /// Retorna:
  /// - URL pública de la imagen si se subió exitosamente
  /// - `null` si ocurrió un error
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final bytes = await file.readAsBytes();
  /// final url = await service.uploadProductImage('7501234567890', bytes);
  /// if (url != null) {
  ///   print('Imagen disponible en: $url');
  /// }
  /// ```
  Future<String?> uploadProductImage(String barcode, Uint8List imageBytes) async {
    try {
      // Generar nombre único para la imagen
      final fileName = 'products/$barcode-${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Subir imagen al storage
      await _supabase.storage
          .from('product-images')
          .uploadBinary(fileName, imageBytes);
      
      // Obtener URL pública de la imagen
      final imageUrl = _supabase.storage
          .from('product-images')
          .getPublicUrl(fileName);
      
      return imageUrl;
    } catch (e) {
      debugPrint('Error subiendo imagen: $e');
      return null;
    }
  }

  /// Registra un producto comprado en el inventario.
  /// 
  /// Este es el proceso completo que ocurre cuando un usuario marca
  /// un producto de la lista de compras como "comprado":
  /// 
  /// 1. Si el producto tiene código de barras:
  ///    - Busca si ya existe en el catálogo
  ///    - Si no existe: lo crea con toda su información
  ///    - Si existe pero no tiene imagen: actualiza la imagen
  /// 2. Agrega el producto al inventario de la familia
  /// 3. Elimina el producto de la lista de compras
  /// 
  /// Parámetros:
  /// [familyId] ID de la familia que registra el producto.
  /// [itemId] ID del producto en la lista de compras (para eliminarlo).
  /// [productName] Nombre del producto.
  /// [barcode] Código de barras (opcional).
  /// [quantity] Cantidad comprada.
  /// [unit] Unidad de medida ('pz', 'kg', 'lt').
  /// [expiryDate] Fecha de caducidad.
  /// [categoryId] ID de la categoría del producto.
  /// [costPerUnit] Costo por unidad.
  /// [imageUrl] URL de la imagen del producto (opcional).
  /// 
  /// Retorna `true` si todo el proceso fue exitoso, `false` en caso contrario.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// final success = await service.registerProduct(
  ///   familyId: 'abc123',
  ///   itemId: 'item456',
  ///   productName: 'Leche entera',
  ///   barcode: '7501234567890',
  ///   quantity: 2,
  ///   unit: 'lt',
  ///   expiryDate: DateTime.now().add(Duration(days: 7)),
  ///   categoryId: 1,
  ///   costPerUnit: 25.50,
  ///   imageUrl: 'https://...',
  /// );
  /// ```
  Future<bool> registerProduct({
    required String familyId,
    required String itemId,
    required String productName,
    String? barcode,
    required double quantity,
    required String unit,
    required DateTime expiryDate,
    required int categoryId,
    required double costPerUnit,
    String? imageUrl,
  }) async {
    try {
      // Paso 1: Gestionar catálogo de productos (si hay código de barras)
      if (barcode != null && barcode.isNotEmpty) {
        final existing = await getProductByBarcode(barcode);
        
        if (existing == null) {
          // Crear nuevo producto en el catálogo
          await _supabase
              .from('product_catalog')
              .insert({
                'barcode': barcode,
                'name': productName,
                'category_id': categoryId,
                'image_url': imageUrl,
                'created_by_family': familyId,
              });
        } else if (imageUrl != null && existing.imageUrl == null) {
          // Actualizar imagen si el producto existe pero no tenía imagen
          await _supabase
              .from('product_catalog')
              .update({'image_url': imageUrl})
              .eq('barcode', barcode);
        }
      }
      
      // Paso 2: Agregar producto al inventario
      await _supabase
          .from('inventory_items')
          .insert({
            'family_id': familyId,
            'barcode': barcode,
            'custom_name': productName,
            'custom_image_url': imageUrl,
            'quantity': quantity,
            'unit': unit,
            'expiry_date': expiryDate.toIso8601String(),
            'cost_per_unit': costPerUnit,
          });
      
      // Paso 3: Eliminar de la lista de compras
      await deleteItem(itemId);
      
      return true;
    } catch (e) {
      debugPrint('Error registrando producto: $e');
      return false;
    }
  }
}
