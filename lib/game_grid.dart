// lib/game_grid.dart

import 'package:flutter/material.dart';
import 'package:golf_thunk/game_card.dart';
import 'package:golf_thunk/game_state_notifier.dart';
import 'package:golf_thunk/models.dart';

class GameGrid extends StatefulWidget {
  const GameGrid({super.key});

  @override
  State<GameGrid> createState() => _GameGridState();
}

class _GameGridState extends State<GameGrid> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final gameState = GameState.of(context);
    if (gameState.isGameOver) {
      // Wait for the current frame to finish before showing the dialog.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // Ensure the widget is still in the tree.
          _showGameOverDialog(gameState.finalScore!);
        }
      });
    }
  }

  void _showGameOverDialog(int score) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Game Over'),
        content: Text('Your final score is: $score'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close the dialog
              GameState.of(context).dispatchEvent(StartNewGameEvent());
            },
            child: const Text('New Game'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gameState = GameState.of(context);
    final gameGrid = gameState.gameGrid;
    final canDraw = gameState.heldCard == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Golf'),
        backgroundColor: Colors.lightGreen,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () => gameState.dispatchEvent(StartNewGameEvent())),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // New: Add a contextual hint for the user
                  if (gameState.heldCard != null)
                    const Text('Tap a grid card to swap', textAlign: TextAlign.center)
                  else
                    const Text('Draw or reveal a card', textAlign: TextAlign.center),
                  Expanded(
                    child: _buildPile(
                      context: context,
                      title: 'Discard',
                      card: gameState.discardPile.isNotEmpty ? gameState.discardPile.last : null,
                      isVisible: true,
                      isPlayable: canDraw && gameState.discardPile.isNotEmpty, // New
                      onTap: () => gameState.dispatchEvent(DrawFromDiscardEvent()),
                    ),
                  ),
                  Expanded(
                    child: _buildPile(
                      context: context,
                      title: 'Held Card',
                      card: gameState.heldCard,
                      isVisible: true,
                      isPlayable: gameState.heldCard != null, // New
                      onTap: () => gameState.dispatchEvent(DiscardHeldCardEvent()),
                    ),
                  ),
                  Expanded(
                    child: _buildPile(
                      context: context,
                      title: 'Stock (${gameState.stock.length})',
                      card: gameState.stock.isNotEmpty ? gameState.stock.last : null,
                      isVisible: false,
                      isPlayable: canDraw && gameState.stock.isNotEmpty, // New
                      onTap: () => gameState.dispatchEvent(DrawFromStockEvent()),
                    ),
                  ),
                ],
              ),
            ),
            // Game grid section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final spacing = 8.0;
                    final aspectRatio = 0.75;

                    // Calculate available space
                    final availableWidth = constraints.maxWidth;
                    final availableHeight = constraints.maxHeight;

                    // Calculate card dimensions based on available space
                    double cardWidth = (availableWidth - (2 * spacing)) / 3;
                    double cardHeight = cardWidth / aspectRatio;

                    // Check if the grid fits vertically
                    double totalGridHeight = (cardHeight * 3) + (spacing * 2);

                    if (totalGridHeight > availableHeight) {
                      // Scale down to fit vertically
                      cardHeight = (availableHeight - (2 * spacing)) / 3;
                      cardWidth = cardHeight * aspectRatio;
                    }

                    return Center(
                      child: SizedBox(
                        width: (cardWidth * 3) + (spacing * 2),
                        height: (cardHeight * 3) + (spacing * 2),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: aspectRatio,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, index) {
                            final row = index ~/ 3;
                            final col = index % 3;
                            final cardState = gameGrid[row][col];
                            // New: Determine if the card is playable
                            final isPlayable = gameState.heldCard != null || !cardState.isVisible;
                            return GameCard(
                              cardState: cardState,
                              isPlayable: isPlayable, // Pass the flag
                              onTap: () => gameState.dispatchEvent(RevealCardEvent((row: row, col: col))),
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPile({
    required BuildContext context,
    required String title,
    required CardModel? card,
    required bool isVisible,
    required VoidCallback onTap,
    bool isPlayable = false, // Add isPlayable parameter
  }) {
    // New: Add a glow effect when the pile is playable
    final pileGlow = isPlayable
        ? [BoxShadow(color: Colors.yellow.withOpacity(0.7), blurRadius: 10, spreadRadius: 3)]
        : null;

    return Column(
      mainAxisSize: MainAxisSize.min, // Prevent overflow
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        Expanded(
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: pileGlow, // Apply the glow effect here
              ),
              child: card != null
                  ? GameCard(cardState: (card: card, isVisible: isVisible), onTap: onTap)
                  : Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Center(child: Icon(Icons.add, color: Colors.grey, size: 24)),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}
