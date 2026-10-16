import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'productos_view.dart';

class InventarioView extends StatefulWidget {
  const InventarioView({super.key});

  @override
  State<InventarioView> createState() => _InventarioViewState();
}

class _InventarioViewState extends State<InventarioView> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  final categorias = [
    {"nombre": "Aceites y Lubricantes", "key": "aceites", "imagen": "assets/aceite2.png"},
    {"nombre": "Motor", "key": "motores", "imagen": "assets/motor.png"},
    {"nombre": "Sistema Eléctrico", "key": "electricos", "imagen": "assets/electrico.png"},
    {"nombre": "Accesorios", "key": "accesorios", "imagen": "assets/accesorios.png"},
  ];

  Future<Map<String, dynamic>> _calcularMetricas() async {
    int totalUnidades = 0;
    int productosBajoStock = 0;
    double valorInventario = 0;

    for (var cat in categorias) {
      final snapshot = await FirebaseFirestore.instance
          .collection('inventarios')
          .doc(uid)
          .collection('categorias')
          .doc(cat["key"])
          .collection('productos')
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();

        final cantidadRaw = data['cantidad'];
        final int cantidad = cantidadRaw is num ? cantidadRaw.toInt() : 0;
        final alerta = (data['alerta_stock'] ?? 5);
        final precioCompra = (data['precio_compra'] ?? 0).toDouble();

        totalUnidades += cantidad;
        valorInventario += cantidad * precioCompra;

        if (cantidad <= alerta) {
          productosBajoStock++;
        }
      }
    }

    return {
      "totalUnidades": totalUnidades,
      "bajoStock": productosBajoStock,
      "valor": valorInventario,
    };
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
                  /// 🛡️ APPBAR PERSONALIZADA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.inventory_2, color: theme.primaryColor, size: 26),
                        const SizedBox(width: 10),
                        Text(
                          "Gestión de Inventario",
                          style: TextStyle(
                            color: theme.textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _calcularMetricas(),
                      builder: (context, snapshot) {
                        final total = snapshot.data?['totalUnidades'] ?? 0;
                        final bajoStock = snapshot.data?['bajoStock'] ?? 0;
                        final valor = snapshot.data?['valor'] ?? 0.0;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🎬 LOTTIE HEADER
                              Center(
                                child: SizedBox(
                                  height: 140,
                                  child: Lottie.asset(
                                    'assets/lotties/inventory.json',
                                    repeat: true,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 20),

                              /// 📊 MÉTRICAS CON ESTILO NEÓN
                              Row(
                                children: [
                                  Expanded(
                                    child: _metricCard(
                                      "Inventario Total",
                                      total.toString(),
                                      Icons.layers,
                                      theme,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: _metricCard(
                                      "Bajo Stock",
                                      bajoStock.toString(),
                                      Icons.warning_amber_rounded,
                                      theme,
                                      isAlert: true,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              SizedBox(
                                width: double.infinity,
                                child: _metricCard(
                                  "Valor Total Inventario",
                                  "Bs. ${valor.toStringAsFixed(2)}",
                                  Icons.attach_money,
                                  theme,
                                ),
                              ),

                              const SizedBox(height: 30),

                              Text(
                                "Categorías",
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 16),

                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: categorias.length,
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 0.95,
                                ),
                                itemBuilder: (context, index) {
                                  final cat = categorias[index];
                                  return _categoriaCard(context, cat, theme);
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon, AppThemeModel theme, {bool isAlert = false}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAlert ? Colors.redAccent : theme.borderColor.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isAlert ? Colors.redAccent : theme.primaryColor).withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isAlert ? Colors.redAccent : theme.primaryColor, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: isAlert ? Colors.redAccent : theme.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriaCard(BuildContext context, Map<String, dynamic> cat, AppThemeModel theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductosView(
              categoria: cat["key"]!,
              categoriaNombre: cat["nombre"]!,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.borderColor.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(cat["imagen"]!, width: 60),
              const SizedBox(height: 12),
              Text(
                cat["nombre"]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}