import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'crear_orden_screen.dart';
import 'orden_detalle_screen.dart';

class EditarClienteScreen extends StatefulWidget {
  final String clienteId;

  const EditarClienteScreen({super.key, required this.clienteId});

  @override
  State<EditarClienteScreen> createState() => _EditarClienteScreenState();
}

class _EditarClienteScreenState extends State<EditarClienteScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
                        Text(
                          "Detalle de Cliente",
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestore.collection('clientes').doc(widget.clienteId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(color: theme.primaryColor),
                          );
                        }

                        final data = snapshot.data!.data() as Map<String, dynamic>;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔴 NOMBRE
                              Center(
                                child: Text(
                                  data['nombre'] ?? '',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              /// 🔴 FOTO CLIENTE / MOTO
                              Center(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: theme.borderColor.withOpacity(0.5), width: 1.5),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryColor.withOpacity(0.2),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: data['fotoBase64'] != null
                                        ? Image.memory(
                                            base64Decode(data['fotoBase64']),
                                            height: 180,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                          )
                                        : Container(
                                            height: 160,
                                            width: double.infinity,
                                            color: theme.cardColor,
                                            child: Icon(
                                              Icons.motorcycle,
                                              size: 80,
                                              color: theme.primaryColor,
                                            ),
                                          ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              /// 🔴 TÍTULO + BOTÓN NUEVA ORDEN
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Órdenes de Trabajo",
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: theme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, color: Colors.black),
                                    label: const Text(
                                      "Nueva",
                                      style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CrearOrdenScreen(
                                            clienteId: widget.clienteId,
                                            clienteNombre: data['nombre'],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                ],
                              ),

                              const SizedBox(height: 16),

                              /// 🔴 LISTADO DE ÓRDENES
                              StreamBuilder<QuerySnapshot>(
                                stream: _firestore
                                    .collection('clientes')
                                    .doc(widget.clienteId)
                                    .collection('ordenes')
                                    .orderBy('fechaCreacion', descending: true)
                                    .snapshots(),
                                builder: (context, snapshotOrdenes) {
                                  if (!snapshotOrdenes.hasData) {
                                    return Center(
                                      child: CircularProgressIndicator(color: theme.primaryColor),
                                    );
                                  }

                                  final ordenes = snapshotOrdenes.data!.docs;

                                  if (ordenes.isEmpty) {
                                    return Center(
                                      child: Column(
                                        children: [
                                          Lottie.asset(
                                            'assets/lotties/empty.json',
                                            height: 130,
                                          ),
                                          const SizedBox(height: 10),
                                          const Text(
                                            "Este cliente aún no tiene órdenes registradas",
                                            style: TextStyle(color: Colors.white70),
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return Column(
                                    children: ordenes.map((doc) {
                                      final orden = doc.data() as Map<String, dynamic>;
                                      final montoTotal = (orden['montoTotal'] as num?)?.toDouble() ?? 0;
                                      final pagos = (orden['pagos'] ?? []) as List;
                                      double totalPagado = 0;

                                      for (var p in pagos) {
                                        totalPagado += (p['monto'] as num?)?.toDouble() ?? 0;
                                      }

                                      double progreso = montoTotal == 0 ? 0 : (totalPagado / montoTotal).clamp(0.0, 1.0);

                                      Color bordeColor;
                                      if (progreso >= 1) {
                                        bordeColor = Colors.greenAccent;
                                      } else if (progreso >= 0.5) {
                                        bordeColor = Colors.orangeAccent;
                                      } else {
                                        bordeColor = theme.primaryColor;
                                      }

                                      final fecha = (orden['fechaCreacion'] as Timestamp?)?.toDate();

                                      return GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => OrdenDetalleScreen(
                                                clienteId: widget.clienteId,
                                                clienteNombre: data['nombre'],
                                                ordenId: doc.id,
                                              ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 16),
                                          padding: const EdgeInsets.all(18),
                                          decoration: BoxDecoration(
                                            color: theme.cardColor,
                                            borderRadius: BorderRadius.circular(20),
                                            border: Border.all(
                                              color: bordeColor,
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: bordeColor.withOpacity(0.15),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              )
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                orden['numeroOrden'] ?? 'ORDEN S/N',
                                                style: TextStyle(
                                                  color: theme.primaryColor,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                orden['descripcion'] ?? '',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              if (fecha != null)
                                                Text(
                                                  "Fecha: ${fecha.day}/${fecha.month}/${fecha.year}",
                                                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                                                ),
                                              const SizedBox(height: 10),
                                              Text(
                                                "Pagado: Bs. $totalPagado  •  Total: Bs. $montoTotal",
                                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
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
}