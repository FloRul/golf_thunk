// models.dart
typedef CardState = ({CardModel card, bool isVisible});

// Define the suits and values
const List<String> suits = ['♠', '♥', '♦', '♣'];
const List<String> values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A'];

// Function to get score based on value (same for all suits)
int getCardScore(String value) {
  switch (value) {
    case 'J' || 'Q':
      return 10;
    case 'K':
      return 0;
    case 'A':
      return 1;
    default:
      return int.parse(value);
  }
}

// Generate the complete deck efficiently
Set<CardModel> cardValues = {
  for (final suit in suits)
    for (final value in values) CardModel(value: value, suit: suit, score: getCardScore(value)),
};

class CardModel {
  final String value;
  final String suit;
  final int score;

  const CardModel({required this.value, required this.suit, required this.score});

  @override
  String toString() {
    return '$value$suit';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is CardModel && other.value == value && other.suit == suit;
  }

  @override
  int get hashCode => Object.hash(value, suit);
}

sealed class GameEvent {}

class StartNewGameEvent extends GameEvent {}

class DrawFromStockEvent extends GameEvent {}

class DrawFromDiscardEvent extends GameEvent {}

class DiscardHeldCardEvent extends GameEvent {}

class RevealCardEvent extends GameEvent {
  final ({int row, int col}) position;

  RevealCardEvent(this.position);
}
