import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../modules/auth/screens/login_screen.dart';

class GestoApp extends StatelessWidget {
  const GestoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesto',
      debugShowCheckedModeBanner: false,
      theme: GestoTheme.lightTheme,
      darkTheme: GestoTheme.darkTheme,
      themeMode: ThemeMode.system, // Auto switch based on time
      builder: (context, child) => ResponsiveBreakpoints.builder(
        child: child!,
        breakpoints: [
          const Breakpoint(start: 0, end: 450, name: MOBILE),
          const Breakpoint(start: 451, end: 800, name: TABLET),
          const Breakpoint(start: 801, end: 1920, name: DESKTOP),
          const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
        ],
      ),
      initialRoute: AppRoutes.login,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      home: const LoginScreen(),
    );
  }
}