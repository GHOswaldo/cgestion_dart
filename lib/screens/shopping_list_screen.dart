/// Pantalla de lista de compras.
/// 
/// Permite a los usuarios gestionar los productos que necesitan comprar,
/// marcarlos como verificados y registrarlos en el inventario una vez
/// que han sido comprados. Incluye escaneo de códigos de barras y
/// gestión completa de información del producto.
// ignore_for_file: deprecated_member_use

library;

import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';

import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/shopping_list_service.dart';
import 'package:gestor_alacena/services/inventory_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';
import 'package:gestor_alacena/widgets/theme_switch.dart';

/// Widget principal de la pantalla de lista de compras.
/// 
/// Segunda pestaña de la navegación principal que permite gestionar
/// productos pendientes de compra y registrarlos en el inventario.
class ShoppingListScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

/// Estado de la pantalla de lista de compras.
/// 
/// Gestiona la lista de productos pendientes, la adición de nuevos
/// productos y el proceso de registro en el inventario.
class _ShoppingListScreenState extends State<ShoppingListScreen> {
  /// Indica si se está procesando la adición de un producto.
  /// Previene múltiples envíos simultáneos del mismo producto.
  bool _isAddingItem = false;

  /// Inicializa el estado y carga los datos necesarios.
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga la lista de compras y las categorías de productos.
  /// 
  /// Este método se llama:
  /// - Al inicializar la pantalla ([initState])
  /// - Al hacer pull-to-refresh en la lista
  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final shoppingService = context.read<ShoppingListService>();
    
    if (authService.familyId != null) {
      await shoppingService.loadShoppingList(authService.familyId!);
      await shoppingService.loadCategories();
    }
  }

  /// Muestra un diálogo para agregar un nuevo producto a la lista.
  /// 
  /// El diálogo incluye:
  /// - Campo de texto para el nombre del producto
  /// - Botón de cancelar
  /// - Botón de agregar (con indicador de carga)
  /// 
  /// El campo de texto tiene autofocus y capitalización automática
  /// de la primera letra de cada palabra para mejorar la UX.
  void _showAddItemDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Agregar producto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Nombre del producto',
                  hintText: 'Ej: Leche, Pan, Manzanas...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.shopping_bag_outlined),
                ),
                autofocus: true,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    // Deshabilita el botón mientras se procesa
                    onPressed: _isAddingItem ? null : () async {
                      if (controller.text.isEmpty) return;
                      
                      setState(() => _isAddingItem = true);
                      
                      final authService = context.read<AuthService>();
                      final success = await context
                          .read<ShoppingListService>()
                          .addItem(
                            authService.familyId!,
                            controller.text,
                            authService.currentUser!.id,
                          );
                      
                      if (!mounted) return;
                      
                      setState(() => _isAddingItem = false);
                      Navigator.pop(context);
                      
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Producto agregado'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF34A853),
                      foregroundColor: const Color(0xFFFFFFFF),
                    ),
                    child: _isAddingItem 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFFFFFFF),
                            ),
                          )
                        : const Text('Agregar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Muestra el diálogo de registro de producto en el inventario.
  /// 
  /// Este diálogo complejo permite:
  /// - Escanear código de barras
  /// - Buscar producto en el catálogo
  /// - Ingresar información manualmente
  /// - Subir imagen del producto
  /// - Registrar el producto en el inventario
  /// 
  /// [item] Producto de la lista de compras a registrar.
  void _showRegisterProductDialog(ShoppingListItem item) {
    showDialog(
      context: context,
      builder: (context) => RegisterProductDialog(item: item),
    );
  }

  /// Construye la interfaz principal de la pantalla de lista de compras.
  /// 
  /// La pantalla incluye:
  /// 1. AppBar con título y switch de tema
  /// 2. Lista de productos con checkboxes
  /// 3. Botones de acción (registrar, eliminar)
  /// 4. Estado vacío cuando no hay productos
  /// 5. FAB para agregar nuevos productos
  /// 6. Pull-to-refresh para recargar datos
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lista de compras',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          ThemeSwitch(),
        ],
      ),
      body: Consumer<ShoppingListService>(
        builder: (context, service, child) {
          // Estado de carga
          if (service.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF34A853),
              ),
            );
          }
          
          // Estado vacío
          if (service.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lista vacía',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega productos que necesites comprar',
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
              itemCount: service.items.length,
              itemBuilder: (context, index) {
                final item = service.items[index];
                final dateFormat = DateFormat('dd MMM');
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Checkbox para marcar producto como verificado
                        Checkbox(
                          value: item.isChecked,
                          onChanged: (value) {
                            service.toggleCheck(item.id, value ?? false);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          activeColor: const Color(0xFF34A853),
                        ),
                        // Información del producto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: isDark ? Colors.white : const Color(0xFF202124),
                                  // Tachar texto si está marcado
                                  decoration: item.isChecked
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dateFormat.format(item.createdAt),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Botón para registrar en inventario
                        IconButton(
                          icon: const Icon(Icons.add_shopping_cart_rounded),
                          iconSize: 22,
                          color: const Color(0xFF34A853),
                          onPressed: () => _showRegisterProductDialog(item),
                        ),
                        // Botón para eliminar producto
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded),
                          iconSize: 22,
                          color: const Color(0xFFF44336),
                          onPressed: () async {
                            // Confirmar eliminación
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Eliminar producto',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                content: Text(
                                  '¿Eliminar "${item.productName}" de la lista?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancelar'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFF44336),
                                      foregroundColor: const Color(0xFFFFFFFF),
                                    ),
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Eliminar'),
                                  ),
                                ],
                              ),
                            );
                            
                            if (confirm == true) {
                              await service.deleteItem(item.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      // FAB para agregar nuevos productos
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        backgroundColor: const Color(0xFF34A853),
        foregroundColor: const Color(0xFFFFFFFF),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
/// Diálogo para registrar un producto comprado en el inventario.
/// 
/// Este diálogo complejo maneja todo el proceso de registro de un producto,
/// incluyendo escaneo de código de barras, búsqueda en catálogo, entrada
/// manual de datos y subida de imágenes.

/// Widget del diálogo de registro de producto.
/// 
/// Permite al usuario registrar un producto de la lista de compras
/// como un producto comprado que se agregará al inventario.
class RegisterProductDialog extends StatefulWidget {
  /// Producto de la lista de compras que se va a registrar.
  final ShoppingListItem item;

  /// Constructor que requiere el producto a registrar.
  const RegisterProductDialog({super.key, required this.item});

  @override
  State<RegisterProductDialog> createState() => _RegisterProductDialogState();
}

/// Estado del diálogo de registro de producto.
/// 
/// Gestiona múltiples estados y formularios complejos incluyendo:
/// - Escaneo de códigos de barras
/// - Búsqueda en catálogo de productos
/// - Entrada manual de información
/// - Selección de imágenes
/// - Validaciones y envío de datos
class _RegisterProductDialogState extends State<RegisterProductDialog> {
  // Controladores de campos de texto
  /// Controlador para el campo de código de barras.
  final _barcodeController = TextEditingController();
  
  /// Controlador para el campo de nombre del producto.
  final _productNameController = TextEditingController();
  
  /// Controlador para el campo de cantidad (inicializado con '1').
  final _quantityController = TextEditingController(text: '1');
  
  /// Controlador para el campo de costo (inicializado con '0').
  final _costController = TextEditingController(text: '0');
  
  // Estado del formulario
  /// Unidad de medida seleccionada (por defecto 'pz' - piezas).
  String _unit = 'pz';
  
  /// Fecha de caducidad del producto (por defecto 7 días desde hoy).
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 7));
  
  /// Indica si el producto tiene fecha de caducidad.
  /// Si es false, se usa una fecha lejana (2099) como "sin caducidad".
  bool _hasExpiryDate = true;
  
  /// ID de la categoría seleccionada (requerido para el registro).
  int? _selectedCategoryId;
  
  /// Indica si se está usando el escáner de código de barras.
  bool _useScanner = false;
  
  /// Archivo de imagen seleccionado desde la galería.
  File? _selectedImage;
  
  /// URL de la imagen del producto (desde el catálogo o subida).
  String? _imageUrl;
  
  /// Producto encontrado en el catálogo (si existe).
  CatalogProduct? _catalogProduct;
  
  /// Indica si se está buscando el producto en el catálogo.
  bool _isLoadingProduct = false;

  /// Inicializa el controlador de nombre con el nombre del producto
  /// de la lista de compras.
  @override
  void initState() {
    super.initState();
    _productNameController.text = widget.item.productName;
  }

  /// Libera los recursos de los controladores.
  @override
  void dispose() {
    _barcodeController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    super.dispose();
  }

  /// Busca un producto en el catálogo por código de barras.
  /// 
  /// Si encuentra el producto:
  /// - Llena automáticamente el nombre
  /// - Selecciona la categoría correspondiente
  /// - Carga la imagen del catálogo
  /// - Muestra mensaje de confirmación
  /// 
  /// [barcode] Código de barras a buscar en el catálogo.
  Future<void> _checkBarcode(String barcode) async {
    setState(() => _isLoadingProduct = true);
    
    final service = context.read<ShoppingListService>();
    _catalogProduct = await service.getProductByBarcode(barcode);
    
    if (_catalogProduct != null) {
      setState(() {
        _productNameController.text = _catalogProduct!.name;
        _selectedCategoryId = _catalogProduct!.categoryId;
        _imageUrl = _catalogProduct!.imageUrl;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto encontrado en el catálogo'),
            backgroundColor: Color(0xFF34A853),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    
    setState(() => _isLoadingProduct = false);
  }

  /// Maneja la detección de un código de barras por el escáner.
  /// 
  /// Cuando se detecta un código:
  /// - Actualiza el campo de texto con el código
  /// - Cierra el escáner
  /// - Busca el producto en el catálogo automáticamente
  /// 
  /// [capture] Objeto que contiene los códigos de barras detectados.
  void _handleBarcodeDetected(BarcodeCapture capture) {
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        _barcodeController.text = barcode;
        _useScanner = false;
      });
      _checkBarcode(barcode);
    }
  }

  /// Abre el selector de imágenes para que el usuario elija una foto.
  /// 
  /// La imagen seleccionada se almacena localmente hasta que
  /// se registre el producto, momento en el cual se sube a Supabase Storage.
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  /// Registra el producto en el inventario.
  /// 
  /// Proceso completo:
  /// 1. Valida que haya una categoría seleccionada
  /// 2. Si hay imagen seleccionada y código de barras: sube la imagen
  /// 3. Registra el producto (actualiza/crea en catálogo y agrega a inventario)
  /// 4. Recarga el inventario
  /// 5. Cierra el diálogo y muestra confirmación
  /// 
  /// La fecha de caducidad se maneja de forma especial:
  /// - Si _hasExpiryDate es true: usa _expiryDate
  /// - Si es false: usa fecha lejana (2099-12-31) como "sin caducidad"
  Future<void> _registerProduct() async {
    // Validación: categoría es obligatoria
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una categoría'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final authService = context.read<AuthService>();
    final shoppingService = context.read<ShoppingListService>();
    final inventoryService = context.read<InventoryService>();

    String? finalImageUrl = _imageUrl;

    // Subir imagen si hay una seleccionada y existe código de barras
    if (_selectedImage != null && _barcodeController.text.isNotEmpty) {
      final bytes = await _selectedImage!.readAsBytes();
      finalImageUrl = await shoppingService.uploadProductImage(
        _barcodeController.text,
        Uint8List.fromList(bytes),
      );
    }

    // Registrar producto en el inventario
    final success = await shoppingService.registerProduct(
      familyId: authService.familyId!,
      itemId: widget.item.id,
      productName: _productNameController.text,
      barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
      quantity: double.parse(_quantityController.text),
      unit: _unit,
      // Si no tiene caducidad, usar fecha lejana
      expiryDate: _hasExpiryDate ? _expiryDate : DateTime(2099, 12, 31),
      categoryId: _selectedCategoryId!,
      costPerUnit: double.parse(_costController.text),
      imageUrl: finalImageUrl,
    );

    if (!mounted) return;

    if (success) {
      // Recargar inventario para mostrar el nuevo producto
      await inventoryService.loadInventory(authService.familyId!);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Producto registrado en inventario'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al registrar producto'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Construye la interfaz del diálogo de registro.
  /// 
  /// El diálogo incluye múltiples secciones:
  /// 1. Header con título y producto a registrar
  /// 2. Escaneo de código de barras (puede alternar entre campo y escáner)
  /// 3. Campo de nombre (bloqueado si se encontró en catálogo)
  /// 4. Selector/preview de imagen
  /// 5. Campos de cantidad, unidad y costo
  /// 6. Selector de categoría (bloqueado si se encontró en catálogo)
  /// 7. Selector de fecha de caducidad con switch on/off
  /// 8. Botones de cancelar y registrar
  /// 
  /// La UI se adapta según el contexto:
  /// - Muestra escáner o campo de código según _useScanner
  /// - Muestra indicador de carga al buscar en catálogo
  /// - Bloquea campos cuando hay producto del catálogo
  /// - Muestra imagen del catálogo o selector de imagen local
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header del diálogo
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF34A853).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.add_shopping_cart_rounded,
                        color: Color(0xFF34A853),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Registrar: ${widget.item.productName}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF202124),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Sección de código de barras: escáner o campo de texto
                if (_useScanner)
                  // Mostrar escáner de código de barras
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: MobileScanner(
                      onDetect: _handleBarcodeDetected,
                    ),
                  )
                else ...[
                  // Mostrar campo de texto para código de barras
                  TextField(
                    controller: _barcodeController,
                    decoration: InputDecoration(
                      labelText: 'Código de barras (opcional)',
                      hintText: 'Escanea o ingresa manualmente',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.qr_code_2_rounded),
                    ),
                    onChanged: (value) {
                      // Buscar automáticamente cuando tiene 8+ caracteres
                      if (value.length >= 8) {
                        _checkBarcode(value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  // Botón para abrir escáner
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _useScanner = true),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('Escanear código'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF34A853),
                    ),
                  ),
                ],
                
                // Indicador de carga mientras busca en catálogo
                if (_isLoadingProduct)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF34A853),
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),
                // Campo de nombre del producto
                TextField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Nombre del producto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.label_outline_rounded),
                  ),
                  // Bloquear edición si se encontró en el catálogo
                  readOnly: _catalogProduct != null,
                ),
                
                const SizedBox(height: 16),
                
                // Selector de imagen (solo si no hay imagen del catálogo)
                if (_catalogProduct == null || _catalogProduct!.imageUrl == null) ...[
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_rounded),
                    label: const Text('Agregar imagen'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF34A853),
                    ),
                  ),
                  // Preview de imagen seleccionada
                  if (_selectedImage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImage!,
                              height: 120,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Botón para eliminar imagen seleccionada
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0x89000000),
                                foregroundColor: const Color(0xFFFFFFFF),
                              ),
                              onPressed: () {
                                setState(() => _selectedImage = null);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                
                // Preview de imagen del catálogo
                if (_imageUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _imageUrl!,
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                
                // Campos de cantidad y unidad
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Cantidad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.production_quantity_limits_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _unit,
                        decoration: InputDecoration(
                          labelText: 'Unidad',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: ['pz', 'kg', 'lt']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (value) => setState(() => _unit = value!),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                // Campo de costo por unidad
                TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Costo por unidad',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.attach_money_rounded),
                  ),
                ),
                
                const SizedBox(height: 16),
                // Selector de categoría
                Consumer<ShoppingListService>(
                  builder: (context, service, child) {
                    return DropdownButtonFormField<int>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: const Icon(Icons.category_rounded),
                      ),
                      items: service.categories
                          .map((cat) => DropdownMenuItem(
                                value: cat.id,
                                child: Text(cat.name),
                              ))
                          .toList(),
                      // Bloquear si hay producto del catálogo
                      onChanged: _catalogProduct == null
                          ? (value) => setState(() => _selectedCategoryId = value)
                          : null,
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Sección de fecha de caducidad
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Fecha de caducidad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.grey[400] : Colors.grey[700],
                            ),
                          ),
                        ),
                        // Switch para activar/desactivar fecha de caducidad
                        Transform.scale(
                          scale: 0.85,
                          child: Switch(
                            value: _hasExpiryDate,
                            onChanged: (value) {
                              setState(() => _hasExpiryDate = value);
                            },
                            activeColor: const Color(0xFF34A853),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Selector de fecha (solo si está activado)
                    if (_hasExpiryDate)
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _expiryDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (date != null) {
                            setState(() => _expiryDate = date);
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF5F6368),
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Selecciona la fecha',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      DateFormat('dd/MM/yyyy').format(_expiryDate),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                color: isDark ? const Color(0xFF757575) : const Color(0xFF5F6368),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      // Indicador de "sin caducidad"
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF212121) : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF424242) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.all_inclusive_rounded,
                              color: isDark ? const Color(0xFF9E9E9E) : const Color(0xFF757575),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Sin fecha de caducidad',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFBDBDBD) : const Color(0xFF616161),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 24),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _registerProduct,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Registrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34A853),
                        foregroundColor: const Color(0xFFFFFFFF),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
