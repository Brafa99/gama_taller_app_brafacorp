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
  final user = FirebaseAuth.instance.currentUser;
  final _firestore = FirebaseFirestore.instance;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _firestore
                          .collection('clientes')
                          .where('adminId', isEqualTo: user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return Center(
                            child: CircularProgressIndicator(color: theme.primaryColor),
                          );
                        }

                        final clientes = snapshot.data!.docs;

                        return TabBarView(
                          controller: _tabController,
                          children: [
                            _buildLista(clientes, true, theme),
                            _buildLista(clientes, false, theme),
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

  Widget _buildLista(List<QueryDocumentSnapshot> clientes, bool soloPendientes, AppThemeModel theme) {
    List<Widget> items = [];

    for (var cliente in clientes) {
      final data = cliente.data() as Map<String, dynamic>;
      final nombre = data['nombre'] ?? '';
      final celular = data['celular'] ?? '';

      final pagos = (data['pagos'] ?? []) as List;
      final totalPagos = pagos.fold<double>(
          0, (s, p) => s + ((p['monto'] as num?)?.toDouble() ?? 0));

      final montoEstimado = (data['montoEstimado'] as num?)?.toDouble() ?? 0;
      final saldo = ((montoEstimado - totalPagos).clamp(0, double.infinity)).toDouble();
      final pendiente = saldo > 0 && data['pagado'] != true;

      if (soloPendientes && !pendiente) continue;

      items.add(
        Container(
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
              Text(
                nombre,
                style: TextStyle(
                  color: theme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Saldo: Bs ${saldo.toStringAsFixed(2)}",
                style: const TextStyle(
                  color: Colors.greenAccent,
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
                    final mensaje = generarMensajeProfesional(
                      nombre: nombre,
                      servicio: "Servicio de Taller",
                      numeroOrden: "S/N",
                      saldo: saldo,
                      diasVencido: 0,
                    );
                    _abrirWhatsApp('+591$celular', mensaje);
                  },
                ),
              )
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const Center(
        child: Text(
          "No hay registros disponibles",
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 10),
      children: items,
    );
  }
}