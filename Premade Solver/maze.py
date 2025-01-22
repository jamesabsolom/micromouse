import random
import pygame


class MazeGenerator:
    def __init__(self, width, height, cell_size, seed=None):
        self.width = width
        self.height = height
        self.cell_size = cell_size
        self.grid = None
        self.start = None
        self.end = None
        if seed is not None:
            random.seed(seed)

    def generate_maze(self):
        self.grid = [[{"top", "right", "bottom", "left"} for _ in range(self.width)] for _ in range(self.height)]
        self.start = (0, 0)
        self.end = (self.width - 1, self.height - 1)

        visited = set()
        directions = [(0, -1, "top"), (1, 0, "right"), (0, 1, "bottom"), (-1, 0, "left")]
        self._carve_passage(0, 0, visited, directions)

    def _carve_passage(self, x, y, visited, directions):
        visited.add((x, y))
        random.shuffle(directions)

        for dx, dy, direction in directions:
            nx, ny = x + dx, y + dy

            if 0 <= nx < self.width and 0 <= ny < self.height and (nx, ny) not in visited:
                if direction == "top":
                    self.grid[y][x].remove("top")
                    self.grid[ny][nx].remove("bottom")
                elif direction == "right":
                    self.grid[y][x].remove("right")
                    self.grid[ny][nx].remove("left")
                elif direction == "bottom":
                    self.grid[y][x].remove("bottom")
                    self.grid[ny][nx].remove("top")
                elif direction == "left":
                    self.grid[y][x].remove("left")
                    self.grid[ny][nx].remove("right")

                self._carve_passage(nx, ny, visited, directions)

    def reset(self, new_maze=False):
        if new_maze is True:
            self.generate_maze()

        self.grid = None
        self.start = None
        self.end = None

    def draw(self, screen):
        for y, row in enumerate(self.grid):
            for x, walls in enumerate(row):
                top_left = (x * self.cell_size, y * self.cell_size)
                bottom_right = (top_left[0] + self.cell_size, top_left[1] + self.cell_size)

                if "top" in walls:
                    pygame.draw.line(screen, (255, 255, 255), top_left, (top_left[0] + self.cell_size, top_left[1]))
                if "right" in walls:
                    pygame.draw.line(screen, (255, 255, 255), (top_left[0] + self.cell_size, top_left[1]), (top_left[0] + self.cell_size, bottom_right[1]))
                if "bottom" in walls:
                    pygame.draw.line(screen, (255, 255, 255), (top_left[0], bottom_right[1]), (bottom_right[0], bottom_right[1]))
                if "left" in walls:
                    pygame.draw.line(screen, (255, 255, 255), top_left, (top_left[0], bottom_right[1]))

        sx, sy = self.start
        ex, ey = self.end
        pygame.draw.rect(screen, (0, 255, 0), (sx * self.cell_size, sy * self.cell_size, self.cell_size, self.cell_size))
        pygame.draw.rect(screen, (255, 0, 0), (ex * self.cell_size, ey * self.cell_size, self.cell_size, self.cell_size))
