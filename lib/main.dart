import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:taller_gama/clients_view.dart';
import 'package:taller_gama/firebase_options.dart';
import 'package:taller_gama/home.dart';
import 'package:taller_gama/inventario_view.dart';
import 'package:taller_gama/login.dart';
import 'package:taller_gama/register_client_view.dart';
import 'dart:async';

import 'package:taller_gama/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const GamaApp());
}

class GamaApp extends StatelessWidget {
  const GamaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gama',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.red[700],
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      routes: {
          // '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          //'/home': (context) => HomeScreen(),
          '/clients_view': (context) => const ClientesScreen(),
          '/register_client': (context) => RegistrarClienteScreen(),
          '/inventario': (context) => const InventarioView(),
          // '/home': (context) => HomeScreen(),
        },
      home: const SplashScreen(),
    );
  }
}
