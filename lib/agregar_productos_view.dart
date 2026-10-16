import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:taller_gama/app_theme.dart';


class AgregarProductoView extends StatefulWidget {
  final String categoria;
  final String categoriaNombre;
  const AgregarProductoView({
    super.key,
    required this.categoria,
    required this.categoriaNombre,
  });

  @override
  State<AgregarProductoView> createState() => _AgregarProductoViewState();
}

class _AgregarProductoViewState extends State<AgregarProductoView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _cantidadCtrl = TextEditingController();
  final _precioCompraCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();
  final _alertaCtrl = TextEditingController(text: '5');

  File? _imagen;
  String? _imagenBase64;
  bool _guardando = false;

  Future<void> _seleccionarImagen(AppThemeModel theme) async {
    final picker = ImagePicker();
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library, color: theme.primaryColor),
              title: const Text('Seleccionar desde galería', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: theme.primaryColor),
              title: const Text('Tomar foto con cámara', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'camara'),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );

    if (opcion == null) return;

    XFile? archivo;
    if (opcion == 'galeria') {
      archivo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    } else if (opcion == 'camara') {
      archivo = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    }

    if (archivo != null) {
      final compressed = await FlutterImageCompress.compressWithFile(
        archivo.path,
        minWidth: 800,
        minHeight: 800,
        quality: 60,
        format: CompressFormat.jpeg,
      );

      if (compressed != null) {
        setState(() {
          _imagen = File(archivo!.path);
          _imagenBase64 = base64Encode(compressed);
        });
      }
    }
  }

  Future<void> _guardarProducto() async {
    if (!_formKey.currentState!.validate()) return;

    final precioCompra = double.tryParse(_precioCompraCtrl.text) ?? 0;
    final precioVenta = double.tryParse(_precioVentaCtrl.text) ?? 0;

    if (precioVenta < precioCompra) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("El precio de venta no puede ser menor al de compra"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(user.uid)
          .collection('categorias')
          .doc(widget.categoria)
          .collection('productos');

      await ref.add({
        'nombre': _nombreCtrl.text.trim(),
        'marca': _marcaCtrl.text.trim(),
        'cantidad': int.tryParse(_cantidadCtrl.text) ?? 0,
        'precio_compra': precioCompra,
        'precio_venta': precioVenta,
        'alerta_stock': int.tryParse(_alertaCtrl.text) ?? 5,
        'imagen_base64': _imagenBase64,
        'fecha_ingreso': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Producto agregado correctamente"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error al guardar el producto"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
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
                        Expanded(
                          child: Text(
                            'Agregar a ${widget.categoriaNombre}',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(18),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () => _seleccionarImagen(theme),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: theme.cardColor,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: theme.borderColor.withOpacity(0.4)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                                child: _imagenBase64 != null
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.memory(
                                          base64Decode(_imagenBase64!),
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.camera_alt, color: theme.primaryColor, size: 45),
                                            const SizedBox(height: 8),
                                            const Text('Agregar imagen del producto',
                                                style: TextStyle(color: Colors.white54)),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            _campoTexto(_nombreCtrl, 'Nombre del producto', theme),
                            _campoTexto(_marcaCtrl, 'Marca', theme),
                            _campoTexto(_cantidadCtrl, 'Cantidad', theme, tipo: TextInputType.number),
                            _campoTexto(_precioCompraCtrl, 'Precio de compra (Bs)', theme, tipo: TextInputType.number),
                            _campoTexto(_precioVentaCtrl, 'Precio de venta (Bs)', theme, tipo: TextInputType.number),
                            _campoTexto(_alertaCtrl, 'Alerta de stock (mínimo)', theme, tipo: TextInputType.number),
                            const SizedBox(height: 25),
                            Container(
                              width: double.infinity,
                              height: 55,
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
                                  onTap: _guardando ? null : _guardarProducto,
                                  child: Center(
                                    child: _guardando
                                        ? const CircularProgressIndicator(color: Colors.black)
                                        : const Text(
                                            'GUARDAR PRODUCTO',
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _campoTexto(TextEditingController controller, String label, AppThemeModel theme, {TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        validator: (v) {
          if (v == null || v.isEmpty) return 'Campo obligatorio';
          if (tipo == TextInputType.number) {
            final numValue = num.tryParse(v);
            if (numValue == null) return 'Valor inválido';
            if (numValue < 0) return 'No puede ser negativo';
          }
          return null;
        },
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          filled: true,
          fillColor: theme.cardColor,
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(14),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: theme.primaryColor, width: 2),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}