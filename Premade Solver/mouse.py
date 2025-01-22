import pygame


class Mouse:
    def __init__(self, maze, screen, colour=(0, 0, 255), draw_path=False, colour_repeates=False, connect_path=False):
        self.maze = maze
        self.colour = colour
        self.x, self.y = maze.start
        self.radius = maze.cell_size // 4
        self.cell_size = maze.cell_size
        self.direction = "up"
        self.current_direction = 0
        self.directions = ["up", "right", "down", "left"]
        self.found_walls = [False, False, False, False]
        self.screen = screen
        self.draw_path = draw_path
        self.path = [(self.x, self.y)]
        if draw_path:
            self.colour_repeates = colour_repeates
            self.connect_path = connect_path
        else:
            self.colour_repeates = False
            self.connect_path = False

    def draw(self):
        if self.draw_path:
            self.draw_route()
        center_x = self.x * self.cell_size + self.cell_size // 2
        center_y = self.y * self.cell_size + self.cell_size // 2
        pygame.draw.circle(self.screen, self.colour, (center_x, center_y), self.radius)

        if self.direction == "up":
            arrow_points = [(center_x, center_y - self.radius),
                            (center_x - self.radius // 2, center_y + self.radius // 2),
                            (center_x + self.radius // 2, center_y + self.radius // 2)]
        elif self.direction == "down":
            arrow_points = [(center_x, center_y + self.radius),
                            (center_x - self.radius // 2, center_y - self.radius // 2),
                            (center_x + self.radius // 2, center_y - self.radius // 2)]
        elif self.direction == "left":
            arrow_points = [(center_x - self.radius, center_y),
                            (center_x + self.radius // 2, center_y - self.radius // 2),
                            (center_x + self.radius // 2, center_y + self.radius // 2)]
        elif self.direction == "right":
            arrow_points = [(center_x + self.radius, center_y),
                            (center_x - self.radius // 2, center_y - self.radius // 2),
                            (center_x - self.radius // 2, center_y + self.radius // 2)]

        pygame.draw.polygon(self.screen, (255, 255, 255), arrow_points)

    def draw_route(self):
        if self.connect_path:
            for i in range(len(self.path) - 1):
                x1, y1 = self.path[i]
                x2, y2 = self.path[i + 1]
                start = (x1 * self.cell_size + self.cell_size // 2, y1 * self.cell_size + self.cell_size // 2)
                end = (x2 * self.cell_size + self.cell_size // 2, y2 * self.cell_size + self.cell_size // 2)
                pygame.draw.line(self.screen, (255, 255, 0), start, end, 2)

        for x, y in self.path:
            center_x = x * self.cell_size + self.cell_size // 2
            center_y = y * self.cell_size + self.cell_size // 2
            # change the colour depending on how often a spot is visited yellow -> orange -> red
            if self.colour_repeates:
                if self.path.count((x, y)) == 1:
                    pygame.draw.circle(self.screen, (255, 255, 0), (center_x, center_y), self.radius/2)
                elif self.path.count((x, y)) == 2:
                    pygame.draw.circle(self.screen, (255, 125, 0), (center_x, center_y), self.radius/2)
                else:
                    pygame.draw.circle(self.screen, (255, 0, 0), (center_x, center_y), self.radius/2)

            else:
                pygame.draw.circle(self.screen, (255, 0, 0), (center_x, center_y), self.radius/2)

    def move(self, direction):
        if direction == "up" and "top" not in self.maze.grid[self.y][self.x]:
            self.y -= 1
        elif direction == "down" and "bottom" not in self.maze.grid[self.y][self.x]:
            self.y += 1
        elif direction == "left" and "left" not in self.maze.grid[self.y][self.x]:
            self.x -= 1
        elif direction == "right" and "right" not in self.maze.grid[self.y][self.x]:
            self.x += 1

        self.path.append((self.x, self.y))
                      
    def set_direction(self, direction):
        self.direction = direction

    def check_for_walls(self):
        x, y = self.x, self.y
        # 0 = left, 1 = forward, 2 = right
        self.found_walls = [False, False, False, False]

        left_direction = (self.current_direction - 1) % 4
        forward_direction = self.current_direction
        right_direction = (self.current_direction + 1) % 4

        left_wall = self.directions[left_direction]
        forward_wall = self.directions[forward_direction]
        right_wall = self.directions[right_direction]

        movement_checker = [left_wall, forward_wall, right_wall]

        #
        for i in range(len(movement_checker)):
            if movement_checker[i] == "up":
                movement_checker[i] = "top"
            elif movement_checker[i] == "down":
                movement_checker[i] = "bottom"
            elif movement_checker[i] == "left":
                movement_checker[i] = "left"
            elif movement_checker[i] == "right":
                movement_checker[i] = "right"

        print(f"Current position: ({x}, {y})")
        print(f"Current direction: {self.directions[self.current_direction]}")
        print(f"Left wall: {movement_checker[0]}")
        print(f"Forward wall: {movement_checker[1]}")
        print(f"Right wall: {movement_checker[2]}")
        print(f"Grid status: {self.maze.grid[y][x]}")

        if movement_checker[0] in self.maze.grid[y][x]:
            self.found_walls[0] = True
        if movement_checker[1] in self.maze.grid[y][x]:
            self.found_walls[1] = True
        if movement_checker[2] in self.maze.grid[y][x]:
            self.found_walls[2] = True

        return self.found_walls

    def turn_left(self):
        print("Turning left")
        self.current_direction = (self.current_direction - 1) % 4
        self.direction = self.directions[self.current_direction]

    def turn_right(self):
        print("Turning right")
        self.current_direction = (self.current_direction + 1) % 4
        self.direction = self.directions[self.current_direction]

    def turn_around(self):
        print("Turning around")
        self.current_direction = (self.current_direction + 2) % 4
        self.direction = self.directions[self.current_direction]

    def move_forward(self):
        print("Moving forward")
        direction = self.directions[self.current_direction]
        self.move(direction)
        
    def reset(self):
        self.x, self.y = self.maze.start
        self.direction = "up"
        self.current_direction = 0
        self.path = [(self.x, self.y)]
        self.found_walls = [False, False, False, False]
