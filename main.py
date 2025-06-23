import random
import os
import time

# --- Core Game Components ---

class Card:
    """Represents a single playing card."""
    def __init__(self, rank, suit, base_value):
        self.rank = rank
        self.suit = suit
        self.base_value = base_value
        self.is_enhanced = False # For future Balatro-like features

    def __str__(self):
        return f"{self.rank}{self.suit}"

    def get_value(self):
        # This can be modified by Caddies later
        return self.base_value

class Deck:
    """Represents the deck of cards for a round."""
    def __init__(self):
        self.cards = self._create_deck()
        self.shuffle()

    def _create_deck(self):
        ranks = {
            'A': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7,
            '8': 8, '9': 9, '10': 10, 'J': 10, 'Q': 10, 'K': 0
        }
        suits = ['♥', '♦', '♣', '♠']
        deck = [Card(r, s, v) for r, v in ranks.items() for s in suits]
        deck.extend([Card('Joker', '🃏', -2), Card('Joker', '🃏', -2)])
        return deck

    def shuffle(self):
        random.shuffle(self.cards)

    def deal(self):
        if not self.cards:
            return None # Handle empty deck
        return self.cards.pop()

# --- Balatro-style Caddies (The "Jokers") ---

class Caddie:
    """Base class for special abilities."""
    def __init__(self, name, description, cost):
        self.name = name
        self.description = description
        self.cost = cost

    def apply_scoring_bonus(self, grid):
        """Calculates any end-of-round scoring bonuses."""
        return 0
        
    def on_setup(self, player):
        """Applies any start-of-round effects."""
        pass

    def on_discard_draw(self, player):
        """Applies effect when drawing from discard."""
        pass

class IronDukeCaddie(Caddie):
    def __init__(self):
        super().__init__("Iron Duke", "All Kings are worth -5 points instead of 0.", 50)

    def apply_scoring_bonus(self, grid):
        bonus = 0
        for row in grid:
            for card in row:
                if card and card.rank == 'K':
                    bonus -= 5 # -5 for each King
        return bonus

class CartographerCaddie(Caddie):
    def __init__(self):
        super().__init__("Cartographer", "Reveal 3 cards at the start of a Hole instead of 2.", 60)
        
    def on_setup(self, player):
        print("Cartographer Caddie allows you to reveal one extra card!")
        player.reveal_card_phase(num_to_reveal=1)


class ScavengerCaddie(Caddie):
    def __init__(self):
        super().__init__("Scavenger", "Gain $2 every time you take a card from the discard pile.", 40)
    
    def on_discard_draw(self, player):
        print("Scavenger Caddie grants +$2!")
        player.money += 2


# --- Player and Game Logic ---

class Player:
    """Manages the player's state."""
    def __init__(self):
        self.grid = [[None for _ in range(3)] for _ in range(3)]
        self.revealed = [[False for _ in range(3)] for _ in range(3)]
        self.money = 0
        self.caddies = []

    def has_caddie(self, caddie_name):
        return any(c.name == caddie_name for c in self.caddies)

    def setup_grid(self, deck):
        self.grid = [[deck.deal() for _ in range(3)] for _ in range(3)]
        self.revealed = [[False for _ in range(3)] for _ in range(3)]

    def display_grid(self):
        print("\n--- YOUR GRID ---")
        for r in range(3):
            row_str = ""
            for c in range(3):
                pos = r * 3 + c + 1
                if self.revealed[r][c]:
                    card_str = str(self.grid[r][c])
                    row_str += f"| {pos}: {card_str:<4} "
                else:
                    row_str += f"| {pos}: [ ? ]  "
            print(row_str + "|")
        print("-----------------")

    def reveal_card_phase(self, num_to_reveal):
        for i in range(num_to_reveal):
            self.display_grid()
            while True:
                try:
                    choice = int(input(f"Choose a card to reveal ({i+1}/{num_to_reveal}): "))
                    if 1 <= choice <= 9:
                        r, c = (choice - 1) // 3, (choice - 1) % 3
                        if not self.revealed[r][c]:
                            self.revealed[r][c] = True
                            break
                        else:
                            print("That card is already revealed. Choose another.")
                    else:
                        print("Invalid input. Please enter a number from 1 to 9.")
                except ValueError:
                    print("Invalid input. Please enter a number.")
    
    def all_cards_revealed(self):
        return all(all(row) for row in self.revealed)

    def calculate_score(self):
        # Step 1: Base card values
        score = sum(card.get_value() for row in self.grid for card in row)

        # Step 2: Check for pairs in columns canceling out
        for c in range(3):
            col_cards = [self.grid[r][c] for r in range(3)]
            if col_cards[0].rank == col_cards[1].rank:
                score -= (col_cards[0].get_value() + col_cards[1].get_value())
            if col_cards[0].rank == col_cards[2].rank:
                 score -= (col_cards[0].get_value() + col_cards[2].get_value())
            if col_cards[1].rank == col_cards[2].rank:
                 score -= (col_cards[1].get_value() + col_cards[2].get_value())
        
        # Step 3: Apply Caddie bonuses
        for caddie in self.caddies:
            score += caddie.apply_scoring_bonus(self.grid)
            
        return score

class CosmicGolfGame:
    """The main game engine."""
    def __init__(self):
        self.player = Player()
        self.run_config = [
            {'hole': 1, 'target': 25},
            {'hole': 2, 'target': 20},
            {'hole': 3, 'target': 15, 'boss': True},
            {'hole': 4, 'target': 10},
            {'hole': 5, 'target': 5, 'boss': True},
        ]
        self.current_hole_index = 0
        self.deck = Deck()
        self.discard_pile = []
        self.shop_caddies = [IronDukeCaddie(), CartographerCaddie(), ScavengerCaddie()]

    def _clear_screen(self):
        os.system('cls' if os.name == 'nt' else 'clear')

    def _setup_hole(self):
        self._clear_screen()
        hole_info = self.run_config[self.current_hole_index]
        print(f"--- Hole {hole_info['hole']} ---")
        print(f"TARGET SCORE: {hole_info['target']} or less")
        if hole_info.get('boss'):
            print("!!! BOSS HOLE !!!")
        
        self.deck = Deck()
        self.player.setup_grid(self.deck)
        self.discard_pile = [self.deck.deal()]

        # Caddie setup effects
        for caddie in self.player.caddies:
            caddie.on_setup(self.player)


    def _player_turn(self):
        self.player.display_grid()
        print(f"Top of Discard Pile: {self.discard_pile[-1]}")
        
        action = ""
        while action not in ['1', '2']:
            action = input("Choose action: [1] Draw from Stock [2] Draw from Discard -> ")
        
        if action == '1': # Draw from Stock
            drawn_card = self.deck.deal()
            print(f"You drew: {drawn_card}")
            swap = ""
            while swap.lower() not in ['y', 'n']:
                swap = input("Do you want to swap this card? (y/n) -> ")
            if swap.lower() == 'y':
                self._swap_card(drawn_card)
            else:
                self.discard_pile.append(drawn_card)
                print(f"You discarded the {drawn_card}.")
        
        elif action == '2': # Draw from Discard
            drawn_card = self.discard_pile.pop()
            print(f"You took the {drawn_card} from the discard pile.")
            # Check for Scavenger Caddie effect
            if self.player.has_caddie("Scavenger"):
                for c in self.player.caddies:
                    if c.name == "Scavenger":
                        c.on_discard_draw(self.player)

            self._swap_card(drawn_card)

    def _swap_card(self, new_card):
        while True:
            try:
                pos = int(input("Choose card position to replace (1-9): "))
                if 1 <= pos <= 9:
                    r, c = (pos - 1) // 3, (pos - 1) % 3
                    old_card = self.player.grid[r][c]
                    self.player.grid[r][c] = new_card
                    self.player.revealed[r][c] = True
                    self.discard_pile.append(old_card)
                    print(f"Swapped {new_card} for {old_card}.")
                    break
                else:
                    print("Invalid position.")
            except ValueError:
                print("Invalid input.")

    def _shop_phase(self):
        self._clear_screen()
        print("--- PRO SHOP ---")
        print(f"Your Cash: ${self.player.money}")
        
        available_caddies = [c for c in self.shop_caddies if c.name not in [p.name for p in self.player.caddies]]
        
        if not available_caddies:
            print("No new caddies to buy!")
            input("Press Enter to continue to the next hole...")
            return

        while True:
            print("\nCaddies for Sale:")
            for i, caddie in enumerate(available_caddies):
                print(f"[{i+1}] {caddie.name} (${caddie.cost}): {caddie.description}")
            print("[0] Exit Shop")

            try:
                choice = int(input("Choose an item to buy: "))
                if choice == 0:
                    break
                if 1 <= choice <= len(available_caddies):
                    selected_caddie = available_caddies[choice - 1]
                    if self.player.money >= selected_caddie.cost:
                        self.player.money -= selected_caddie.cost
                        self.player.caddies.append(selected_caddie)
                        print(f"\nSuccessfully purchased {selected_caddie.name}!")
                        time.sleep(2)
                        break
                    else:
                        print("Not enough cash!")
                else:
                    print("Invalid choice.")
            except ValueError:
                print("Invalid input.")


    def run(self):
        self._clear_screen()
        print("Welcome to COSMIC GOLF!")
        print("Your goal is to complete all Holes by getting a score at or below the target.")
        input("Press Enter to start your run...")

        while self.current_hole_index < len(self.run_config):
            hole_info = self.run_config[self.current_hole_index]
            self._setup_hole()

            # Initial Reveal
            num_to_reveal = 3 if self.player.has_caddie("Cartographer") else 2
            self.player.reveal_card_phase(num_to_reveal)

            # Main gameplay loop for the hole
            while not self.player.all_cards_revealed():
                self._clear_screen()
                print(f"--- Hole {hole_info['hole']} | Target: {hole_info['target']} | Cash: ${self.player.money} ---")
                self._player_turn()
                time.sleep(1) # Pause to see result of turn

            # End of round scoring
            self._clear_screen()
            print("All cards revealed! Calculating score...")
            self.player.display_grid()
            final_score = self.player.calculate_score()
            print(f"\nFINAL SCORE: {final_score}")

            if final_score <= hole_info['target']:
                print(f"SUCCESS! You beat the target of {hole_info['target']}.")
                earnings = 10 + (hole_info['target'] - final_score)
                print(f"You earned ${earnings}!")
                self.player.money += earnings
                self.current_hole_index += 1
                
                if self.current_hole_index < len(self.run_config):
                    input("Press Enter to head to the Pro Shop...")
                    self._shop_phase()
                else:
                    print("\nCONGRATULATIONS! You have completed your run!")
                    break
            else:
                print(f"RUN OVER. Your score of {final_score} was higher than the target of {hole_info['target']}.")
                break
        
        print("Thanks for playing Cosmic Golf!")


# --- Start the game ---
if __name__ == "__main__":
    game = CosmicGolfGame()
    game.run()