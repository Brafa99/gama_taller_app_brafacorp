import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'agregar_productos_view.dart';
import 'editar_producto_view.dart';

class ProductosView extends StatefulWidget {
  final String categoria;
  final String categoriaNombre;

  const ProductosView({
    super.key,
    required this.categoria,
    required this.categoriaNombre,
  });

  @override
  State<ProductosView> createState() => _ProductosViewState();
}

class _ProductosViewState extends State<ProductosView> {
  bool soloBajoStock = false;
  String searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final productosRef = FirebaseFirestore.instance
        .collection('inventarios')
        .doc(uid)
        .collection('categorias')
        .doc(widget.categoria)
        .collection('productos');

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
              child: StreamBuilder<QuerySnapshot>(
                stream: productosRef.snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(color: theme.primaryColor),
                    );
                  }

                  final docs = snapshot.data!.docs;

                  int totalProductos = 0;
                  int totalUnidades = 0;
                  int bajoStockCount = 0;

                  final productos = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;

                    final nombre = (data['nombre'] ?? "").toString().toLowerCase();
                    final marca = (data['marca'] ?? "").toString().toLowerCase();

                    final int cantidad = (data['cantidad'] as num?)?.toInt() ?? 0;
                    final int alerta = (data['alerta_stock'] as num?)?.toInt() ?? 5;

                    final coincideBusqueda =
                        nombre.contains(searchQuery) || marca.contains(searchQuery);
                    final coincideStock = soloBajoStock ? cantidad <= alerta : true;

                    totalProductos++;
                    totalUnidades += cantidad;
                    if (cantidad <= alerta) {
                      bajoStockCount++;
                    }

                    return coincideBusqueda && coincideStock;
                  }).toList();

                  return Column(
                    children: [
                      /// 🛡️ APPBAR Y MÉTRICAS
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.categoriaNombre,
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                _metricMini("Productos", totalProductos, theme),
                                const SizedBox(width: 10),
                                _metricMini("Unidades", totalUnidades, theme),
                                const SizedBox(width: 10),
                                _metricMini("Alertas", bajoStockCount, theme, isAlert: true),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 15),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                              ),
                              child: TextField(
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  icon: Icon(Icons.search, color: theme.primaryColor),
                                  hintText: "Buscar por nombre o marca...",
                                  hintStyle: const TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    searchQuery = value.toLowerCase();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Filtrar solo bajo stock",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Switch(
                                  value: soloBajoStock,
                                  activeColor: theme.primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      soloBajoStock = value;
                                    });
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),

                      Expanded(
                        child: productos.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 140,
                                      child: Lottie.asset(
                                        'assets/lotties/empty.json',
                                        repeat: false,
                                      ),
                                    ),
                                    const SizedBox(height: 15),
                                    const Text(
                                      "No hay productos en esta categoría",
                                      style: TextStyle(color: Colors.white70, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: productos.length,
                                itemBuilder: (context, index) {
                                  final doc = productos[index];
                                  final data = doc.data() as Map<String, dynamic>;
                                  final id = doc.id;

                                  final int cantidad = (data['cantidad'] as num?)?.toInt() ?? 0;
                                  final int alerta = (data['alerta_stock'] as num?)?.toInt() ?? 5;
                                  final bool bajoStock = cantidad <= alerta;

                                  final double porcentaje = alerta == 0
                                      ? 0
                                      : (cantidad / (alerta * 2)).clamp(0.0, 1.0);

                                  final double precioCompra =
                                      (data['precio_compra'] as num?)?.toDouble() ?? 0;
                                  final double precioVenta =
                                      (data['precio_venta'] as num?)?.toDouble() ?? 0;

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: theme.cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: bajoStock ? Colors.redAccent : theme.borderColor.withOpacity(0.3),
                                        width: bajoStock ? 1.5 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: bajoStock
                                              ? Colors.redAccent.withOpacity(0.2)
                                              : theme.primaryColor.withOpacity(0.1),
                                          blurRadius: 15,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            data['imagen_base64'] != null
                                                ? ClipRRect(
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: Image.memory(
                                                      base64Decode(data['imagen_base64']),
                                                      width: 65,
                                                      height: 65,
                                                      fit: BoxFit.cover,
                                                    ),
                                                  )
                                                : Container(
                                                    width: 65,
                                                    height: 65,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white10,
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    child: Icon(Icons.inventory,
                                                        color: theme.primaryColor, size: 34),
                                                  ),
                                            const SizedBox(width: 14),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    data['nombre'] ?? '',
                                                    style: TextStyle(
                                                      color: theme.textColor,
                                                      fontSize: 16,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "Marca: ${data['marca'] ?? '-'}",
                                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                                  ),
                                                  Text(
                                                    "Compra: Bs.${precioCompra.toStringAsFixed(2)} | Venta: Bs.${precioVenta.toStringAsFixed(2)}",
                                                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            /// ⚙️ MENÚ DESPLEGABLE
                                            Container(
                                              decoration: BoxDecoration(
                                                color: theme.primaryColor.withOpacity(0.15),
                                                shape: BoxShape.circle,
                                              ),
                                              child: PopupMenuButton<String>(
                                                icon: Icon(Icons.more_vert, color: theme.primaryColor),
                                                color: const Color(0xFF161616),
                                                elevation: 8,
                                                onSelected: (value) {
                                                  if (value == 'editar') {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (_) => EditarProductoView(
                                                          categoria: widget.categoria,
                                                          productoId: id,
                                                          data: data,
                                                        ),
                                                      ),
                                                    );
                                                  } else if (value == 'eliminar') {
                                                    _confirmarEliminar(productosRef.doc(id), theme);
                                                  } else if (value == 'vender') {
                                                    _actualizarStock(productosRef.doc(id), data, true, theme);
                                                  } else if (value == 'comprar') {
                                                    _actualizarStock(productosRef.doc(id), data, false, theme);
                                                  }
                                                },
                                                itemBuilder: (_) => const [
                                                  PopupMenuItem(
                                                      value: 'editar',
                                                      child: Text('✏ Editar', style: TextStyle(color: Colors.white))),
                                                  PopupMenuItem(
                                                      value: 'eliminar',
                                                      child: Text('🗑 Eliminar', style: TextStyle(color: Colors.white))),
                                                  PopupMenuItem(
                                                      value: 'vender',
                                                      child: Text('💰 Registrar venta', style: TextStyle(color: Colors.white))),
                                                  PopupMenuItem(
                                                      value: 'comprar',
                                                      child: Text('📦 Agregar stock', style: TextStyle(color: Colors.white))),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "Stock actual: $cantidad",
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            if (bajoStock)
                                              const Text(
                                                "⚠ Bajo Stock",
                                                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 12),
                                              )
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        LinearProgressIndicator(
                                          value: porcentaje,
                                          backgroundColor: Colors.white10,
                                          valueColor: AlwaysStoppedAnimation(
                                              bajoStock ? Colors.redAccent : theme.primaryColor),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: theme.primaryColor,
            elevation: 8,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AgregarProductoView(
                    categoria: widget.categoria,
                    categoriaNombre: widget.categoriaNombre,
                  ),
                ),
              );
            },
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        );
      },
    );
  }

  Widget _metricMini(String title, int value, AppThemeModel theme, {bool isAlert = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.borderColor.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: isAlert ? Colors.redAccent : theme.primaryColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarEliminar(DocumentReference ref, AppThemeModel theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Eliminar producto", style: TextStyle(color: Colors.white)),
        content: const Text("¿Seguro que deseas eliminar este producto?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              await ref.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  void _actualizarStock(DocumentReference ref, Map<String, dynamic> data, bool restar, AppThemeModel theme) async {
    final int cantidadActual = (data['cantidad'] as num?)?.toInt() ?? 0;
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(restar ? "Registrar Venta" : "Agregar Stock", style: TextStyle(color: theme.textColor)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Ingrese cantidad",
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar", style: TextStyle(color: Colors.white54))),
          TextButton(
            onPressed: () async {
              final cambio = int.tryParse(controller.text) ?? 0;
              if (restar && cambio > cantidadActual) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Stock insuficiente"), backgroundColor: Colors.red),
                );
                return;
              }
              final nuevoStock = restar ? cantidadActual - cambio : cantidadActual + cambio;
              await ref.update({'cantidad': nuevoStock});
              if (context.mounted) Navigator.pop(context);
            },
            child: Text("Guardar", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}