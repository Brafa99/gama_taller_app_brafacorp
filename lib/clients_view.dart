import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'editar_cliente_screen.dart';
import 'register_client_view.dart';

class ClientesScreen extends StatefulWidget {
  const ClientesScreen({super.key});

  @override
  State<ClientesScreen> createState() => _ClientesScreenState();
}

class _ClientesScreenState extends State<ClientesScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  Future<void> _eliminarCliente(String clienteId) async {
    try {
      final ordenesSnapshot = await FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteId)
          .collection('ordenes')
          .get();

      for (var doc in ordenesSnapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('clientes')
          .doc(clienteId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Cliente y órdenes eliminados con éxito"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error eliminando: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _confirmarEliminar(String clienteId, AppThemeModel theme) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.borderColor.withOpacity(0.5)),
        ),
        title: Text(
          "Eliminar cliente",
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "¿Seguro que deseas eliminar este cliente y todas sus órdenes?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: const Text(
              "Eliminar",
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.pop(context);
              _eliminarCliente(clienteId);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isSearching = _searchText.isNotEmpty;

    return ValueListenableBuilder<AppThemeModel>(
      valueListenable: currentThemeNotifier,
      builder: (context, theme, child) {
        return Scaffold(
          resizeToAvoidBottomInset: true,
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
                  /// 🛡️ APPBAR PERSONALIZADA FUTURISTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.arrow_back, color: theme.primaryColor),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: 8),
                        Icon(Icons.people, color: theme.primaryColor),
                        const SizedBox(width: 10),
                        Text(
                          "Gestión de Clientes",
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// 🔎 BUSCADOR FUTURISTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _searchText = value.toLowerCase();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Buscar por nombre, placa o celular...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          prefixIcon: Icon(Icons.search, color: theme.primaryColor),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        ),
                      ),
                    ),
                  ),

                  /// 🎞 LOTTIE
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: isSearching
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: SizedBox(
                              height: 120,
                              child: Lottie.asset(
                                'assets/lotties/clients.json',
                                repeat: true,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                  ),

                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('clientes')
                          .where('adminId', isEqualTo: uid)
                          .orderBy('fechaRegistro', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: CircularProgressIndicator(color: theme.primaryColor),
                          );
                        }

                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              "Error cargando clientes",
                              style: TextStyle(color: Colors.redAccent),
                            ),
                          );
                        }

                        final clientes = snapshot.data!.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final nombre = (data['nombre'] ?? '').toString().toLowerCase();
                          final placa = (data['placa'] ?? '').toString().toLowerCase();
                          final celular = (data['celular'] ?? '').toString().toLowerCase();

                          return nombre.contains(_searchText) ||
                              placa.contains(_searchText) ||
                              celular.contains(_searchText);
                        }).toList();

                        if (clientes.isEmpty) {
                          final mensaje = isSearching
                              ? 'No se encontraron resultados'
                              : 'No se encontraron clientes registrados';

                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Lottie.asset(
                                  'assets/lotties/empty.json',
                                  height: 140,
                                ),
                                const SizedBox(height: 15),
                                Text(
                                  mensaje,
                                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: clientes.length,
                          itemBuilder: (context, index) {
                            final doc = clientes[index];
                            final data = doc.data() as Map<String, dynamic>;

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditarClienteScreen(
                                      clienteId: doc.id,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: theme.borderColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    )
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    /// BARRA LATERAL NEÓN
                                    Container(
                                      width: 6,
                                      height: 170,
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor,
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(20),
                                          bottomLeft: Radius.circular(20),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: theme.primaryColor,
                                            blurRadius: 6,
                                          )
                                        ],
                                      ),
                                    ),

                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              data['nombre'] ?? '',
                                              style: TextStyle(
                                                color: theme.textColor,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              "${data['marca'] ?? 'Sin marca'} • Placa: ${data['placa'] ?? 'S/N'}",
                                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "Cel: ${data['celular'] ?? 'No registrado'}",
                                              style: const TextStyle(color: Colors.white54, fontSize: 12),
                                            ),
                                            const SizedBox(height: 12),

                                            /// 📊 FLUJO FINANCIERO DE ÓRDENES
                                            StreamBuilder<QuerySnapshot>(
                                              stream: FirebaseFirestore.instance
                                                  .collection('clientes')
                                                  .doc(doc.id)
                                                  .collection('ordenes')
                                                  .snapshots(),
                                              builder: (context, ordenSnap) {
                                                if (!ordenSnap.hasData) {
                                                  return const SizedBox(
                                                    height: 30,
                                                    child: Center(
                                                      child: LinearProgressIndicator(
                                                        color: Colors.cyanAccent,
                                                        minHeight: 2,
                                                      ),
                                                    ),
                                                  );
                                                }

                                                final ordenes = ordenSnap.data!.docs;

                                                if (ordenes.isEmpty) {
                                                  return Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                    decoration: BoxDecoration(
                                                      color: Colors.white10,
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Text(
                                                      "SIN ÓRDENES",
                                                      style: TextStyle(
                                                        color: Colors.white38,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  );
                                                }

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

                                                final estaPagado = totalEstimado > 0 && totalPagado >= totalEstimado;

                                                return Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(
                                                          "Total: Bs. ${totalEstimado.toStringAsFixed(2)}",
                                                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                                                        ),
                                                        Text(
                                                          "Pagado: Bs. ${totalPagado.toStringAsFixed(2)}",
                                                          style: const TextStyle(
                                                            color: Colors.greenAccent,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 13,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: estaPagado ? Colors.green : theme.primaryColor,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: Text(
                                                        estaPagado ? 'PAGADO' : 'PENDIENTE',
                                                        style: const TextStyle(
                                                          color: Colors.black,
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 11,
                                                        ),
                                                      ),
                                                    )
                                                  ],
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    /// BOTONES DE ACCIÓN (EDITAR / ELIMINAR)
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 22),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditarClienteScreen(clienteId: doc.id),
                                              ),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 22),
                                          onPressed: () => _confirmarEliminar(doc.id, theme),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: theme.primaryColor,
            elevation: 8,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegistrarClienteScreen()),
            ),
            child: const Icon(Icons.add, color: Colors.black, size: 28),
          ),
        );
      },
    );
  }
}