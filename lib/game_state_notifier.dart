import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:golf_thunk/models.dart';

class GameStateProvider extends StatefulWidget {
  final Widget child;

  const GameStateProvider({super.key, required this.child});

  @override
  State<GameStateProvider> createState() => _GameStateProviderState();
}

class _GameStateProviderState extends State<GameStateProvider> {
  late List<List<CardState>> gameGrid;
  late List<CardModel> stock;
  late List<CardModel> discardPile;
  CardModel? heldCard;
  bool isGameOver = false;
  int? finalScore;

  @override
  void initState() {
    super.initState();
    startNewGame();
  }

  void startNewGame() {
    final shuffledCards = List<CardModel>.from(cardValues)..shuffle();
    gameGrid = List.generate(
      3,
      (row) => List.generate(3, (col) {
        final card = shuffledCards.removeAt(0);
        return (card: card, isVisible: false);
      }),
    );

    discardPile = [shuffledCards.removeAt(0)];

    // The rest of the cards are the stock
    stock = shuffledCards;
    isGameOver = false;
    finalScore = null;
    heldCard = null;
    var revealed = 0;
    while (revealed < 2) {
      final row = Random().nextInt(3);
      final col = Random().nextInt(3);
      if (!gameGrid[row][col].isVisible) {
        final currentCard = gameGrid[row][col];
        gameGrid[row][col] = (card: currentCard.card, isVisible: true);
        revealed++;
      }
    }
  }

  void dispatchEvent(GameEvent event) {
    if (isGameOver && event is! StartNewGameEvent) return;

    setState(() {
      switch (event) {
        case StartNewGameEvent():
          startNewGame();
          break;
        case RevealCardEvent():
          final pos = event.position;
          if (heldCard != null) {
            final cardToDiscard = gameGrid[pos.row][pos.col].card;

            final newGrid = List<List<CardState>>.from(gameGrid.map((r) => List<CardState>.from(r)));
            newGrid[pos.row][pos.col] = (card: heldCard!, isVisible: true);
            gameGrid = newGrid;

            discardPile.add(cardToDiscard);
            heldCard = null; // Clear the held card
            checkGameOver();
          } else {
            if (gameGrid[pos.row][pos.col].isVisible) {
              return;
            }
            final newGrid = List<List<CardState>>.from(gameGrid.map((r) => List<CardState>.from(r)));
            final currentCard = newGrid[pos.row][pos.col];
            newGrid[pos.row][pos.col] = (card: currentCard.card, isVisible: true);
            gameGrid = newGrid;
            checkGameOver();
          }
          break;
        case DrawFromStockEvent():
          if (stock.isNotEmpty) {
            final drawnCard = stock.removeLast();
            if (heldCard == null) {
              heldCard = drawnCard;
            } else {
              // If a card is already held, discard it and hold the new one
              discardPile.add(heldCard!);
              heldCard = drawnCard;
            }
          }
          break;
        case DrawFromDiscardEvent():
          if (discardPile.isNotEmpty) {
            final drawnCard = discardPile.removeLast();
            if (heldCard == null) {
              heldCard = drawnCard;
            } else {
              // If a card is already held, discard it and hold the new one
              discardPile.add(heldCard!);
              heldCard = drawnCard;
            }
          }
          break;
        case DiscardHeldCardEvent():
          if (heldCard != null) {
            discardPile.add(heldCard!);
            heldCard = null;
          }
          break;
      }
    });
  }

  void checkGameOver() {
    final allVisible = gameGrid.every((row) => row.every((card) => card.isVisible));
    if (allVisible) {
      isGameOver = true;
      finalScore = calculateScore();
    }
  }

  int calculateScore() {
    int totalScore = 0;
    for (var col = 0; col < 3; col++) {
      final colCards = [gameGrid[0][col].card, gameGrid[1][col].card, gameGrid[2][col].card];
      final firstCardValue = colCards[0].value;
      if (colCards.every((card) => card.value == firstCardValue)) {
        totalScore += 0;
      } else {
        for (final card in colCards) {
          totalScore += card.score;
        }
      }
    }
    return totalScore;
  }

  @override
  Widget build(BuildContext context) {
    return GameState(
      gameGrid: gameGrid,
      stock: stock,
      discardPile: discardPile,
      heldCard: heldCard,
      dispatchEvent: dispatchEvent,
      isGameOver: isGameOver,
      finalScore: finalScore,
      child: widget.child,
    );
  }
}

class GameState extends InheritedWidget {
  final List<List<CardState>> gameGrid;
  final List<CardModel> stock;
  final List<CardModel> discardPile;
  final CardModel? heldCard;
  final bool isGameOver;
  final int? finalScore;
  final void Function(GameEvent) dispatchEvent;

  const GameState({
    super.key,
    required this.gameGrid,
    required this.stock,
    required this.discardPile,
    required this.heldCard,
    required this.isGameOver,
    required this.finalScore,
    required this.dispatchEvent,
    required super.child,
  });

  @override
  bool updateShouldNotify(covariant GameState oldWidget) {
    // Rebuild widgets that depend on this state if any of these have changed.
    return gameGrid != oldWidget.gameGrid ||
        stock != oldWidget.stock ||
        discardPile != oldWidget.discardPile ||
        heldCard != oldWidget.heldCard ||
        isGameOver != oldWidget.isGameOver ||
        finalScore != oldWidget.finalScore;
  }

  static GameState of(BuildContext context) {
    final GameState? result = context.dependOnInheritedWidgetOfExactType<GameState>();
    assert(result != null, 'No GameState found in context');
    return result!;
  }
}
