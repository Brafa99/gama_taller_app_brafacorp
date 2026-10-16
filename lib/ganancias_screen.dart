// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:taller_gama/app_theme.dart';

class FinanzasScreen extends StatefulWidget {
  const FinanzasScreen({super.key});

  @override
  State<FinanzasScreen> createState() => _FinanzasScreenState();
}

class _FinanzasScreenState extends State<FinanzasScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  Stream<QuerySnapshot> _movimientosStream(String tipo) {
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('movimientos')
        .where('adminId', isEqualTo: user!.uid)
        .where('tipo', isEqualTo: tipo)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> _resumenStream() {
    if (user == null) return const Stream.empty();
    return _firestore
        .collection('movimientos')
        .where('adminId', isEqualTo: user!.uid)
        .orderBy('fecha', descending: true)
        .snapshots();
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  double _calcularTotal(List<QueryDocumentSnapshot> docs) {
    double total = 0;
    for (var doc in docs) {
      total += (doc['monto'] as num).toDouble();
    }
    return total;
  }

  Future<void> _mostrarDialogMovimiento(String tipo, AppThemeModel theme) async {
    final formKey = GlobalKey<FormState>();
    final montoController = TextEditingController();
    final descripcionController = TextEditingController();
    String? categoriaSeleccionada;

    final categoriasIngreso = ['venta', 'servicio', 'otro'];
    final categoriasEgreso = ['compra', 'pagos a otros', 'servicios', 'otro'];
    final categorias = tipo == 'ingreso' ? categoriasIngreso : categoriasEgreso;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: theme.borderColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tipo == 'ingreso' ? "Nuevo Ingreso" : "Nuevo Egreso",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    dropdownColor: theme.cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInput("Categoría", theme),
                    items: categorias
                        .map((e) => DropdownMenuItem(value: e, child: Text(e.toUpperCase())))
                        .toList(),
                    onChanged: (value) => categoriaSeleccionada = value,
                    validator: (value) => value == null ? 'Seleccione categoría' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInput("Monto (Bs)", theme),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Ingrese monto';
                      if (double.tryParse(value) == null) return 'Monto inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descripcionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: _dialogInput("Descripción", theme),
                    validator: (value) => value == null || value.isEmpty ? 'Ingrese descripción' : null,
                  ),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancelar", style: TextStyle(color: Colors.white70)),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            await _firestore.collection('movimientos').add({
                              'adminId': user!.uid,
                              'tipo': tipo,
                              'categoria': categoriaSeleccionada,
                              'monto': double.parse(montoController.text),
                              'descripcion': descripcionController.text,
                              'clienteId': null,
                              'clienteNombre': null,
                              'fecha': Timestamp.now(),
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  InputDecoration _dialogInput(String label, AppThemeModel theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: theme.backgroundGradient[0],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
    );
  }

  Future<void> _generarPDF(List<QueryDocumentSnapshot> docs) async {
    final pdf = pw.Document();
    final totalIngresos = _calcularTotal(docs.where((e) => e['tipo'] == 'ingreso').toList());
    final totalEgresos = _calcularTotal(docs.where((e) => e['tipo'] == 'egreso').toList());
    final balance = totalIngresos - totalEgresos;

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text("REPORTE FINANCIERO GAMA", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 20),
          pw.Text("Total Ingresos: Bs. ${totalIngresos.toStringAsFixed(2)}"),
          pw.Text("Total Egresos: Bs. ${totalEgresos.toStringAsFixed(2)}"),
          pw.Text("Balance: Bs. ${balance.toStringAsFixed(2)}"),
          pw.SizedBox(height: 20),
          pw.TableHelper.fromTextArray(
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
            headers: ['Fecha', 'Tipo', 'Categoría', 'Descripción', 'Monto'],
            data: docs.map((doc) {
              return [
                _formatDate(doc['fecha']),
                doc['tipo'],
                doc['categoria'] ?? '',
                doc['descripcion'],
                doc['monto'].toString(),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _buildMovimientoCard(QueryDocumentSnapshot doc, AppThemeModel theme) {
    final tipo = doc['tipo'];
    final monto = (doc['monto'] as num?)?.toDouble() ?? 0;
    final descripcion = doc['descripcion'] ?? '';
    final categoria = doc['categoria'] ?? '';
    final fecha = _formatDate(doc['fecha']);
    final esIngreso = tipo == 'ingreso';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: esIngreso ? Colors.greenAccent : theme.primaryColor,
          width: 1.2,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(descripcion, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text("Categoría: $categoria", style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text("Fecha: $fecha", style: const TextStyle(color: Colors.white38, fontSize: 12)),
          const SizedBox(height: 10),
          Text(
            "Bs. ${monto.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: esIngreso ? Colors.greenAccent : theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLista(String tipo, AppThemeModel theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _movimientosStream(tipo),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error cargando movimientos", style: TextStyle(color: Colors.red)));
        }
        final docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Lottie.asset('assets/lotties/empty.json', height: 140));
        }
        return ListView(children: docs.map((doc) => _buildMovimientoCard(doc, theme)).toList());
      },
    );
  }

  Widget _buildResumen(AppThemeModel theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: _resumenStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
        }

        final docs = snapshot.data!.docs;
        final ingresos = docs.where((e) => e['tipo'] == 'ingreso').toList();
        final egresos = docs.where((e) => e['tipo'] == 'egreso').toList();
        final totalIngresos = _calcularTotal(ingresos);
        final totalEgresos = _calcularTotal(egresos);
        final balance = totalIngresos - totalEgresos;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: theme.primaryColor.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text("BALANCE GENERAL", style: TextStyle(color: Colors.white70, letterSpacing: 1.2)),
                    const SizedBox(height: 10),
                    Text(
                      "Bs. ${balance.toStringAsFixed(2)}",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.greenAccent : theme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text("Ingresos", style: TextStyle(color: Colors.white54)),
                            Text("Bs. ${totalIngresos.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Egresos", style: TextStyle(color: Colors.white54)),
                            Text("Bs. ${totalEgresos.toStringAsFixed(2)}", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(value: totalIngresos, title: "Ingresos", color: Colors.greenAccent, radius: 60),
                      PieChartSectionData(value: totalEgresos, title: "Egresos", color: theme.primaryColor, radius: 60),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeModel>(
      valueListenable: currentThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: theme.backgroundGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  /// 🛡️ APPBAR Y TABS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 6),
                            Icon(Icons.bar_chart, color: theme.primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              "Finanzas",
                              style: TextStyle(
                                color: theme.textColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                            ),
                          ],
                        ),
                        if (_tabController.index == 0)
                          IconButton(
                            icon: Icon(Icons.picture_as_pdf, color: theme.primaryColor),
                            onPressed: () async {
                              final snapshot = await _resumenStream().first;
                              if (snapshot.docs.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("No hay movimientos para generar PDF")),
                                );
                                return;
                              }
                              _generarPDF(snapshot.docs);
                            },
                          ),
                      ],
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: theme.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                    tabs: const [
                      Tab(icon: Icon(Icons.dashboard, size: 18), text: "Resumen"),
                      Tab(icon: Icon(Icons.trending_up, size: 18), text: "Ingresos"),
                      Tab(icon: Icon(Icons.trending_down, size: 18), text: "Egresos"),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 110,
                    child: Lottie.asset('assets/lotties/finance.json', repeat: true),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildResumen(theme),
                        _buildLista('ingreso', theme),
                        _buildLista('egreso', theme),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: _tabController.index == 0
              ? null
              : FloatingActionButton(
                  backgroundColor: theme.primaryColor,
                  elevation: 8,
                  onPressed: () {
                    if (_tabController.index == 1) {
                      _mostrarDialogMovimiento('ingreso', theme);
                    } else {
                      _mostrarDialogMovimiento('egreso', theme);
                    }
                  },
                  child: const Icon(Icons.add, color: Colors.black, size: 28),
                ),
        );
      },
    );
  }
}