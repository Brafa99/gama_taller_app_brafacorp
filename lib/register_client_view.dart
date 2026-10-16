import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:taller_gama/app_theme.dart';
import 'editar_cliente_screen.dart';

class RegistrarClienteScreen extends StatefulWidget {
  const RegistrarClienteScreen({super.key});

  @override
  State<RegistrarClienteScreen> createState() => _RegistrarClienteScreenState();
}

class _RegistrarClienteScreenState extends State<RegistrarClienteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nombreCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _marcaCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();

  String? _fotoBase64;
  File? _fotoFile;
  bool _guardando = false;

  Future<void> _pickImage(AppThemeModel theme) async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.camera_alt, color: theme.primaryColor),
              title: const Text('Tomar foto con cámara', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.camera);
                await _procesarImagen(img);
                if (mounted) Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: theme.primaryColor),
              title: const Text('Elegir de galería', style: TextStyle(color: Colors.white)),
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.gallery);
                await _procesarImagen(img);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _procesarImagen(XFile? img) async {
    if (img == null) return;

    final compressed = await FlutterImageCompress.compressWithFile(
      img.path,
      minWidth: 800,
      minHeight: 800,
      quality: 60,
      format: CompressFormat.jpeg,
    );

    if (compressed == null) return;

    setState(() {
      _fotoFile = File(img.path);
      _fotoBase64 = base64Encode(compressed);
    });
  }

  Future<void> _guardarCliente() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _guardando = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final docRef = await FirebaseFirestore.instance.collection('clientes').add({
        'adminId': uid,
        'nombre': _nombreCtrl.text.trim(),
        'celular': _celularCtrl.text.trim(),
        'marca': _marcaCtrl.text.trim(),
        'placa': _placaCtrl.text.trim(),
        'fotoBase64': _fotoBase64,
        'fechaRegistro': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => EditarClienteScreen(clienteId: docRef.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text("Error al guardar: $e"),
          ),
        );
      }
    }

    if (mounted) setState(() => _guardando = false);
  }

  InputDecoration _inputDecoration(String label, AppThemeModel theme) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: theme.cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: theme.borderColor.withOpacity(0.3)),
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
                          'Registrar Nuevo Cliente',
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
                    child: _guardando
                        ? Center(
                            child: Lottie.asset(
                              "assets/lotties/loading.json",
                              height: 140,
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.all(20),
                            child: Form(
                              key: _formKey,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Lottie.asset(
                                      "assets/lotties/edit_client.json",
                                      height: 130,
                                    ),
                                    const SizedBox(height: 10),

                                    /// 📸 FOTO
                                    GestureDetector(
                                      onTap: () => _pickImage(theme),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(color: theme.primaryColor, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: theme.primaryColor.withOpacity(0.3),
                                              blurRadius: 15,
                                            )
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 50,
                                          backgroundColor: theme.cardColor,
                                          backgroundImage: _fotoFile != null
                                              ? FileImage(_fotoFile!)
                                              : _fotoBase64 != null
                                                  ? MemoryImage(base64Decode(_fotoBase64!))
                                                  : null,
                                          child: _fotoFile == null && _fotoBase64 == null
                                              ? Icon(Icons.camera_alt, size: 36, color: theme.primaryColor)
                                              : null,
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 25),

                                    TextFormField(
                                      controller: _nombreCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Nombre completo", theme),
                                      validator: (v) => v!.isEmpty ? "Ingrese el nombre" : null,
                                    ),
                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _celularCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Número de Celular", theme),
                                      keyboardType: TextInputType.phone,
                                    ),
                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _marcaCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Marca de Moto", theme),
                                      validator: (v) => v!.isEmpty ? "Ingrese la marca" : null,
                                    ),
                                    const SizedBox(height: 14),

                                    TextFormField(
                                      controller: _placaCtrl,
                                      style: const TextStyle(color: Colors.white),
                                      decoration: _inputDecoration("Número de Placa", theme),
                                    ),

                                    const SizedBox(height: 30),

                                    /// 🚀 BOTÓN GUARDAR
                                    Container(
                                      width: double.infinity,
                                      height: 55,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [theme.primaryColor, theme.accentColor],
                                        ),
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
                                          onTap: _guardarCliente,
                                          child: const Center(
                                            child: Text(
                                              "GUARDAR CLIENTE",
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