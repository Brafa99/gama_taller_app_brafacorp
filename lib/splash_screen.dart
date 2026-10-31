import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:taller_gama/app_theme.dart';
import 'package:taller_gama/login.dart';
import 'package:taller_gama/home.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _mostrarFirma = false;

  @override
  void initState() {
    super.initState();
    _iniciarSecuenciaSplash();
  }

  Future<void> _iniciarSecuenciaSplash() async {
    // 1. Esperar 2 segundos antes de mostrar la firma de la marca de forma sutil
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _mostrarFirma = true;
      });
    }

    // 2. Esperar 2 segundos adicionales (4 segundos en total) antes de validar sesión y navegar
    await Future.delayed(const Duration(seconds: 1.5));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
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
            child: Stack(
              children: [
                // CONTENIDO CENTRAL DEL SPLASH
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: theme.primaryColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: theme.primaryColor.withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 8,
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/gama_icon.jpeg', // 👈 Logotipo oficial
                            width: 140,
                            height: 140,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text(
                        "INICIALIZANDO SISTEMA...",
                        style: TextStyle(
                          color: theme.primaryColor,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      CircularProgressIndicator(color: theme.primaryColor),
                    ],
                  ),
                ),

                // FIRMA COMERCIAL APARICIÓN RETARDADA (BRAFACORP)
                Positioned(
                  bottom: 35,
                  left: 0,
                  right: 0,
                  child: AnimatedOpacity(
                    opacity: _mostrarFirma ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 800),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "DEVELOPED BY BRAFACORP",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            letterSpacing: 2.5,
                            fontWeight: FontWeight.w600,
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
        );
      },
    );
  }
}
