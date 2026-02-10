import math

class Unit:
    """Represents a single unit on the battlefield."""
    def __init__(self, name, team, x, y, health=100, ap=4):
        self.name = name
        self.team = team
        self.x = x
        self.y = y
        self.health = health
        self.ap = ap
        self.max_ap = 4

    def __repr__(self):
        return f"{self.name} ({self.team}) at ({self.x}, {self.y}) | HP: {self.health} | AP: {self.ap}"

    def is_alive(self):
        """Check if the unit's health is above 0."""
        return self.health > 0

    def reset_ap(self):
        """Reset AP at the start of the turn."""
        self.ap = self.max_ap

class CombatSimulator:
    """Manages the state and logic of the combat simulation."""
    def __init__(self, grid_size=7):
        self.grid_size = grid_size
        self.grid = [['.' for _ in range(grid_size)] for _ in range(grid_size)]
        self.player_units = []
        self.enemy_units = []
        self.all_units = []

    def setup_scenario(self):
        """Initializes the units and places them on the grid."""
        player = Unit("Player", "player", 5, 3, health=100)
        enemy = Unit("Goblin", "enemy", 1, 3, health=50)

        self.player_units.append(player)
        self.enemy_units.append(enemy)
        self.all_units = self.player_units + self.enemy_units

        self.update_grid()
        print("--- Scenario Initialized ---")
        self.print_state()

    def update_grid(self):
        """Updates the grid representation with unit positions."""
        # Clear the grid
        self.grid = [['.' for _ in range(self.grid_size)] for _ in range(self.grid_size)]
        # Place units
        for unit in self.all_units:
            if unit.is_alive():
                # P for Player, E for Enemy
                symbol = 'P' if unit.team == 'player' else 'E'
                self.grid[unit.y][unit.x] = symbol

    def print_state(self):
        """Prints the current state of the grid and all units."""
        self.update_grid()
        print("\n--- Battlefield ---")
        for row in self.grid:
            print(" ".join(row))
        print("\n--- Unit Stats ---")
        for unit in self.all_units:
            print(unit)
        print("-" * 20)

    def get_unit_at_pos(self, x, y):
        """Returns the unit at a given position, or None."""
        for unit in self.all_units:
            if unit.x == x and unit.y == y and unit.is_alive():
                return unit
        return None

    def is_adjacent(self, unit1, unit2):
        """Checks if two units are on adjacent tiles (not diagonally)."""
        return abs(unit1.x - unit2.x) + abs(unit1.y - unit2.y) == 1

    def move_unit(self, unit, dx, dy):
        """Moves a unit by a delta, handling AP cost and grid boundaries."""
        if unit.ap < 1:
            print(f"{unit.name} is out of AP to move.")
            return

        new_x, new_y = unit.x + dx, unit.y + dy

        # Check boundaries
        if not (0 <= new_x < self.grid_size and 0 <= new_y < self.grid_size):
            print("Move is out of bounds.")
            return

        # Check for collision
        if self.get_unit_at_pos(new_x, new_y):
            print("Cannot move into an occupied tile.")
            return

        unit.x = new_x
        unit.y = new_y
        unit.ap -= 1
        print(f"{unit.name} moves to ({unit.x}, {unit.y}).")

    def attack_action(self, source_unit, target_unit):
        """Handles the logic for an attack action."""
        if source_unit.ap < 2:
            print(f"{source_unit.name} does not have enough AP to attack.")
            return

        if not self.is_adjacent(source_unit, target_unit):
            print(f"{target_unit.name} is not in range for a melee attack.")
            return

        damage = 25
        source_unit.ap -= 2
        target_unit.health -= damage

        print(f"{source_unit.name} attacks {target_unit.name} for {damage} damage!")

        if not target_unit.is_alive():
            print(f"{target_unit.name} has been defeated!")
            # In a real game, we would remove the unit from the list of active units.
            # For this simulation, we'll just let their health be <= 0.

    def handle_player_turn(self, turn_actions):
        """Manages the player's turn, taking input from a predefined list of actions."""
        player = self.player_units[0]
        player.reset_ap()
        print(f"\n--- {player.name}'s Turn ---")
        self.print_state()

        for action_data in turn_actions:
            if player.ap <= 0 or not player.is_alive():
                break

            action = action_data.lower().split()
            command = action[0]
            print(f"Player action: {' '.join(action)}")

            if command == 'move' and len(action) > 1:
                direction = action[1]
                moves = {'up': (0, -1), 'down': (0, 1), 'left': (-1, 0), 'right': (1, 0)}
                if direction in moves:
                    dx, dy = moves[direction]
                    self.move_unit(player, dx, dy)
                else:
                    print("Invalid direction. Use up, down, left, or right.")
            elif command == 'attack' and len(action) > 1:
                target_name = action[1].capitalize()
                target = next((u for u in self.enemy_units if u.name == target_name and u.is_alive()), None)
                if target:
                    self.attack_action(player, target)
                else:
                    print(f"Enemy '{target_name}' not found.")
            elif command == 'pass':
                print("Passing remaining turn.")
                break
            else:
                print("Invalid command. Try again.")

            self.print_state()
            if not self.enemy_units[0].is_alive():
                break

    def handle_enemy_turn(self):
        """Manages the enemy's turn based on a simple AI routine."""
        enemy = self.enemy_units[0]
        player = self.player_units[0]
        enemy.reset_ap()
        print(f"\n--- {enemy.name}'s Turn ---")

        while enemy.ap > 0 and enemy.is_alive():
            # AI Logic: Attack if adjacent, otherwise move closer.
            if self.is_adjacent(enemy, player):
                if enemy.ap >= 2:
                    self.attack_action(enemy, player)
                else:
                    # Not enough AP to attack, end turn
                    break
            else:
                # Move towards the player
                dx = player.x - enemy.x
                dy = player.y - enemy.y

                # Move horizontally or vertically, whichever is greater distance
                if abs(dx) > abs(dy):
                    self.move_unit(enemy, int(math.copysign(1, dx)), 0)
                else:
                    self.move_unit(enemy, 0, int(math.copysign(1, dy)))
            
            if not player.is_alive():
                break
        
        self.print_state()

    def run_simulation(self):
        """The main game loop for the combat simulation."""
        self.setup_scenario()
        turn_count = 1
        
        # Pre-defined actions for the simulation
        player_actions_by_turn = {
            1: ["move left", "move left"],
            2: ["attack goblin"],
            3: ["attack goblin"]
        }

        while all(u.is_alive() for u in self.all_units):
            print(f"\n=== Turn {turn_count} ===")
            
            player_turn_actions = player_actions_by_turn.get(turn_count, ["pass"])
            self.handle_player_turn(player_turn_actions)
            
            if not self.enemy_units[0].is_alive():
                print("\nPlayer wins!")
                break

            self.handle_enemy_turn()
            if not self.player_units[0].is_alive():
                print("\nEnemy wins!")
                break
            
            turn_count += 1

if __name__ == "__main__":
    simulator = CombatSimulator()
    simulator.run_simulation()
