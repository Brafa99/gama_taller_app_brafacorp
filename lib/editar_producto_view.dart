import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class EditarProductoView extends StatefulWidget {
  final String categoria;
  final String productoId;
  final Map<String, dynamic> data;
  const EditarProductoView({
    super.key,
    required this.categoria,
    required this.productoId,
    required this.data,
  });

  @override
  State<EditarProductoView> createState() => _EditarProductoViewState();
}

class _EditarProductoViewState extends State<EditarProductoView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _marcaCtrl;
  late TextEditingController _cantidadCtrl;
  late TextEditingController _precioCompraCtrl;
  late TextEditingController _precioVentaCtrl;
  late TextEditingController _alertaCtrl;

  File? _imagen;
  String? _imagenBase64;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _nombreCtrl = TextEditingController(text: widget.data['nombre']);
    _marcaCtrl = TextEditingController(text: widget.data['marca']);
    _cantidadCtrl = TextEditingController(text: '${widget.data['cantidad']}');
    _precioCompraCtrl =
        TextEditingController(text: '${widget.data['precio_compra']}');
    _precioVentaCtrl =
        TextEditingController(text: '${widget.data['precio_venta']}');
    _alertaCtrl = TextEditingController(text: '${widget.data['alerta_stock']}');
    _imagenBase64 = widget.data['imagen_base64'];
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();

    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.white70),
              title: const Text('Seleccionar desde galería',
                  style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, 'galeria'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.white70),
              title: const Text('Tomar foto con cámara',
                  style: TextStyle(color: Colors.white)),
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
      archivo = await picker.pickImage(
          source: ImageSource.gallery, imageQuality: 70);
    } else if (opcion == 'camara') {
      archivo =
          await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
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

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final ref = FirebaseFirestore.instance
          .collection('inventarios')
          .doc(user.uid)
          .collection('categorias')
          .doc(widget.categoria)
          .collection('productos')
          .doc(widget.productoId);

      await ref.update({
        'nombre': _nombreCtrl.text.trim(),
        'marca': _marcaCtrl.text.trim(),
        'cantidad': int.tryParse(_cantidadCtrl.text) ?? 0,
        'precio_compra': double.tryParse(_precioCompraCtrl.text) ?? 0.0,
        'precio_venta': double.tryParse(_precioVentaCtrl.text) ?? 0.0,
        'alerta_stock': int.tryParse(_alertaCtrl.text) ?? 5,
        'imagen_base64': _imagenBase64,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      print('Error al actualizar producto: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar los cambios')));
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Editar producto',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(children: [
            GestureDetector(
              onTap: _seleccionarImagen,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: _imagenBase64 != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.memory(
                          base64Decode(_imagenBase64!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.camera_alt,
                                color: Colors.white54, size: 50),
                            Text('Cambiar imagen',
                                style: TextStyle(color: Colors.white54)),
                          ],
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            _campoTexto(_nombreCtrl, 'Nombre del producto'),
            _campoTexto(_marcaCtrl, 'Marca'),
            _campoTexto(_cantidadCtrl, 'Cantidad', tipo: TextInputType.number),
            _campoTexto(_precioCompraCtrl, 'Precio de compra',
                tipo: TextInputType.number),
            _campoTexto(_precioVentaCtrl, 'Precio de venta',
                tipo: TextInputType.number),
            _campoTexto(_alertaCtrl, 'Alerta de stock (mínimo)',
                tipo: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _guardando ? null : _guardarCambios,
              child: _guardando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Guardar cambios',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade800,
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  onPressed: _confirmarEliminacion,
  child: const Text(
    "Eliminar producto",
    style: TextStyle(color: Colors.white),
  ),
),
          ]),
        ),
      ),
    );
  }

  Future<void> _confirmarEliminacion() async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.grey[900],
      title: const Text(
        "Confirmar eliminación",
        style: TextStyle(color: Colors.white),
      ),
      content: const Text(
        "Esta acción no se puede deshacer.",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("Cancelar"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text(
            "Eliminar",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    ),
  );

  if (confirmar == true) {
    final user = FirebaseAuth.instance.currentUser!;
    await FirebaseFirestore.instance
        .collection('inventarios')
        .doc(user.uid)
        .collection('categorias')
        .doc(widget.categoria)
        .collection('productos')
        .doc(widget.productoId)
        .delete();

    if (mounted) Navigator.pop(context);
  }
}


  Widget _campoTexto(TextEditingController controller, String label,
      {TextInputType? tipo}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: tipo,
        validator: (v) => v == null || v.isEmpty ? 'Campo obligatorio' : null,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white70),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.white30),
            borderRadius: BorderRadius.circular(12),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.red),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
