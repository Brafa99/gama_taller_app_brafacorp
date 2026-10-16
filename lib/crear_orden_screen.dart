import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';


class CrearOrdenScreen extends StatefulWidget {
  final String clienteId;
  final String clienteNombre;

  const CrearOrdenScreen({
    super.key,
    required this.clienteId,
    required this.clienteNombre,
  });

  @override
  State<CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<CrearOrdenScreen> {
  final _formKey = GlobalKey<FormState>();

  final _descripcionCtrl = TextEditingController();
  final _montoCtrl = TextEditingController();
  final _pagoInicialCtrl = TextEditingController();

  bool _guardando = false;
  final _firestore = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _guardarOrden(AppThemeModel theme) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final montoTotal = double.parse(_montoCtrl.text);
      final pagoInicial = double.tryParse(_pagoInicialCtrl.text) ?? 0;

      final ordenesRef = _firestore
          .collection('clientes')
          .doc(widget.clienteId)
          .collection('ordenes');

      final snapshot = await ordenesRef.get();
      final numero = snapshot.docs.length + 1;
      final numeroOrden = "OT-${numero.toString().padLeft(3, '0')}";

      final nuevaOrden = await ordenesRef.add({
        'numeroOrden': numeroOrden,
        'descripcion': _descripcionCtrl.text.trim(),
        'montoTotal': montoTotal,
        'estadoManual': 'en_proceso',
        'fechaCreacion': FieldValue.serverTimestamp(),
        'pagos': pagoInicial > 0
            ? [
                {
                  'monto': pagoInicial,
                  'fecha': Timestamp.now(),
                }
              ]
            : [],
      });

      if (pagoInicial > 0) {
        await _firestore.collection('movimientos').add({
          'adminId': user!.uid,
          'tipo': 'ingreso',
          'categoria': 'pago_cliente',
          'clienteId': widget.clienteId,
          'clienteNombre': widget.clienteNombre,
          'ordenId': nuevaOrden.id,
          'monto': pagoInicial,
          'descripcion': 'Pago inicial $numeroOrden',
          'fecha': Timestamp.now(),
        });
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Error al guardar: $e"),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  InputDecoration _input(String label, AppThemeModel theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.primaryColor, width: 2),
      ),
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
                          "Nueva Orden de Trabajo",
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _guardando
                        ? Center(
                            child: Lottie.asset("assets/lotties/loading.json", height: 120),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                Lottie.asset("assets/lotties/work.json", height: 120),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(25),
                                  decoration: BoxDecoration(
                                    color: theme.cardColor,
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(color: theme.borderColor.withOpacity(0.3)),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.primaryColor.withOpacity(0.1),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      )
                                    ],
                                  ),
                                  child: Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _descripcionCtrl,
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _input("Descripción del trabajo", theme),
                                          validator: (v) => v == null || v.trim().isEmpty ? "Ingrese descripción" : null,
                                        ),
                                        const SizedBox(height: 18),
                                        TextFormField(
                                          controller: _montoCtrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _input("Monto Total (Bs)", theme),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return "Ingrese monto";
                                            if (double.tryParse(v) == null) return "Monto inválido";
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        TextFormField(
                                          controller: _pagoInicialCtrl,
                                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                          style: const TextStyle(color: Colors.white),
                                          decoration: _input("Pago Inicial (opcional)", theme),
                                        ),
                                        const SizedBox(height: 30),
                                        Container(
                                          width: double.infinity,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(colors: [theme.primaryColor, theme.accentColor]),
                                            borderRadius: BorderRadius.circular(16),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.primaryColor.withOpacity(0.4),
                                                blurRadius: 15,
                                                offset: const Offset(0, 5),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius: BorderRadius.circular(16),
                                              onTap: () => _guardarOrden(theme),
                                              child: const Center(
                                                child: Text(
                                                  "CREAR ORDEN",
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
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