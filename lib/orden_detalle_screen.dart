import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:intl/intl.dart';
import 'package:taller_gama/app_theme.dart';

class OrdenDetalleScreen extends StatefulWidget {
  final String clienteId;
  final String clienteNombre;
  final String ordenId;

  const OrdenDetalleScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
    required this.ordenId,
  });

  @override
  State<OrdenDetalleScreen> createState() => _OrdenDetalleScreenState();
}

class _OrdenDetalleScreenState extends State<OrdenDetalleScreen> {
  final _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _agregarPago(DocumentSnapshot orden, AppThemeModel theme) async {
    final TextEditingController montoCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Registrar Pago", style: TextStyle(color: theme.textColor)),
        content: TextField(
          controller: montoCtrl,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: "Monto en Bs",
            hintStyle: const TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final monto = double.tryParse(montoCtrl.text);
              if (monto == null || monto <= 0) return;

              await orden.reference.update({
                'pagos': FieldValue.arrayUnion([
                  {
                    'monto': monto,
                    'fecha': Timestamp.now(),
                  }
                ])
              });

              await _firestore.collection('movimientos').add({
                'adminId': user!.uid,
                'tipo': 'ingreso',
                'categoria': 'pago_cliente',
                'clienteId': widget.clienteId,
                'clienteNombre': widget.clienteNombre,
                'ordenId': orden.id,
                'monto': monto,
                'descripcion': 'Pago adicional ${orden['numeroOrden']}',
                'fecha': Timestamp.now(),
              });

              if (context.mounted) Navigator.pop(context);
            },
            child: Text("Guardar", style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Color _colorEstado(double total, double pagado, AppThemeModel theme) {
    if (pagado == 0) return Colors.grey;
    if (pagado < total) return Colors.orangeAccent;
    return Colors.greenAccent;
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
                  /// 🛡️ APPBAR
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
                          "Detalle de Orden",
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Lottie.asset("assets/lotties/work.json", height: 110),
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('clientes')
                          .doc(widget.clienteId)
                          .collection('ordenes')
                          .doc(widget.ordenId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(child: CircularProgressIndicator(color: theme.primaryColor));
                        }

                        if (!snapshot.data!.exists) {
                          return const Center(
                            child: Text("Orden no encontrada", style: TextStyle(color: Colors.white70)),
                          );
                        }

                        final orden = snapshot.data!;
                        final data = orden.data() as Map<String, dynamic>;
                        final montoTotal = (data['montoTotal'] as num?)?.toDouble() ?? 0;
                        final pagos = List.from(data['pagos'] ?? []);
                        double totalPagado = 0;

                        for (var p in pagos) {
                          totalPagado += (p['monto'] as num?)?.toDouble() ?? 0;
                        }

                        double progreso = montoTotal == 0 ? 0 : (totalPagado / montoTotal).clamp(0.0, 1.0);
                        final fecha = (data['fechaCreacion'] as Timestamp?)?.toDate();

                        return ListView(
                          padding: const EdgeInsets.all(18),
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.primaryColor.withOpacity(0.1),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  )
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['numeroOrden'] ?? '',
                                    style: TextStyle(
                                      color: theme.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    data['descripcion'] ?? '',
                                    style: TextStyle(
                                      color: theme.textColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (fecha != null)
                                    Text(
                                      DateFormat('dd MMM yyyy').format(fecha),
                                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  const SizedBox(height: 18),
                                  LinearProgressIndicator(
                                    value: progreso,
                                    backgroundColor: Colors.white10,
                                    color: _colorEstado(montoTotal, totalPagado, theme),
                                    minHeight: 10,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Pagado: Bs. ${totalPagado.toStringAsFixed(2)}  •  Total: Bs. ${montoTotal.toStringAsFixed(2)}",
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                  const SizedBox(height: 20),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: theme.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      onPressed: () => _agregarPago(orden, theme),
                                      icon: const Icon(Icons.add, color: Colors.black),
                                      label: const Text(
                                        "Agregar Pago",
                                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 25),
                            if (pagos.isNotEmpty) ...[
                              Text(
                                "Historial de Pagos",
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              ...pagos.map((p) {
                                final monto = (p['monto'] as num?)?.toDouble() ?? 0;
                                final fechaPago = (p['fecha'] as Timestamp?)?.toDate();

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: theme.borderColor.withOpacity(0.2)),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        fechaPago != null ? DateFormat('dd/MM/yyyy').format(fechaPago) : '',
                                        style: const TextStyle(color: Colors.white54),
                                      ),
                                      Text(
                                        "Bs. ${monto.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                          color: Colors.greenAccent,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ]
                          ],
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}