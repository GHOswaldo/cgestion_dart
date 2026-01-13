/// Pantalla de estadísticas y análisis.
/// 
/// Muestra visualizaciones gráficas del inventario y consumo de la familia,
/// incluyendo gráficos de pastel (distribución por categorías), gráficos
/// de barras (consumo mensual) y métricas clave como el valor total del inventario.
// ignore_for_file: deprecated_member_use

library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'package:gestor_alacena/services/auth_service.dart';
import 'package:gestor_alacena/services/statistics_service.dart';
import 'package:gestor_alacena/services/theme_service.dart';
import 'package:gestor_alacena/widgets/theme_switch.dart';

/// Widget de la pantalla de estadísticas.
/// 
/// Tercera pestaña de la navegación principal que muestra análisis
/// visuales del inventario y patrones de consumo de la familia.
class StatisticsScreen extends StatefulWidget {
  /// Constructor const para optimizar el rendimiento.
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// Estado de la pantalla de estadísticas.
/// 
/// Gestiona la carga de datos estadísticos y la visualización
/// de múltiples tipos de gráficos usando la librería fl_chart.
class _StatisticsScreenState extends State<StatisticsScreen> {
  /// Inicializa el estado y carga las estadísticas.
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga todas las estadísticas de la familia.
  /// 
  /// Este método se llama:
  /// - Al inicializar la pantalla ([initState])
  /// - Al hacer pull-to-refresh
  Future<void> _loadData() async {
    final authService = context.read<AuthService>();
    final statsService = context.read<StatisticsService>();
    
    if (authService.familyId != null) {
      await statsService.loadStatistics(authService.familyId!);
    }
  }

  /// Convierte un código hexadecimal a un objeto Color de Flutter.
  /// 
  /// Soporta códigos con o sin el prefijo '#' y de 6 o 7 caracteres.
  /// Agrega opacidad completa (ff) si no está presente.
  /// 
  /// [hexString] Código hexadecimal del color (ej: "#FF5722" o "FF5722").
  /// 
  /// Retorna un objeto [Color] listo para usar en widgets.
  /// 
  /// Ejemplo:
  /// ```dart
  /// final color = _hexToColor("#FF5722"); // Color naranja
  /// final color2 = _hexToColor("34A853"); // Color verde
  /// ```
  Color _hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Muestra un diálogo con el historial de meses anteriores.
  /// 
  /// Presenta una lista de meses con sus consumos totales,
  /// ordenados cronológicamente (más reciente primero).
  /// 
  /// [context] Contexto de construcción.
  /// [olderMonths] Lista de meses anteriores con sus consumos.
  void _showOlderMonths(BuildContext context, List<MonthlyConsumption> olderMonths) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Historial de consumo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: olderMonths.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'No hay datos de meses anteriores',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: olderMonths.length,
                  itemBuilder: (context, index) {
                    final month = olderMonths[index];
                    return ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF34A853).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.calendar_month_rounded,
                          color: Color(0xFF34A853),
                        ),
                      ),
                      title: Text('${month.month} ${month.year}'),
                      trailing: Text(
                        NumberFormat.currency(
                          symbol: '\$',
                          decimalDigits: 2,
                        ).format(month.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Calcula el intervalo óptimo para el eje Y del gráfico de barras.
  /// 
  /// Determina un intervalo apropiado para las líneas de cuadrícula
  /// horizontales basándose en el valor máximo del gráfico.
  /// 
  /// [maxValue] Valor máximo que aparecerá en el gráfico.
  /// 
  /// Retorna un intervalo redondeado que resulte en 5-6 líneas de cuadrícula.
  /// 
  /// Rangos de intervalos:
  /// - 0-500: intervalos de 100
  /// - 501-1000: intervalos de 200
  /// - 1001-2500: intervalos de 500
  /// - 2501-5000: intervalos de 1000
  /// - 5001-10000: intervalos de 2000
  /// - >10000: intervalos de 5000
  double _calculateInterval(double maxValue) {
    if (maxValue <= 500) return 100;
    if (maxValue <= 1000) return 200;
    if (maxValue <= 2500) return 500;
    if (maxValue <= 5000) return 1000;
    if (maxValue <= 10000) return 2000;
    return 5000;
  }

  /// Construye la interfaz principal de la pantalla de estadísticas.
  /// 
  /// La pantalla se estructura en tres secciones principales:
  /// 
  /// 1. **Gráfico de Pastel** (Distribución por Categorías):
  ///    - Muestra la proporción de productos por categoría
  ///    - Usa colores predefinidos de cada categoría
  ///    - Incluye porcentajes y leyenda detallada
  ///    - Total de unidades en el inventario
  /// 
  /// 2. **Card de Valor Total**:
  ///    - Muestra el valor monetario total del inventario
  ///    - Diseño destacado con gradiente verde
  ///    - Formato de moneda con símbolo y decimales
  /// 
  /// 3. **Gráfico de Barras** (Consumo Mensual):
  ///    - Últimos 4 meses de consumo
  ///    - Tooltips con valores exactos
  ///    - Botón para ver historial completo
  ///    - Etiquetas de montos debajo de cada barra
  /// 
  /// Todas las secciones incluyen estados vacíos con iconos y mensajes.
  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeService>().isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Estadísticas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: const [
          ThemeSwitch(),
        ],
      ),
      body: Consumer<StatisticsService>(
        builder: (context, service, child) {
          // Estado de carga
          if (service.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF34A853),
              ),
            );
          }
          
          // Contenido principal con pull-to-refresh
          return RefreshIndicator(
            onRefresh: _loadData,
            color: const Color(0xFF34A853),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ===== SECCIÓN 1: GRÁFICO DE PASTEL =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF424242) : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Distribución por categorías',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Estado vacío o gráfico
                        if (service.categoryDistribution.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.pie_chart_outline_rounded,
                                    size: 64,
                                    color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay datos disponibles',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else ...[
                          // Gráfico de pastel
                          SizedBox(
                            height: 250,
                            child: PieChart(
                              PieChartData(
                                sections: service.categoryDistribution
                                    .asMap()
                                    .entries
                                    .map((entry) {
                                  // Calcular porcentaje de cada sección
                                  final total = service.categoryDistribution
                                      .fold(0.0, (sum, item) => sum + item.value);
                                  final percentage = (entry.value.value / total * 100);
                                  
                                  return PieChartSectionData(
                                    color: _hexToColor(entry.value.colorHex),
                                    value: entry.value.value,
                                    title: '${percentage.toStringAsFixed(1)}%',
                                    radius: 100,
                                    titleStyle: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFFFFFFF),
                                      shadows: [
                                        Shadow(
                                          blurRadius: 2,
                                          color: Color(0x89000000),
                                          offset: Offset(1, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                sectionsSpace: 2,
                                centerSpaceRadius: 40,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Badge con total de unidades
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF34A853).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.inventory_2_rounded,
                                  color: Color(0xFF34A853),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Total: ${service.categoryDistribution.fold(0.0, (sum, item) => sum + item.value).toStringAsFixed(0)} unidades',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF34A853),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Leyenda con detalles de cada categoría
                          ...service.categoryDistribution.map((cat) {
                            final total = service.categoryDistribution
                                .fold(0.0, (sum, item) => sum + item.value);
                            final percentage = (cat.value / total * 100);
                            
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  // Cuadro de color
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _hexToColor(cat.colorHex),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nombre de la categoría
                                  Expanded(
                                    child: Text(
                                      cat.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : const Color(0xFF202124),
                                      ),
                                    ),
                                  ),
                                  // Cantidad
                                  Text(
                                    '${cat.value.toStringAsFixed(0)} ',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.grey[400] : Colors.grey[700],
                                    ),
                                  ),
                                  // Porcentaje
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF34A853),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===== SECCIÓN 2: VALOR TOTAL DEL INVENTARIO =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34A853), Color(0xFF2E8B44)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // Icono de billetera
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 32,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Texto y valor
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Valor total del Inventario',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                NumberFormat.currency(
                                  symbol: '\$',
                                  decimalDigits: 2,
                                ).format(service.totalInventoryValue),
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ===== SECCIÓN 3: GRÁFICO DE BARRAS =====
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? const Color(0xFF424242) : const Color(0xFFEEEEEE),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header con título y botón de historial
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Consumo mensual',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? const Color(0xFFFFFFFF) : const Color(0xFF202124),
                                ),
                              ),
                            ),
                            // Botón "Ver más" solo si hay meses anteriores
                            if (service.olderMonths.isNotEmpty)
                              TextButton.icon(
                                onPressed: () => _showOlderMonths(context, service.olderMonths),
                                icon: const Icon(Icons.history_rounded, size: 18),
                                label: const Text('Ver más'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF34A853),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Estado vacío o gráfico
                        if (service.monthlyConsumption.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.bar_chart_rounded,
                                    size: 64,
                                    color: isDark ? const Color(0xFF616161) : const Color(0xFFE0E0E0),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No hay datos disponibles',
                                    style: TextStyle(
                                      color: isDark ? const Color(0xFF757575) : const Color(0xFF9E9E9E),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          // Builder para construir el gráfico con datos calculados
                          Builder(
                            builder: (context) {
                              // Calcular valor máximo para escalar el gráfico
                              final maxValue = service.monthlyConsumption
                                  .map((e) => e.amount)
                                  .reduce((a, b) => a > b ? a : b);
                              final interval = _calculateInterval(maxValue);
                              
                              return Column(
                                children: [
                                  // Gráfico de barras
                                  SizedBox(
                                    height: 280,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceEvenly,
                                        maxY: maxValue * 1.15, // 15% más para espacio superior
                                        minY: 0,
                                        // Configuración de tooltips
                                        barTouchData: BarTouchData(
                                          touchTooltipData: BarTouchTooltipData(
                                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                              return BarTooltipItem(
                                                NumberFormat.currency(
                                                  symbol: '\$',
                                                  decimalDigits: 2,
                                                ).format(rod.toY),
                                                const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                        // Configuración de títulos de ejes
                                        titlesData: FlTitlesData(
                                          show: true,
                                          rightTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          topTitles: const AxisTitles(
                                            sideTitles: SideTitles(showTitles: false),
                                          ),
                                          // Eje X: nombres de meses
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                if (value.toInt() >= 0 &&
                                                    value.toInt() < service.monthlyConsumption.length) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(top: 10.0),
                                                    child: Text(
                                                      service.monthlyConsumption[value.toInt()].month,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 12,
                                                        color: isDark 
                                                            ? const Color(0xFFBDBDBD) 
                                                            : const Color(0xFF5F6368),
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return const Text('');
                                              },
                                              reservedSize: 30,
                                            ),
                                          ),
                                          // Eje Y: valores monetarios
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              reservedSize: 60,
                                              interval: interval,
                                              getTitlesWidget: (value, meta) {
                                                return Padding(
                                                  padding: const EdgeInsets.only(right: 8.0),
                                                  child: Text(
                                                    '\$${value.toInt()}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isDark 
                                                          ? const Color(0xFF9E9E9E) 
                                                          : const Color(0xFF5F6368),
                                                    ),
                                                    textAlign: TextAlign.right,
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                        // Líneas de cuadrícula
                                        gridData: FlGridData(
                                          show: true,
                                          drawVerticalLine: false,
                                          horizontalInterval: interval,
                                          getDrawingHorizontalLine: (value) {
                                            return FlLine(
                                              color: isDark 
                                                  ? const Color(0xFF424242) 
                                                  : const Color(0xFFEEEEEE),
                                              strokeWidth: 1,
                                            );
                                          },
                                        ),
                                        borderData: FlBorderData(show: false),
                                        // Datos de las barras
                                        barGroups: service.monthlyConsumption
                                            .asMap()
                                            .entries
                                            .map((entry) {
                                          return BarChartGroupData(
                                            x: entry.key,
                                            barRods: [
                                              BarChartRodData(
                                                toY: entry.value.amount,
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF34A853),
                                                    Color(0xFF2E8B44),
                                                  ],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                                width: 32,
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Etiquetas de montos debajo de cada barra
                                  Row(
                                    children: service.monthlyConsumption.asMap().entries.map((entry) {
                                      return Expanded(
                                        child: Container(
                                          alignment: Alignment.center,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF34A853).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              NumberFormat.currency(
                                                symbol: '\$',
                                                decimalDigits: 0,
                                              ).format(entry.value.amount),
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF34A853),
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
