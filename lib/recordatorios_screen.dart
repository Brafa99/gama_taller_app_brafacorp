import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:taller_gama/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecordatoriosScreen extends StatefulWidget {
  const RecordatoriosScreen({super.key});

  @override
  State<RecordatoriosScreen> createState() => _RecordatoriosScreenState();
}

class _RecordatoriosScreenState extends State<RecordatoriosScreen>
    with SingleTickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _abrirWhatsApp(String numero, String mensaje) async {
    final numeroLimpio = numero.replaceAll(RegExp(r'[^0-9]'), '');

    final Uri appUri = Uri.parse(
        "whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}");

    final Uri webUri = Uri.parse(
        "https://wa.me/$numeroLimpio?text=${Uri.encodeComponent(mensaje)}");

    if (await canLaunchUrl(appUri)) {
      await launchUrl(appUri);
    } else {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  String generarMensajeProfesional({
    required String nombre,
    required String servicio,
    required String numeroOrden,
    required double saldo,
    required int diasVencido,
    String extra = "",
  }) {
    final estadoTexto = diasVencido > 0
        ? "⚠️ *ATENCIÓN: $diasVencido días de retraso*"
        : "📌 *Recordatorio de pago*";

    final adicional = extra.isNotEmpty ? "\n\n📎 *Adicionalmente:*\n$extra" : "";

    return """
👋 Hola *$nombre*,

$estadoTexto

Te escribimos respecto al servicio:
_*$servicio*_

🧾 Orden: *#$numeroOrden*
💰 Saldo pendiente: *Bs ${saldo.toStringAsFixed(2)}*

Agradecemos puedas regularizar el pago a la brevedad posible.

Si ya realizaste el pago, por favor ignora este mensaje o envíanos el comprobante.$adicional

_Gracias por tu confianza._

*TALLER GAMA*
""";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                        Icon(Icons.notifications_active, color: theme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          "Gestión de Recordatorios",
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// PESTAÑAS (TABS)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TabBar(
                      controller: _tabController,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: theme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.black,
                      unselectedLabelColor: Colors.white54,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                      tabs: const [
                        Tab(text: "Pendientes"),
                        Tab(text: "Todos"),
                      ],
                    ),
                  ),

                  Expanded(
                    child: user == null
                        ? Center(
                            child: Text(
                              "Usuario no autenticado",
                              style: TextStyle(color: theme.textColor),
                            ),
                          )
                        : StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('clientes')
                                .where('adminId', isEqualTo: user.uid)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(color: theme.primaryColor),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                return const Center(
                                  child: Text(
                                    "No hay clientes registrados",
                                    style: TextStyle(color: Colors.white70, fontSize: 15),
                                  ),
                                );
                              }

                              final clientes = snapshot.data!.docs;

                              return TabBarView(
                                controller: _tabController,
                                children: [
                                  _ClientesListaRecordatorio(clientes: clientes, soloPendientes: true, theme: theme, abrirWhatsApp: _abrirWhatsApp, generarMensaje: generarMensajeProfesional),
                                  _ClientesListaRecordatorio(clientes: clientes, soloPendientes: false, theme: theme, abrirWhatsApp: _abrirWhatsApp, generarMensaje: generarMensajeProfesional),
                                ],
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

/// Widget auxiliar para evaluar dinámicamente las órdenes de cada cliente en tiempo real
class _ClientesListaRecordatorio extends StatelessWidget {
  final List<QueryDocumentSnapshot> clientes;
  final bool soloPendientes;
  final AppThemeModel theme;
  final Function(String, String) abrirWhatsApp;
  final Function({required String nombre, required String servicio, required String numeroOrden, required double saldo, required int diasVencido}) generarMensaje;

  const _ClientesListaRecordatorio({
    required this.clientes,
    required this.soloPendientes,
    required this.theme,
    required this.abrirWhatsApp,
    required this.generarMensaje,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 10),
      itemCount: clientes.length,
      itemBuilder: (context, index) {
        final clienteDoc = clientes[index];
        final clienteData = clienteDoc.data() as Map<String, dynamic>;
        final nombre = clienteData['nombre'] ?? '';
        final celular = clienteData['celular'] ?? '';

        return StreamBuilder<QuerySnapshot>(
          stream: clienteDoc.reference.collection('ordenes').snapshots(),
          builder: (context, ordenesSnap) {
            if (!ordenesSnap.hasData) {
              return const SizedBox.shrink();
            }

            final ordenes = ordenesSnap.data!.docs;
            double totalEstimado = 0;
            double totalPagado = 0;

            for (var orden in ordenes) {
              final dataOrden = orden.data() as Map<String, dynamic>;
              final monto = (dataOrden['montoTotal'] as num?)?.toDouble() ?? 0;
              final pagos = List.from(dataOrden['pagos'] ?? []);
              double pagadoOrden = 0;

              for (var p in pagos) {
                pagadoOrden += (p['monto'] as num?)?.toDouble() ?? 0;
              }

              totalEstimado += monto;
              totalPagado += pagadoOrden;
            }

            final saldo = ((totalEstimado - totalPagado).clamp(0, double.infinity)).toDouble();
            final bool estaPagado = totalEstimado > 0 && totalPagado >= totalEstimado;

            if (soloPendientes && estaPagado) {
              return const SizedBox.shrink(); // Omitir si se piden solo pendientes y ya está pagado
            }

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        nombre,
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: estaPagado ? Colors.green : theme.primaryColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          estaPagado ? 'PAGADO' : 'PENDIENTE',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Saldo pendiente: Bs ${saldo.toStringAsFixed(2)}",
                    style: TextStyle(
                      color: estaPagado ? Colors.greenAccent : Colors.orangeAccent,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.send, color: Colors.black, size: 18),
                      label: const Text(
                        "Enviar WhatsApp",
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        final mensaje = generarMensaje(
                          nombre: nombre,
                          servicio: "Servicio de Taller",
                          numeroOrden: "General",
                          saldo: saldo,
                          diasVencido: 0,
                        );
                        abrirWhatsApp('+591$celular', mensaje);
                      },
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}
