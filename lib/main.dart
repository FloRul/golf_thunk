// lib/main.dart
import 'package:flutter/material.dart';
import 'package:golf_thunk/game_grid.dart';
import 'package:golf_thunk/game_state_notifier.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GameStateProvider(
      child: MaterialApp(title: 'Game Grid Demo', home: GameGrid()),
    );
  }
}
