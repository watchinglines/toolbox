// lib/app/app.dart - 根 Widget + 主题 + 路由
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../design_system/theme.dart';
import '../features/scanner/presentation/bloc/scanner_bloc.dart';
import '../features/scanner/presentation/pages/home_page.dart';
import '../features/scanner/presentation/pages/scanner_page.dart';
import '../features/scanner/presentation/pages/result_page.dart';

class ToolBoxApp extends StatelessWidget {
  const ToolBoxApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ScannerBloc>(
          create: (_) => ScannerBloc()..add(const ScannerInitialized()),
        ),
      ],
      child: MaterialApp(
        title: 'ToolBox',
        debugShowCheckedModeBanner: false,
        theme: ToolBoxTheme.light(),
        darkTheme: ToolBoxTheme.dark(),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (_) => const HomePage(),
          '/scanner': (_) => const ScannerPage(),
          '/result': (_) => const ResultPage(),
        },
      ),
    );
  }
}
