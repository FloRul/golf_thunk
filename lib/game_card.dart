// lib/game_card.dart

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:golf_thunk/models.dart';

class GameCard extends StatefulWidget {
  final CardState cardState;
  final VoidCallback onTap;
  final bool isPlayable; // Add this parameter

  const GameCard({
    super.key,
    required this.cardState,
    required this.onTap,
    this.isPlayable = false, // Default to not playable
  });

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);
    if (widget.cardState.isVisible) {
      _controller.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant GameCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.cardState.isVisible != oldWidget.cardState.isVisible) {
      widget.cardState.isVisible ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.cardState.card;
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final isFront = _controller.value < 0.5;
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi * _controller.value);

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isFront
                ? _buildCardFace(Colors.blue, Container())
                : Transform(
                    transform: Matrix4.identity()..rotateY(pi),
                    alignment: Alignment.center,
                    child: _buildCardFace(
                      Colors.white,
                      Center(
                        child: Text(
                          card.toString(),
                          style: TextStyle(
                            fontSize: 24.0,
                            fontWeight: FontWeight.bold,
                            color: switch (card.suit) {
                              '♦' => Colors.orange,
                              '♣' => Colors.blue,
                              '♥' => Colors.red,
                              '♠' => Colors.black,
                              _ => Colors.black,
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildCardFace(Color color, Widget child) {
    // New: Add a glow effect when the card is playable
    final cardGlow = widget.isPlayable
        ? [BoxShadow(color: Colors.yellow.withOpacity(0.7), blurRadius: 10, spreadRadius: 3)]
        : null;

    return Card(
      elevation: 4.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      color: color,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: widget.cardState.isVisible ? Border.all(color: Colors.blue, width: 2) : null,
          boxShadow: cardGlow, // Apply the glow effect here
        ),
        child: child,
      ),
    );
  }
}
