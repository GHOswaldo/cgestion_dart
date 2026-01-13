/// Servicio de gestión de estadísticas y análisis.
/// 
/// Proporciona funcionalidad para calcular y obtener estadísticas sobre
/// el inventario y consumo de la familia, incluyendo distribución por
/// categorías, valor total del inventario y consumo mensual.
library;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Modelo que representa datos de una categoría para gráficos.
/// 
/// Usado principalmente en el gráfico de pastel (pie chart) para
/// mostrar la distribución de productos por categoría.
class CategoryData {
  /// Nombre de la categoría (ej: "Lácteos", "Carnes").
  final String name;
  
  /// Valor numérico de la categoría (cantidad total de productos).
  final double value;
  
  /// Código hexadecimal del color asignado a la categoría.
  /// Usado para mantener consistencia visual en los gráficos.
  final String colorHex;

  /// Constructor del modelo CategoryData.
  CategoryData({
    required this.name,
    required this.value,
    required this.colorHex,
  });
}

/// Modelo que representa el consumo de un mes específico.
/// 
/// Usado en el gráfico de barras para mostrar el gasto mensual
/// de la familia en productos de la alacena.
class MonthlyConsumption {
  /// Nombre abreviado del mes (ej: "Ene", "Feb", "Mar").
  final String month;
  
  /// Monto total consumido en el mes (en la moneda local).
  final double amount;
  
  /// Año del consumo (para distinguir meses de diferentes años).
  final int year;
  
  /// Número del mes (1-12) para ordenamiento y comparaciones.
  final int monthNumber;

  /// Constructor del modelo MonthlyConsumption.
  MonthlyConsumption({
    required this.month, 
    required this.amount,
    required this.year,
    required this.monthNumber,
  });
}

/// Servicio que gestiona estadísticas del inventario y consumo.
/// 
/// Este servicio extiende [ChangeNotifier] para notificar a los widgets
/// cuando cambian las estadísticas calculadas.
/// 
/// Funcionalidades principales:
/// - Calcular distribución de productos por categoría
/// - Calcular valor total del inventario actual
/// - Obtener consumo mensual histórico
/// - Separar consumo reciente vs. histórico (últimos 4 meses vs. anteriores)
class StatisticsService extends ChangeNotifier {
  /// Cliente de Supabase para operaciones de backend.
  final _supabase = Supabase.instance.client;
  
  /// Lista de categorías con sus cantidades para el gráfico de pastel.
  List<CategoryData> _categoryDistribution = [];
  
  /// Valor total del inventario actual (suma de cantidad × costo de todos los productos).
  double _totalInventoryValue = 0;
  
  /// Consumo de los últimos 4 meses (para el gráfico de barras principal).
  List<MonthlyConsumption> _monthlyConsumption = [];
  
  /// Consumo de meses anteriores a los últimos 4 (para el historial).
  List<MonthlyConsumption> _olderMonths = [];
  
  /// Indica si se están cargando las estadísticas.
  bool _isLoading = false;
  
  // Getters públicos
  List<CategoryData> get categoryDistribution => _categoryDistribution;
  double get totalInventoryValue => _totalInventoryValue;
  List<MonthlyConsumption> get monthlyConsumption => _monthlyConsumption;
  List<MonthlyConsumption> get olderMonths => _olderMonths;
  bool get isLoading => _isLoading;

  /// Carga todas las estadísticas de una familia.
  /// 
  /// Este método orquesta la carga paralela de tres tipos de estadísticas:
  /// 1. Distribución por categorías (para gráfico de pastel)
  /// 2. Valor total del inventario (para card destacado)
  /// 3. Consumo mensual (para gráfico de barras)
  /// 
  /// Usa [Future.wait] para cargar todas las estadísticas en paralelo
  /// y mejorar el rendimiento.
  /// 
  /// [familyId] ID de la familia cuyas estadísticas se van a cargar.
  /// 
  /// Ejemplo de uso:
  /// ```dart
  /// await statisticsService.loadStatistics(authService.familyId!);
  /// ```
  Future<void> loadStatistics(String familyId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // Cargar las tres estadísticas en paralelo
      await Future.wait([
        _loadCategoryDistribution(familyId),
        _loadTotalInventoryValue(familyId),
        _loadMonthlyConsumption(familyId),
      ]);
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
    
    _isLoading = false;
    notifyListeners();
  }

  /// Carga la distribución de productos por categoría.
  /// 
  /// Proceso:
  /// 1. Obtiene todos los productos del inventario con sus categorías
  /// 2. Agrupa productos por categoría
  /// 3. Suma las cantidades de cada categoría
  /// 4. Ordena por cantidad (mayor a menor)
  /// 
  /// La query usa joins para obtener información de categorías:
  /// - inventory_items → product_catalog → product_categories
  /// 
  /// Solo se consideran productos que tienen código de barras y
  /// están en el catálogo (producto del join inner).
  /// 
  /// [familyId] ID de la familia a analizar.
  Future<void> _loadCategoryDistribution(String familyId) async {
    try {
      // Query con joins para obtener categorías
      final response = await _supabase
          .from('inventory_items')
          .select('''
            id,
            quantity,
            barcode,
            product_catalog!inner (
              category_id,
              product_categories!inner (
                id,
                name,
                color_hex,
                icon_name
              )
            )
          ''')
          .eq('family_id', familyId);
      
      // Map para acumular cantidades por categoría
      final Map<int, CategoryData> categoryMap = {};
      
      for (var item in response) {
        final categoryData = item['product_catalog']?['product_categories'];
        final quantity = (item['quantity'] ?? 1).toDouble();
        
        if (categoryData != null) {
          final categoryId = categoryData['id'] as int;
          final categoryName = categoryData['name'] ?? 'Sin categoría';
          final colorHex = categoryData['color_hex'] ?? '#607D8B';
          
          if (categoryMap.containsKey(categoryId)) {
            // Categoría ya existe: sumar cantidad
            categoryMap[categoryId] = CategoryData(
              name: categoryName,
              value: categoryMap[categoryId]!.value + quantity,
              colorHex: colorHex,
            );
          } else {
            // Primera vez que aparece esta categoría
            categoryMap[categoryId] = CategoryData(
              name: categoryName,
              value: quantity,
              colorHex: colorHex,
            );
          }
        }
      }
      
      _categoryDistribution = categoryMap.values.toList();
      
      // Ordenar por cantidad descendente (más productos primero)
      _categoryDistribution.sort((a, b) => b.value.compareTo(a.value));
    } catch (e) {
      debugPrint('Error en distribución de categorías: $e');
      _categoryDistribution = [];
    }
  }

  /// Calcula el valor total del inventario actual.
  /// 
  /// El valor se calcula multiplicando la cantidad de cada producto
  /// por su costo unitario y sumando todos los productos:
  /// 
  /// Valor Total = Σ (cantidad × costo_unitario)
  /// 
  /// Este valor representa cuánto dinero hay "invertido" en el
  /// inventario actual de la familia.
  /// 
  /// [familyId] ID de la familia a analizar.
  Future<void> _loadTotalInventoryValue(String familyId) async {
    try {
      final response = await _supabase
          .from('inventory_items')
          .select('quantity, cost_per_unit')
          .eq('family_id', familyId);
      
      double total = 0;
      for (var item in response) {
        final quantity = (item['quantity'] ?? 0).toDouble();
        final cost = (item['cost_per_unit'] ?? 0).toDouble();
        total += quantity * cost;
      }
      
      _totalInventoryValue = total;
    } catch (e) {
      debugPrint('Error calculando valor total: $e');
      _totalInventoryValue = 0;
    }
  }

  /// Carga el historial de consumo mensual.
  /// 
  /// Este método procesa el log de consumo (consumption_log) y lo
  /// agrupa por mes, separando en dos listas:
  /// 
  /// 1. **_monthlyConsumption**: Últimos 4 meses (para gráfico principal)
  ///    - Incluye el mes actual y los 3 anteriores
  ///    - Si un mes no tiene datos, se crea con amount = 0
  ///    - Se ordena cronológicamente (más antiguo a más reciente)
  /// 
  /// 2. **_olderMonths**: Meses anteriores (para historial)
  ///    - Todos los meses antes de los últimos 4
  ///    - Se ordena cronológicamente descendente (más reciente primero)
  /// 
  /// El consumo se obtiene de la tabla consumption_log, que se alimenta
  /// cuando se eliminan productos del inventario (consumo completo).
  /// 
  /// [familyId] ID de la familia a analizar.
  /// 
  /// Ejemplo de estructura resultante:
  /// ```
  /// monthlyConsumption: [Sep: $150, Oct: $200, Nov: $180, Dic: $220]
  /// olderMonths: [Ago: $170, Jul: $160, Jun: $140, ...]
  /// ```
  Future<void> _loadMonthlyConsumption(String familyId) async {
    try {
      final now = DateTime.now();
      
      // Obtener todos los consumos ordenados por fecha
      final response = await _supabase
          .from('consumption_log')
          .select('cost, consumed_at')
          .eq('family_id', familyId)
          .order('consumed_at', ascending: false);
      
      // Map para agrupar por mes (key: "YYYY-MM")
      final Map<String, MonthlyConsumption> monthlyMap = {};
      
      // Agrupar consumos por mes
      for (var item in response) {
        final date = DateTime.parse(item['consumed_at']);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        final cost = (item['cost'] ?? 0).toDouble();
        
        if (monthlyMap.containsKey(monthKey)) {
          // Mes ya existe: sumar costo
          monthlyMap[monthKey] = MonthlyConsumption(
            month: monthlyMap[monthKey]!.month,
            amount: monthlyMap[monthKey]!.amount + cost,
            year: date.year,
            monthNumber: date.month,
          );
        } else {
          // Primer consumo de este mes
          final monthNames = [
            '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
            'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
          ];
          monthlyMap[monthKey] = MonthlyConsumption(
            month: monthNames[date.month],
            amount: cost,
            year: date.year,
            monthNumber: date.month,
          );
        }
      }
      
      // Construir lista de últimos 4 meses
      _monthlyConsumption = [];
      for (int i = 3; i >= 0; i--) {
        final date = DateTime(now.year, now.month - i, 1);
        final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        
        if (monthlyMap.containsKey(monthKey)) {
          // Mes tiene datos: usar el consumo real
          _monthlyConsumption.add(monthlyMap[monthKey]!);
        } else {
          // Mes sin datos: crear con consumo 0
          final monthNames = [
            '', 'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
            'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
          ];
          _monthlyConsumption.add(MonthlyConsumption(
            month: monthNames[date.month],
            amount: 0,
            year: date.year,
            monthNumber: date.month,
          ));
        }
      }
      
      // Filtrar meses anteriores a los últimos 4
      _olderMonths = monthlyMap.values
          .where((month) {
            final currentDate = DateTime(now.year, now.month);
            final monthDate = DateTime(month.year, month.monthNumber);
            // Incluir solo meses antes de hace 3 meses
            return monthDate.isBefore(DateTime(currentDate.year, currentDate.month - 3));
          })
          .toList()
        // Ordenar cronológicamente descendente (más reciente primero)
        ..sort((a, b) {
          final dateA = DateTime(a.year, a.monthNumber);
          final dateB = DateTime(b.year, b.monthNumber);
          return dateB.compareTo(dateA);
        });
    } catch (e) {
      debugPrint('Error en consumo mensual: $e');
      _monthlyConsumption = [];
      _olderMonths = [];
    }
  }
}
