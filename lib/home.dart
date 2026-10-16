import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'clients_view.dart';
import 'ganancias_screen.dart';
import 'login.dart';
import 'inventario_view.dart';
import 'recordatorios_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? user;

  @override
  void initState() {
    super.initState();
    user = FirebaseAuth.instance.currentUser;
    _verificarYCrearConfiguracionInicial();
  }

  Future<void> _verificarYCrearConfiguracionInicial() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final docRef = FirebaseFirestore.instance.collection('configuracion_taller').doc(currentUser.uid);
    final docSnap = await docRef.get();

    if (!docSnap.exists) {
      await docRef.set({
        'nombre_taller': 'TALLER GAMA',
        'subtitulo': 'Panel Administrativo',
      });
    }
  }

  // Método de Logout seguro
  Future<void> _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  // Modal para cambiar entre los 5 estilos futuristas globalmente
  void _showThemeSelector(BuildContext context, AppThemeModel currentTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "⚡ SELECCIONAR ESTILO FUTURISTA GLOBAL",
                style: TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 15),
              ...AppThemes.themes.map((theme) {
                return ListTile(
                  leading: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor,
                      boxShadow: [
                        BoxShadow(
                          color: theme.primaryColor.withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                  ),
                  title: Text(
                    theme.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  trailing: currentTheme.name == theme.name
                      ? const Icon(Icons.check_circle, color: Colors.cyanAccent)
                      : null,
                  onTap: () {
                    setState(() {
                      currentThemeNotifier.value = theme;
                    });
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // Modal para editar el Nombre del Taller y la Descripción en Firestore en tiempo real
  void _mostrarEditarTallerDialog(String nombreActual, String subtituloActual, AppThemeModel theme) {
    final nombreCtrl = TextEditingController(text: nombreActual);
    final subtituloCtrl = TextEditingController(text: subtituloActual);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: theme.borderColor.withOpacity(0.5)),
        ),
        title: Text(
          "Personalizar Taller",
          style: TextStyle(color: theme.textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nombreCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Nombre del Taller",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: subtituloCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "Descripción / Subtítulo",
                labelStyle: const TextStyle(color: Colors.white70),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: theme.primaryColor)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: theme.primaryColor),
            onPressed: () async {
              final currentUser = FirebaseAuth.instance.currentUser;
              if (currentUser != null) {
                await FirebaseFirestore.instance
                    .collection('configuracion_taller')
                    .doc(currentUser.uid)
                    .set({
                  'nombre_taller': nombreCtrl.text.trim(),
                  'subtitulo': subtituloCtrl.text.trim(),
                }, SetOptions(merge: true));
              }
              if (mounted) Navigator.pop(context);
            },
            child: const Text("Guardar", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const Scaffold(body: Center(child: Text("No autenticado")));

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    /// ================= BARRA SUPERIOR CON CONTROLES =================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SISTEMA GAMA v2.0",
                          style: TextStyle(
                            color: theme.primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        Row(
                          children: [
                            // Botón de Selector de Tema Global
                            IconButton(
                              icon: Icon(Icons.palette, color: theme.primaryColor),
                              tooltip: "Cambiar Estilo Futurista",
                              onPressed: () => _showThemeSelector(context, theme),
                            ),
                            // Botón de Cierre de Sesión (Logout) en AppBar
                            IconButton(
                              icon: const Icon(Icons.logout, color: Colors.redAccent),
                              tooltip: "Cerrar Sesión",
                              onPressed: () => _logout(context),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    /// ================= HERO PANEL CON NEÓN Y DATOS EN TIEMPO REAL =================
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('configuracion_taller')
                          .doc(currentUser.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        String nombreTaller = "TALLER GAMA";
                        String subtitulo = "Panel Administrativo";

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          nombreTaller = data['nombre_taller'] ?? "TALLER GAMA";
                          subtitulo = data['subtitulo'] ?? "Panel Administrativo";
                        }

                        return Container(
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.primaryColor.withOpacity(0.3), theme.cardColor],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: theme.borderColor.withOpacity(0.5), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          subtitulo,
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => _mostrarEditarTallerDialog(nombreTaller, subtitulo, theme),
                                          child: Icon(Icons.edit, size: 14, color: theme.primaryColor),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            nombreTaller,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.edit_note, color: theme.primaryColor, size: 20),
                                          tooltip: "Editar Nombre y Título",
                                          onPressed: () => _mostrarEditarTallerDialog(nombreTaller, subtitulo, theme),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: theme.primaryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "ESTILO: ${theme.name.toUpperCase()}",
                                        style: TextStyle(
                                          color: theme.primaryColor,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              // Imagen de la Moto Futurista
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    )
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.asset(
                                    'assets/moto_futurista.png',
                                    height: 95,
                                    width: 95,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Icon(
                                      Icons.motorcycle,
                                      size: 60,
                                      color: theme.primaryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 25),

                    /// ================= MENÚ PRINCIPAL =================
                    GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _menuCard(Icons.people, "Clientes", const ClientesScreen(), theme),
                        _menuCard(Icons.inventory_2, "Inventario", const InventarioView(), theme),
                        _menuCard(Icons.bar_chart, "Finanzas", const FinanzasScreen(), theme),
                        _menuCard(Icons.notifications, "Recordatorios", const RecordatoriosScreen(), theme),
                      ],
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      "Últimos Movimientos",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 14),

                    _ultimosMovimientos(theme, currentUser.uid),

                    const SizedBox(height: 30),

                    /// ================= BOTÓN DE LOGOUT EXTRA EN EL SCROLL =================
                    Center(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent, width: 1.5),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        label: const Text(
                          "CERRAR SESIÓN",
                          style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1),
                        ),
                        onPressed: () => _logout(context),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// ================= MENU CARD FUTURISTA =================
  Widget _menuCard(IconData icon, String title, Widget screen, AppThemeModel theme) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.borderColor.withOpacity(0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: theme.primaryColor.withOpacity(0.12),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: theme.primaryColor, size: 36),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ================= ÚLTIMOS MOVIMIENTOS =================
  Widget _ultimosMovimientos(AppThemeModel theme, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('movimientos')
          .where('adminId', isEqualTo: uid)
          .orderBy('fecha', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Error cargando movimientos",
              style: TextStyle(color: Colors.redAccent),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Lottie.asset(
              "assets/lotties/loading.json",
              height: 100,
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              children: [
                Lottie.asset(
                  "assets/lotties/empty.json",
                  height: 140,
                ),
                const SizedBox(height: 8),
                const Text(
                  "Aún no hay movimientos registrados",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final bool esIngreso = data['tipo'] == 'ingreso';

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border(
                  left: BorderSide(
                    color: esIngreso ? Colors.greenAccent : theme.primaryColor,
                    width: 4,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    esIngreso ? Icons.arrow_upward : Icons.arrow_downward,
                    color: esIngreso ? Colors.greenAccent : theme.primaryColor,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['descripcion'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          data['categoria'] ?? '',
                          style: const TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Bs ${(data['monto'] ?? 0).toString()}",
                    style: TextStyle(
                      color: esIngreso ? Colors.greenAccent : theme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}