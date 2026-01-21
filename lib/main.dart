import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 分割したファイルをインポート
import 'providers/group_provider.dart';
import 'providers/lobby_view_model.dart';
import 'screens/lobby_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GroupProvider()),
        ChangeNotifierProvider(create: (_) => LobbyViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Matching Room App',
      theme: ThemeData(primarySwatch: Colors.blue),
      // 最初の画面を LobbyScreen に指定
      home: const LobbyScreen(),
    );
  }
}
