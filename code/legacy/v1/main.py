
import pygame
import sys

# --- Constants ---
SCREEN_WIDTH = 800
SCREEN_HEIGHT = 600
GRID_SIZE = 7
TILE_SIZE = 60
GRID_WIDTH = GRID_SIZE * TILE_SIZE
GRID_HEIGHT = GRID_SIZE * TILE_SIZE
GRID_X = (SCREEN_WIDTH - GRID_WIDTH) // 2
GRID_Y = (SCREEN_HEIGHT - GRID_HEIGHT) // 2

# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRID_COLOR = (50, 50, 50)
PLAYER_COLOR = (0, 150, 255)
ENEMY_COLOR = (255, 50, 50)

# --- Game Classes ---

class Unit:
    """Represents a unit on the battlefield."""
    def __init__(self, name, team, x, y, color):
        self.name = name
        self.team = team
        self.x = x
        self.y = y
        self.color = color

    def draw(self, screen):
        """Draws the unit on the grid."""
        rect = pygame.Rect(
            GRID_X + self.x * TILE_SIZE,
            GRID_Y + self.y * TILE_SIZE,
            TILE_SIZE,
            TILE_SIZE
        )
        pygame.draw.rect(screen, self.color, rect)

class Game:
    """Manages the main game loop and state."""
    def __init__(self):
        pygame.init()
        self.screen = pygame.display.set_mode((SCREEN_WIDTH, SCREEN_HEIGHT))
        pygame.display.set_caption("Eternal Spiral - Prototype")
        self.clock = pygame.time.Clock()
        self.font = pygame.font.SysFont(None, 24)
        self.is_running = True
        self.units = []

    def setup(self):
        """Initializes the game state."""
        self.units.append(Unit("Player", "player", 2, 5, PLAYER_COLOR))
        self.units.append(Unit("Goblin", "enemy", 4, 1, ENEMY_COLOR))

    def run(self):
        """The main game loop."""
        self.setup()
        while self.is_running:
            self.handle_events()
            self.update()
            self.draw()
            self.clock.tick(60)
        pygame.quit()
        sys.exit()

    def handle_events(self):
        """Processes player input and other events."""
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                self.is_running = False

    def update(self):
        """Updates the game logic."""
        pass  # Game logic will be added here in future steps.

    def draw_grid(self):
        """Draws the 7x7 combat grid."""
        for row in range(GRID_SIZE):
            for col in range(GRID_SIZE):
                rect = pygame.Rect(
                    GRID_X + col * TILE_SIZE,
                    GRID_Y + row * TILE_SIZE,
                    TILE_SIZE,
                    TILE_SIZE
                )
                pygame.draw.rect(self.screen, GRID_COLOR, rect, 1)

    def draw(self):
        """Renders all game elements to the screen."""
        self.screen.fill(BLACK)
        self.draw_grid()

        # Draw units
        for unit in self.units:
            unit.draw(self.screen)

        pygame.display.flip()

if __name__ == "__main__":
    game = Game()
    game.run()
