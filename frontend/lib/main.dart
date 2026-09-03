import 'package:flutter/material.dart';

import 'pages/dashboard_page.dart';

void main() {
  runApp(const SmartClaimApp());
}

class SmartClaimApp extends StatelessWidget {
  const SmartClaimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SmartClaim',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
        ),
        fontFamily: 'Arial',
      ),
      home: const DashboardPage(),
    );
  }
}