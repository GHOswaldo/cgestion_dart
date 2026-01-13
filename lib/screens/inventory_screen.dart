/// Pantalla de inventario de productos.
/// 
/// Muestra la lista de productos almacenados en la alacena de la familia
/// con funcionalidades de búsqueda, visualización detallada y actualización
/// de cantidades. Incluye alertas visuales para productos caducados o
/// próximos a vencer.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/inventory_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';
import 'package:gestor_alacena/widgets/theme_switch.dart';

/// Widget de la pantalla de inventario.
/// 
/// Primera pestaña de la navegación principal que permite a los usuarios
/// ver y gestionar los productos en su alacena.
class InventoryScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

/// Estado de la pantalla de inventario.
/// 
/// Gestiona la búsqueda de productos, la carga de datos y la interacción
/// con los diálogos de detalle y edición.
class _InventoryScreenState extends State<InventoryScreen> {
  /// Controlador para el campo de búsqueda de productos.
  final _searchController = TextEditingController();
  
  /// Query de búsqueda actual.
  /// Se actualiza cuando el usuario escribe en el campo de búsqueda.
  String _searchQuery = '';

  /// Inicializa el estado y carga los datos del inventario.
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Libera los recursos del controlador al destruir el widget.
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Carga los productos del inventario desde Supabase.
  /// 
  /// Este método se llama:
  /// - Al inicializar la pantalla ([initState])
  /// - Al hacer pull-to-refresh en la lista
  /// 
  /// Obtiene el familyId del AuthService y lo usa para cargar
  /// solo los productos de la familia actual.
  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final inventoryService = context.read<InventoryService>();
    
    if (authService.familyId != null) {
      await inventoryService.loadInventory(authService.familyId!);
    }
  }

  /// Muestra un diálogo modal con los detalles completos del producto.
  /// 
  /// El diálogo incluye:
  /// - Imagen del producto a tamaño grande (o ícono si no hay imagen)
  /// - Nombre del producto
  /// - Cantidad disponible con su unidad
  /// - Botón de cerrar
  /// 
  /// Se activa con un long press en cualquier producto de la lista.
  /// 
  /// [item] Producto del cual mostrar los detalles.
  void _showProductDetail(InventoryItem item) {
    final isDark = context.read<ThemeService>().isDarkMode;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sección de imagen del producto
              if (item.imageUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: Stack(
                    children: [
                      // Imagen cargada con caché
                      CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: 300,
                        // Placeholder mientras carga la imagen
                        placeholder: (context, url) => Container(
                          height: 300,
                          color: isDark ? const Color(0xFF212121) : const Color(0xFFF5F5F5),
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF34A853),
                            ),
                          ),
                        ),
                        // Widget de error si falla la carga
                        errorWidget: (context, url, error) => Container(
                          height: 300,
                          color: isDark ? const Color(0xFF212121) : const Color(0xFFF5F5F5),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image_rounded,
                                size: 64,
                                color: isDark ? const Color(0xFF616161) : const Color(0xFFBDBDBD),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Error al cargar imagen',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Botón de cerrar sobre la imagen
                      Positioned(
                        top: 12,
                        right: 12,
                        child: IconButton(
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0x89000000),
                            foregroundColor: const Color(0xFFFFFFFF),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                    ],
                  ),
                )
              else
                // Placeholder cuando no hay imagen disponible
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF34A853).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.inventory_2_rounded,
                        size: 100,
                        color: const Color(0xFF34A853).withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin imagen',
                        style: TextStyle(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              
              // Sección de información del producto
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Nombre del producto
                    Text(
                      item.displayName,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // Badge con la cantidad disponible
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF34A853),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Botón de cerrar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF34A853),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Cerrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra un diálogo para ajustar la cantidad del producto.
  /// 
  /// Permite al usuario:
  /// - Incrementar cantidad (botón +)
  /// - Decrementar cantidad (botón -)
  /// - Eliminar completamente el producto (botón "Ya no hay producto")
  /// - Guardar cambios o cancelar
  /// 
  /// El diálogo usa [StatefulBuilder] para actualizar la cantidad
  /// localmente mientras el usuario ajusta los valores, sin afectar
  /// el inventario hasta que presione "Guardar".
  /// 
  /// [item] Producto cuya cantidad se va a ajustar.
  void _showDecrementDialog(InventoryItem item) {
    // Copia local de la cantidad para modificarla sin afectar el original
    double currentQuantity = item.quantity;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(item.displayName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ajusta la cantidad disponible',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 24),
              // Controles de incremento/decremento
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Botón decrementar (-)
                  IconButton(
                    onPressed: currentQuantity > 0
                        ? () {
                            setState(() {
                              if (currentQuantity >= 1) {
                                currentQuantity -= 1;
                              } else {
                                currentQuantity = 0;
                              }
                            });
                          }
                        : null, // Deshabilitado cuando cantidad es 0
                    icon: const Icon(Icons.remove_circle),
                    iconSize: 40,
                    color: Colors.red,
                  ),
                  const SizedBox(width: 16),
                  // Display de cantidad actual
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF34A853).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF34A853)),
                    ),
                    child: Text(
                      '${currentQuantity.toStringAsFixed(0)} ${item.unit}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF34A853),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Botón incrementar (+)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        currentQuantity += 1;
                      });
                    },
                    icon: const Icon(Icons.add_circle),
                    iconSize: 40,
                    color: const Color(0xFF34A853),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            // Botón para eliminar producto completamente
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  final authService = context.read<AuthService>();
                  final success = await context
                      .read<InventoryService>()
                      .decrementQuantity(item.id, 0, authService.familyId!);
                  
                  if (!mounted) return;
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Producto eliminado del inventario')),
                    );
                  }
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('Ya no hay producto'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFF44336),
                  side: const BorderSide(color: Color(0xFFF44336)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Botones de cancelar y guardar
            Row(
              children: [
                // Botón cancelar
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 8),
                // Botón guardar (solo habilitado si la cantidad cambió)
                Expanded(
                  child: ElevatedButton(
                    onPressed: currentQuantity != item.quantity
                        ? () async {
                            Navigator.pop(context);
                            
                            final authService = context.read<AuthService>();
                            final success = await context
                                .read<InventoryService>()
                                .decrementQuantity(
                                    item.id, currentQuantity, authService.familyId!);
                            
                            if (!mounted) return;
                            
                            if (success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Cantidad actualizada')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Error al actualizar')),
                              );
                            }
                          }
                        : null, // Deshabilitado si no hay cambios
                    child: const Text('Guardar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Construye el widget de imagen del producto para la lista.
  /// 
  /// Maneja tres casos:
  /// 1. Imagen válida: muestra la imagen con CachedNetworkImage
  /// 2. Error al cargar: muestra ícono de inventario
  /// 3. Sin imagen: muestra ícono de inventario
  /// 
  /// [imageUrl] URL de la imagen del producto (puede ser null).
  /// [isDark] Indica si el tema actual es oscuro.
  /// 
  /// Retorna un widget de 50x50 px con bordes redondeados.
  Widget _buildProductImage(String? imageUrl, bool isDark) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          // Placeholder mientras carga
          placeholder: (context, url) => Container(
            width: 50,
            height: 50,
            color: isDark ? Colors.grey[800] : Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          // Ícono de error si falla la carga
          errorWidget: (context, url, error) => Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF34A853).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2, color: Color(0xFF34A853)),
          ),
        ),
      );
    }
    
    // Caso por defecto: sin imagen
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: const Color(0xFF34A853).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.inventory_2, color: Color(0xFF34A853)),
    );
  }

  /// Construye la interfaz principal de la pantalla de inventario.
  /// 
  /// Estructura:
  /// 1. AppBar con título y switch de tema
  /// 2. Campo de búsqueda con funcionalidad de filtrado
  /// 3. Lista de productos con:
  ///    - Imagen miniatura
  ///    - Nombre y fechas (compra/caducidad)
  ///    - Alertas visuales para productos caducados
  ///    - Cantidad y botón de edición
  /// 4. Estado vacío cuando no hay productos
  /// 5. Pull-to-refresh para recargar datos
  /// 
  /// Alertas de caducidad:
  /// - Producto caducado: fondo rojo, ícono de advertencia
  /// - Caduca pronto (< 7 días): texto naranja
  /// - Normal: texto gris
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inventario',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          ThemeSwitch(),
        ],
      ),
      body: Column(
        children: [
          // Campo de búsqueda
          Container(
            color: Theme.of(context).appBarTheme.backgroundColor,
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar productos...',
                prefixIcon: Icon(Icons.search_rounded, 
                  color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575)),
                // Botón para limpiar búsqueda (solo visible cuando hay texto)
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          // Lista de productos
          Expanded(
            child: Consumer<InventoryService>(
              builder: (context, service, child) {
                // Estado de carga
                if (service.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF34A853),
                    ),
                  );
                }
                
                // Filtrar productos según búsqueda
                final items = service.searchItems(_searchQuery);
                
                // Estado vacío
                if (items.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 80,
                          color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay productos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Agrega productos desde la lista de compras',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                
                // Lista de productos con pull-to-refresh
                return RefreshIndicator(
                  onRefresh: _loadData,
                  color: const Color(0xFF34A853),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final dateFormat = DateFormat('dd/MM/yyyy');
                      
                      // Verificar estado de caducidad
                      final isExpired = item.expiryDate != null && 
                          item.expiryDate!.isBefore(DateTime.now());
                      final isExpiringSoon = item.expiryDate != null && 
                          !isExpired &&
                          item.expiryDate!.isBefore(
                            DateTime.now().add(const Duration(days: 7)),
                          );
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          // Fondo rojo para productos caducados
                          color: isExpired 
                              ? (isDark ? const Color(0xFF4A1616) : const Color(0xFFFEE9E7))
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isExpired
                                ? const Color(0xFFE57373)
                                : (isDark ? Colors.grey.shade800 : const Color(0xFFEEEEEE)),
                          ),
                        ),
                        child: InkWell(
                          // Long press para mostrar detalles
                          onLongPress: () => _showProductDetail(item),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Imagen del producto
                                _buildProductImage(item.imageUrl, isDark),
                                const SizedBox(width: 12),
                                // Información del producto
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nombre
                                      Text(
                                        item.displayName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                          color: isDark ? Colors.white : const Color(0xFF202124),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Fecha de compra
                                      Text(
                                        'Compra: ${dateFormat.format(item.purchaseDate)}',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      // Fecha de caducidad (si existe)
                                      if (item.expiryDate != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            // Ícono de advertencia para caducados
                                            if (isExpired)
                                              const Icon(
                                                Icons.warning_rounded,
                                                size: 14,
                                                color: Color(0xFFE57373),
                                              ),
                                            if (isExpired)
                                              const SizedBox(width: 4),
                                            // Texto de caducidad con color según estado
                                            Text(
                                              isExpired 
                                                  ? 'Caducado ${dateFormat.format(item.expiryDate!)}'
                                                  : 'Caduca ${dateFormat.format(item.expiryDate!)}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isExpired 
                                                    ? const Color(0xFFE57373) // Rojo
                                                    : isExpiringSoon
                                                        ? const Color(0xFFFFA726) // Naranja
                                                        : (isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575)),
                                                fontWeight: isExpired 
                                                    ? FontWeight.w600 
                                                    : FontWeight.w400,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                // Cantidad y botón de edición
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    // Cantidad disponible
                                    Text(
                                      '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF34A853),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Botón de editar
                                    IconButton(
                                      icon: const Icon(Icons.edit_rounded),
                                      iconSize: 20,
                                      color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF5F6368),
                                      onPressed: () => _showDecrementDialog(item),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
