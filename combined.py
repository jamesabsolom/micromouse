import pygame
import random
import tkinter as tk
from tkinter import ttk
from tkinter import scrolledtext
from tkinter import filedialog as fd
import time
import pickle
import os
import sys
import math

class MouseSimple:
    def __init__(self, maze, screen, colour=(0, 0, 255), draw_path=False, colour_repeates=False, connect_path=False, move_delay=0.5, use_image=False, image=None):
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
        self.connect_path = connect_path
        self.colour_repeates = colour_repeates
        self.path = [(self.x, self.y)]
        self.move_delay = move_delay
        self.use_image = use_image  # Toggle for using an image
        self.image = image

    def draw(self):
        if self.draw_path:
            self.draw_route()
        
        center_x = self.x * self.cell_size + self.cell_size // 2
        center_y = self.y * self.cell_size + self.cell_size // 2

        if self.use_image and self.image:
            # Define rotation angles based on direction
            rotation_angles = {
                "up": 180,
                "right": 90,
                "down": 0,
                "left": -90
            }
            angle = rotation_angles.get(self.direction, 0)
            rotated_image = pygame.transform.rotate(self.image, angle)
            image_rect = rotated_image.get_rect(center=(center_x, center_y))
            self.screen.blit(rotated_image, image_rect.topleft)

        else:
            # Default arrow indicator
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

    def check_for_walls(self):
        x, y = self.x, self.y
        # 0 = left, 1 = forward, 2 = right
        self.found_walls = [False, False, False]

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
        self.step()

    def turn_right(self):
        print("Turning right")
        self.current_direction = (self.current_direction + 1) % 4
        self.direction = self.directions[self.current_direction]
        self.step()

    def turn_around(self):
        print("Turning around")
        self.current_direction = (self.current_direction + 2) % 4
        self.direction = self.directions[self.current_direction]
        self.step()

    def move_forward(self):
        print("Moving forward")
        direction = self.directions[self.current_direction]
        self.move(direction)
        self.step()

    def reset(self):
        # print("--- Resetting Mouse ---")
        self.x, self.y = self.maze.start
        self.direction = "up"
        self.current_direction = 0
        self.path = [(self.x, self.y)]
        self.found_walls = [False, False, False]

    def step(self, delay=0.5):
        self.screen.fill((0, 0, 0))
        self.maze.draw()
        self.draw()
        pygame.display.flip()
        pygame.time.delay(int(self.move_delay * 1000))  # Converts seconds to milliseconds
        pygame.event.pump()

    def is_solved(self):
        return (self.x, self.y) == self.maze.end

class MouseComplex:
    def __init__(self, maze, screen, colour=(0, 0, 255), move_delay=0.1, speed=2, rotation_speed=5, detection_range_right=30, detection_range_left=30, detection_range_front=30, show_detection=True):
        self.maze = maze
        self.screen = screen
        self.colour = colour
        self.x = 0
        self.y = 0
        self.radius = maze.cell_size // 4
        self.speed = speed  # Movement speed per frame
        self.rotation_speed = rotation_speed  # How fast the mouse turns
        self.angle = 0  # Facing up
        self.path = [(self.x, self.y)]
        self.found_walls = [False, False, False]
        self.show_detection = show_detection
        self.move_delay = move_delay

        if maze.start[0] != 0:
            self.x = maze.start[0] * (maze.cell_size/2)
        else:
            self.x = (maze.cell_size/2)
        
        if maze.start[1] != 0:
            self.y = maze.start[1] * (maze.cell_size/2)
        else:
            self.y = (maze.cell_size/2)

        # Detection ranges
        self.detection_range_right = detection_range_right
        self.detection_range_left = detection_range_left
        self.detection_range_front = detection_range_front

    def move_forward(self):
        """ Move in the direction of the current angle """
        new_x = self.x + math.cos(math.radians(self.angle)) * self.speed
        new_y = self.y - math.sin(math.radians(self.angle)) * self.speed  # Invert Y-axis

        if not self.check_collision(new_x, new_y):
            self.x, self.y = new_x, new_y
            self.path.append((self.x, self.y))
        
        self.step()

    def turn_left(self):
        """ Rotate counterclockwise """
        self.angle = (self.angle + self.rotation_speed) % 360

    def turn_right(self):
        """ Rotate clockwise """
        self.angle = (self.angle - self.rotation_speed) % 360

    def check_collision(self, new_x, new_y):
        """ Check if the next position collides with a maze wall """
        for y, row in enumerate(self.maze.grid):
            for x, walls in enumerate(row):
                cell_x, cell_y = x * self.maze.cell_size, y * self.maze.cell_size
                if "top" in walls and self.line_circle_collision((cell_x, cell_y), (cell_x + self.maze.cell_size, cell_y), (new_x, new_y), self.radius):
                    return True
                if "bottom" in walls and self.line_circle_collision((cell_x, cell_y + self.maze.cell_size), (cell_x + self.maze.cell_size, cell_y + self.maze.cell_size), (new_x, new_y), self.radius):
                    return True
                if "left" in walls and self.line_circle_collision((cell_x, cell_y), (cell_x, cell_y + self.maze.cell_size), (new_x, new_y), self.radius):
                    return True
                if "right" in walls and self.line_circle_collision((cell_x + self.maze.cell_size, cell_y), (cell_x + self.maze.cell_size, cell_y + self.maze.cell_size), (new_x, new_y), self.radius):
                    return True
        return False
    
    def line_circle_collision(self, p1, p2, circle, r):
        """ Check if a line (p1, p2) intersects with a circle (circle, r) """
        x1, y1 = p1
        x2, y2 = p2
        cx, cy = circle

        # Line equation components
        dx = x2 - x1
        dy = y2 - y1
        fx = x1 - cx
        fy = y1 - cy

        a = dx**2 + dy**2
        b = 2 * (fx * dx + fy * dy)
        c = (fx**2 + fy**2) - r**2

        discriminant = b**2 - 4 * a * c
        if discriminant >= 0:
            discriminant = math.sqrt(discriminant)
            t1 = (-b - discriminant) / (2 * a)
            t2 = (-b + discriminant) / (2 * a)
            if 0 <= t1 <= 1 or 0 <= t2 <= 1:
                return True
        return False

    def draw(self):
        """ Draw the mouse with rotation """
        center = (int(self.x), int(self.y))
        pygame.draw.circle(self.screen, self.colour, center, self.radius)

        # Draw direction arrow
        arrow_length = self.radius * 2
        arrow_x = self.x + math.cos(math.radians(self.angle)) * arrow_length
        arrow_y = self.y - math.sin(math.radians(self.angle)) * arrow_length
        pygame.draw.line(self.screen, (255, 255, 255), center, (int(arrow_x), int(arrow_y)), 2)    

        if self.show_detection:
            self.draw_detection_lines()

    def check_for_walls(self):
        x, y = self.x, self.y
        self.found_walls = [False, False, False]  # 0 = left, 1 = forward, 2 = right

        directions = {
            0: -(self.angle + 90),   # Left
            1: -(self.angle),        # Forward
            2: -(self.angle - 90)    # Right
        }

        detection_ranges = {
            0: self.detection_range_left,
            1: self.detection_range_front,
            2: self.detection_range_right
        }

        for i in range(3):  # Check left, forward, and right
            rad = math.radians(directions[i])
            dx = math.cos(rad)
            dy = -math.sin(rad)  # Inverted Y-axis in Pygame

            end_x = x + dx * detection_ranges[i]
            end_y = y + dy * detection_ranges[i]

            for row_idx, row in enumerate(self.maze.grid):
                for col_idx, walls in enumerate(row):
                    cell_x, cell_y = col_idx * self.maze.cell_size, row_idx * self.maze.cell_size

                    if "top" in walls and self.line_intersection((cell_x, cell_y), (cell_x + self.maze.cell_size, cell_y), (x, y), directions[i], detection_ranges[i]):
                        self.found_walls[i] = True
                    if "bottom" in walls and self.line_intersection((cell_x, cell_y + self.maze.cell_size), (cell_x + self.maze.cell_size, cell_y + self.maze.cell_size), (x, y), directions[i], detection_ranges[i]):
                        self.found_walls[i] = True
                    if "left" in walls and self.line_intersection((cell_x, cell_y), (cell_x, cell_y + self.maze.cell_size), (x, y), directions[i], detection_ranges[i]):
                        self.found_walls[i] = True
                    if "right" in walls and self.line_intersection((cell_x + self.maze.cell_size, cell_y), (cell_x + self.maze.cell_size, cell_y + self.maze.cell_size), (x, y), directions[i], detection_ranges[i]):
                        self.found_walls[i] = True

        return self.found_walls

    def line_intersection(self, p1, p2, ray_start, angle, length):
        # Convert angle to radians
        angle_rad = math.radians(angle)
        
        # Compute the end point of the ray
        ray_end = (ray_start[0] + length * math.cos(angle_rad), 
                ray_start[1] + length * math.sin(angle_rad))       
        
        # Unpack coordinates
        x1, y1 = p1
        x2, y2 = p2
        rx1, ry1 = ray_start
        rx2, ry2 = ray_end

        # Compute determinants
        det = (x1 - x2) * (ry1 - ry2) - (y1 - y2) * (rx1 - rx2)

        if det == 0:
            return None  # Parallel lines

        # Find intersection using determinant formula
        t = ((x1 - rx1) * (ry1 - ry2) - (y1 - ry1) * (rx1 - rx2)) / det
        u = ((x1 - rx1) * (y1 - y2) - (y1 - ry1) * (x1 - x2)) / det

        # Check if the intersection is within the line segment and ray length
        if 0 <= t <= 1 and 0 <= u <= 1:
            # Calculate intersection point
            return True

        return False  # No valid intersection

    def draw_detection_lines(self):
        """Draws visual detection lines based on check_for_walls() results."""
        detection_ranges = {
            "front": self.detection_range_front,
            "right": self.detection_range_right,
            "left": self.detection_range_left
        }

        directions = {
            "front": -(self.angle),
            "right": -(self.angle - 90),
            "left": -(self.angle + 90)
        }

        values = {
            "front": self.found_walls[1],
            "right": self.found_walls[2],
            "left": self.found_walls[0]
        }

        for direction, angle in directions.items():
            rad = math.radians(angle)
            dx = math.cos(rad)
            dy = math.sin(rad)

            end_x = self.x + dx * detection_ranges[direction]
            end_y = self.y + dy * detection_ranges[direction]

            color = (255, 0, 0) if values[direction] else (0, 255, 0)  # Red = detected, Green = clear
            pygame.draw.line(self.screen, color, (self.x, self.y), (end_x, end_y), 2)

    def reset(self):
        # print("--- Resetting Mouse ---")
        if maze.start[0] != 0:
            self.x = maze.start[0] * (maze.cell_size/2)
        else:
            self.x = (maze.cell_size/2)
        
        if maze.start[1] != 0:
            self.y = maze.start[1] * (maze.cell_size/2)
        else:
            self.y = (maze.cell_size/2)
        self.angle = 0
        self.path = [(self.x, self.y)]
        self.found_walls = [False, False, False]

    def step(self, delay=0.5):
        self.screen.fill((0, 0, 0))
        self.maze.draw()
        self.draw()
        pygame.display.flip()
        pygame.time.delay(int(self.move_delay * 1000))  # Converts seconds to milliseconds
        pygame.event.pump()

    def is_solved(self):
        endx = self.maze.end[0]*maze.cell_size
        endy = self.maze.end[1]*maze.cell_size
        if (self.x > endx) and (self.x < (endx + maze.cell_size)): 
            if (self.y > endy) and (self.y < (endy + maze.cell_size)):
                return True
            
        return False

class MazeGenerator:
    def __init__(self, width, height, cell_size, screen, seed=None):
        self.width = width
        self.height = height
        self.cell_size = cell_size
        self.grid = None
        self.start = None
        self.end = None
        self.screen = screen
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

    def draw(self):
        for y, row in enumerate(self.grid):
            for x, walls in enumerate(row):
                top_left = (x * self.cell_size, y * self.cell_size)
                bottom_right = (top_left[0] + self.cell_size, top_left[1] + self.cell_size)

                if "top" in walls:
                    pygame.draw.line(self.screen, (255, 255, 255), top_left, (top_left[0] + self.cell_size, top_left[1]))
                if "right" in walls:
                    pygame.draw.line(self.screen, (255, 255, 255), (top_left[0] + self.cell_size, top_left[1]), (top_left[0] + self.cell_size, bottom_right[1]))
                if "bottom" in walls:
                    pygame.draw.line(self.screen, (255, 255, 255), (top_left[0], bottom_right[1]), (bottom_right[0], bottom_right[1]))
                if "left" in walls:
                    pygame.draw.line(self.screen, (255, 255, 255), top_left, (top_left[0], bottom_right[1]))

        sx, sy = self.start
        ex, ey = self.end
        pygame.draw.rect(self.screen, (0, 255, 0), (sx * self.cell_size, sy * self.cell_size, self.cell_size, self.cell_size))
        pygame.draw.rect(self.screen, (255, 0, 0), (ex * self.cell_size, ey * self.cell_size, self.cell_size, self.cell_size))

    def reset(self):
        # print("--- Resetting Maze ---")
        self.generate_maze()

class GUI_Main:
    def __init__(self, root):
        self.root = root
        self.root.title("MicroMouse Learning Tool")

        # Code editor frame
        self.code_editor_frame = tk.Frame(self.root)
        self.code_editor_frame.grid(row=0, column=0, rowspan=10)

        # Code Editor
        self.code_editor = scrolledtext.ScrolledText(self.code_editor_frame, width=70, height=30)
        self.code_editor.config(font=("TkDefaultFont", 11))
        self.code_editor.pack()

        # Run Button
        self.run_button = tk.Button(self.code_editor_frame, text="Run", command=self.run_student_code)
        self.run_button.pack()

        # Console Output
        self.console_output = scrolledtext.ScrolledText(self.code_editor_frame, width=70, height=10)
        self.console_output.config(font=("TkDefaultFont", 11))
        self.console_output.pack()

        # Text Frame
        self.text_frame = tk.Frame(self.root)
        self.text_frame.grid(row=0, column=1, rowspan=9)

        # Text
        self.text1 = tk.Text(self.text_frame, width=65, height=10, background="lightgrey")
        self.text1.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
        self.text1.configure(font=("TkDefaultFont", 11))
        self.text1.insert(tk.END, "Welcome to the MicroMouse Learning Tool\n\n", "bold")
        self.text1.insert(tk.END, "Instructions:\n", "bold")
        self.text1.insert(tk.END, "1. Write your code in the code editor in python\n")
        self.text1.insert(tk.END, "    -> Use the available functions to control the mouse\n")
        self.text1.insert(tk.END, "2. Click the 'Run' button to execute your code\n")
        self.text1.insert(tk.END, "3. The mouse will move according to your code\n")
        self.text1.insert(tk.END, "4. The console output will display any errors\n")
        self.text1.insert(tk.END, "5. The maze and mouse will reset after each run\n")
        self.text1.config(state=tk.DISABLED)
        self.text1.pack()

        self.text2 = tk.Text(self.text_frame, width=65, height=16, background="lightgrey")
        self.text2.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
        self.text2.configure(font=("TkDefaultFont", 11))
        self.text2.insert(tk.END, "Available Functions:\n", "bold")
        self.text2.insert(tk.END, "1. ")
        self.text2.insert(tk.END, "mouse.move_forward():\n", "bold")
        self.text2.insert(tk.END, "    -> Move the mouse forward\n2.")
        self.text2.insert(tk.END, " mouse.turn_left():\n", "bold")
        self.text2.insert(tk.END, "    -> Turn the mouse left\n3. ")
        self.text2.insert(tk.END, "mouse.turn_right():\n", "bold")
        self.text2.insert(tk.END, "    -> Turn the mouse right\n4. ")
        self.text2.insert(tk.END, "mouse.turn_around():\n", "bold")
        self.text2.insert(tk.END, "    -> Turn the mouse around\n5. ")
        self.text2.insert(tk.END, "mouse.check_for_walls():\n", "bold")
        self.text2.insert(tk.END, "    -> Check for walls around the mouse\n")
        self.text2.insert(tk.END, "    -> Returns a list of booleans from the mouse's perspective\n")
        self.text2.insert(tk.END, "    -> [left, forward, right]\n")
        self.text2.insert(tk.END, "    -> True if there is a wall, False if there is no wall\n6. ")
        self.text2.insert(tk.END, "mouse.is_solved():\n", "bold")
        self.text2.insert(tk.END, "    -> Check if the mouse has reached the end of the maze\n7. ")
        self.text2.insert(tk.END, "maze.end:\n", "bold")
        self.text2.insert(tk.END, "    -> Variable that holds the position of the maze end\n8. ")
        self.text2.insert(tk.END, "mouse.x & mouse.y:\n", "bold")
        self.text2.insert(tk.END, "    -> Variables that hold the current position of the mouse\n9. ")
        self.text2.insert(tk.END, "maze.width & maze.height:\n", "bold")
        self.text2.insert(tk.END, "    -> Variables that hold the width and height of the maze\n")
        self.text2.config(state=tk.DISABLED)
        self.text2.pack()

        self.text3 = tk.Text(self.text_frame, width=65, height=10, background="lightgrey")
        self.text3.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
        self.text3.configure(font=("TkDefaultFont", 11))
        self.text3.insert(tk.END, "Hints:\n")
        self.text3.insert(tk.END, "1. Use a while loop to move the mouse until it reaches the end\n")
        self.text3.config(state=tk.DISABLED)
        self.text3.pack()

        self.button_frame = tk.Frame(self.root)
        self.button_frame.grid(row=9, column=1)

        # New Maze Button
        self.new_maze_button = tk.Button(self.button_frame, text="New Maze", command=self.generate_maze)
        self.new_maze_button.grid(row=0, column=0)

        # Save Code Button
        self.save_code_button = tk.Button(self.button_frame, text="Save Code", command=self.save_code)
        self.save_code_button.grid(row=0, column=1)

        # Load Code Button
        self.load_code_button = tk.Button(self.button_frame, text="Load Code", command=self.load_code)
        self.load_code_button.grid(row=0, column=2)

        # Save Maze Button
        self.save_maze_button = tk.Button(self.button_frame, text="Save Maze", command=self.save_maze)
        self.save_maze_button.grid(row=0, column=3)

        # Load Maze Button
        self.load_maze_button = tk.Button(self.button_frame, text="Load Maze", command=self.load_maze)
        self.load_maze_button.grid(row=0, column=4)

        # Settings Button
        self.settings_button = tk.Button(self.button_frame, text="Settings", command=self.settings)
        self.settings_button.grid(row=0, column=5)

        # Exit Button
        self.exit_button = tk.Button(self.button_frame, text="Exit", command=root.destroy)
        self.exit_button.grid(row=0, column=6)

    def save_code(self):
        # Open a popup window to select a file
        file_path = fd.asksaveasfilename(filetypes=[("Python Files", "*.py")])
        if file_path:
            with open(file_path, "w") as file:
                code = self.code_editor.get("1.0", tk.END)
                file.write(code)

    def load_code(self):
        # Open a popup window to select a file
        file_path = fd.askopenfilename(filetypes=[("Python Files", "*.py")])
        if file_path:
            with open(file_path, "r") as file:
                code = file.read()
                self.code_editor.delete("1.0", tk.END)
                self.code_editor.insert(tk.END, code)

    def settings(self):
        settings_root = tk.Toplevel()
        gui_settings = GUI_Settings(settings_root)

    def generate_maze(self):
        maze.reset()
        mouse.step()
        maze.draw()
        mouse.draw()
        pygame.display.flip()
        time.sleep(0.2)

    def save_maze(self):
        file_path = fd.asksaveasfilename(filetypes=[("Maze Files", "*.maze")])
        if file_path:
            with open(file_path, "wb") as file:
                pickle.dump(maze, file)
            print(f"Maze saved to {file_path}")

    def load_maze(self):
        file_path = fd.askopenfilename(filetypes=[("Maze Files", "*.maze")])
        if file_path:
            with open(file_path, "rb") as file:
                global maze
                maze = pickle.load(file)
            mouse.step()
            print(f"Maze loaded from {file_path}")

    def run_student_code(self):
        global mouse, maze, pygame, time
        try:
            root.withdraw()

            mouse.reset()
            maze.draw()
            mouse.draw()
            pygame.display.flip()
            # Reset the console output
            self.console_output.delete("1.0", tk.END)

            # Get the student code from the editor
            student_code = self.code_editor.get("1.0", tk.END)

            # Sandbox for the student code
            local_scope = {"mouse": mouse, "maze": maze, "pygame": pygame, "time": time}
            # print("--- Running Code ---")
            exec(student_code, {}, local_scope)
            root.wm_deiconify()

            if mouse.is_solved():
                self.console_output.insert(tk.END, "Maze Solved!\n")
                self.console_output.insert(tk.END, "The mouse took " + str(len(mouse.path)) + " steps to reach the end\n")

        except Exception as e:
            root.wm_deiconify()
            self.console_output.insert(tk.END, f"Error: {str(e)}\n")
            print(f"Error: {str(e)}")

class GUI_Settings:
    def __init__(self, root):
        self.root = root
        self.root.title("Settings")
        self.root.geometry("300x400")
        self.root.iconphoto(False, photo)

        self.frame = ttk.Frame(self.root)
        self.frame.pack(pady=10, padx=10, fill=tk.BOTH, expand=True)

        self.mouse_settings = tk.Label(self.frame, text="--- Mouse Settings ---", font='Helvetica 18 bold')
        self.mouse_settings.grid(row=0, column=0, columnspan=3)

        self.use_image_setting_var = tk.IntVar(value=int(mouse.use_image))
        self.use_image_checkbox = tk.Checkbutton(self.frame, text='Use Image For Mouse?', variable=self.use_image_setting_var)
        self.use_image_checkbox.grid(row=1, column=0, columnspan=3)

        self.draw_path_setting_var = tk.IntVar(value=int(mouse.draw_path))
        self.draw_path_checkbox = tk.Checkbutton(self.frame, text='Draw Path?', variable=self.draw_path_setting_var)
        self.draw_path_checkbox.grid(row=2, column=0, columnspan=3)

        self.time_delay_text = tk.Label(self.frame, text="Time Delay Between Actions:")
        self.time_delay_text.grid(row=3, column=0)
        self.time_delay_spinbox = tk.Spinbox(self.frame, increment=0.1, from_=0.1, to=10, width=10)
        self.time_delay_spinbox.grid(row=3, column=1)
        self.time_delay_unit = tk.Label(self.frame, text="Seconds")
        self.time_delay_unit.grid(row=3, column=2)

        self.mouse_mode_setting_var = tk.IntVar(value=int(mouse_mode))
        self.mouse_mode_checkbox = tk.Checkbutton(self.frame, text='Enable complex movement?', variable=self.mouse_mode_setting_var)
        self.mouse_mode_checkbox.grid(row=2, column=0, columnspan=3)

        self.confirmframe = ttk.Frame(self.root)
        self.confirmframe.pack()

        self.cancelbutton = tk.Button(self.confirmframe, text="Cancel", command=self.cancel)
        self.cancelbutton.grid(row=0, column=0)

        self.confirmbutton = tk.Button(self.confirmframe, text="Confirm", command=self.confirm)
        self.confirmbutton.grid(row=0, column=1)

    def confirm(self):
        self.set_mouse_mode(bool(self.mouse_mode_setting_var))
        mouse.use_image = bool(self.use_image_setting_var.get())
        mouse.draw_path = bool(self.draw_path_setting_var.get())
        mouse.move_delay = float(self.time_delay_spinbox.get())
        maze.draw()
        mouse.draw()
        pygame.display.flip()
        time.sleep(0.2)
        self.root.destroy()

    def cancel(self):
        self.root.destroy()

    def set_mouse_mode(self, mode):
        global mouse
        if mode == False:
            mouse = MouseSimple(maze, screen, draw_path=True, colour_repeates=True, connect_path=True, use_image=True, image=image)
        else:
            mouse = MouseComplex(maze, screen)
            
        
def resource_path(relative_path):
    """ Get absolute path to resource, works for dev and for PyInstaller """
    try:
        # PyInstaller creates a temp folder and stores path in _MEIPASS
        base_path = sys._MEIPASS
    except Exception:
        base_path = os.path.abspath(".")

    return os.path.join(base_path, relative_path)

pygame.init()

# Maze and Mouse Initialization
width, height = 10, 10
cell_size = 50
screen_width = width * cell_size + 1
screen_height = height * cell_size + 1
# Mouse mode variable 0 = simple 1 = complex
mouse_mode = False

image = pygame.image.load(resource_path("Assets/mouse.png"))
if image:
    image = pygame.transform.scale(image, (cell_size, cell_size))
pygame.display.set_icon(image)
screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Maze Solver")

root = tk.Tk()
gui = GUI_Main(root)

photo = tk.PhotoImage(file=resource_path("Assets/mouse.png"))
root.iconphoto(False, photo)

maze = MazeGenerator(width, height, cell_size, screen)
maze.generate_maze()

mouse = MouseSimple(maze, screen, draw_path=True, colour_repeates=True, connect_path=True, use_image=True, image=image)

maze.draw()
mouse.draw()
pygame.display.flip()
time.sleep(0.2)

root.mainloop()

pygame.quit()
