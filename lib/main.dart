import 'package:flutter/material.dart';
import 'pages/expenses_list_page.dart';
import 'dart:io';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<void> main() async {
  if (Platform.isWindows) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gider Takip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WelcomeScreen(),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600;
    final padding = isWide ? size.width * 0.2 : size.width * 0.08;
    final fontSize = isWide ? 38.0 : 30.0;
    final buttonWidth = isWide ? 320.0 : size.width * 0.7;
    final buttonHeight = isWide ? 60.0 : 48.0;

    return SafeArea(
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: padding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sayın Halil Bütün \n günlük gider uygulamanıza hoşgeldiniz...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: isWide ? 60 : 40),
                SizedBox(
                  width: buttonWidth,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => const ExpensesListPage(),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: TextStyle(fontSize: isWide ? 22 : 18),
                    ),
                    child: const Text('Giriş'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
