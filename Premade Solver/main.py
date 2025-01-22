from maze import MazeGenerator
from mouse import Mouse
from mazeSolver import MazeSolver
import pygame


if __name__ == "__main__":
    pygame.init()

    width, height = 10, 10
    cell_size = 50
    screen_width = width * cell_size + 1
    screen_height = height * cell_size + 1

    screen = pygame.display.set_mode((screen_width, screen_height))
    pygame.display.set_caption("Maze Solver")

    maze = MazeGenerator(width, height, cell_size)
    maze.generate_maze()

    mouse = Mouse(maze, screen, draw_path=True, colour_repeates=True, connect_path=True)
    mouse.direction = "up"
    solver = MazeSolver(maze, mouse)

    clock = pygame.time.Clock()
    running = True

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False

        if not solver.is_solved():
            solver.follow_left_hand_rule()

        screen.fill((0, 0, 0))
        maze.draw(screen)
        mouse.draw()
        pygame.display.flip()

        clock.tick(10)

    pygame.quit()
