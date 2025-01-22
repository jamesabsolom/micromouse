import pygame
import random
import tkinter as tk
from tkinter import scrolledtext
from tkinter import filedialog as fd
import time
import pickle


class Mouse:
    def __init__(self, maze, screen, colour=(0, 0, 255), draw_path=False, colour_repeates=False, connect_path=False, move_delay=0.5):
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
        self.move_delay = move_delay
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

        # print(f"Current position: ({x}, {y})")
        # print(f"Current direction: {self.directions[self.current_direction]}")
        # print(f"Left wall: {movement_checker[0]}")
        # print(f"Forward wall: {movement_checker[1]}")
        # print(f"Right wall: {movement_checker[2]}")
        # print(f"Grid status: {self.maze.grid[y][x]}")

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
        self.found_walls = [False, False, False, False]

    def step(self, delay=0.5):
        self.screen.fill((0, 0, 0))
        self.maze.draw()
        self.draw()
        pygame.display.flip()
        time.sleep(0.5)  # Adjust the delay as needed

    def is_solved(self):
        return (self.x, self.y) == self.maze.end

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

def load_code():
    # Open a popup window to select a file
    file_path = fd.askopenfilename(filetypes=[("Python Files", "*.py")])
    if file_path:
        with open(file_path, "r") as file:
            code = file.read()
            code_editor.delete("1.0", tk.END)
            code_editor.insert(tk.END, code)

def save_code():
    # Open a popup window to select a file
    file_path = fd.asksaveasfilename(filetypes=[("Python Files", "*.py")])
    if file_path:
        with open(file_path, "w") as file:
            code = code_editor.get("1.0", tk.END)
            file.write(code)

def settings():
    pass

def generate_maze():
    maze.reset()
    mouse.step()

def save_maze():
    file_path = fd.asksaveasfilename(filetypes=[("Maze Files", "*.maze")])
    if file_path:
        with open(file_path, "wb") as file:
            pickle.dump(maze, file)
        print(f"Maze saved to {file_path}")

def load_maze():
    file_path = fd.askopenfilename(filetypes=[("Maze Files", "*.maze")])
    if file_path:
        with open(file_path, "rb") as file:
            global maze
            maze = pickle.load(file)
        mouse.step()
        print(f"Maze loaded from {file_path}")

def run_student_code():
    global mouse, maze, pygame, time
    try:
        root.withdraw()

        mouse.reset()
        maze.draw()
        mouse.draw()
        pygame.display.flip()
        # Reset the console output
        console_output.delete("1.0", tk.END)

        # Get the student code from the editor
        student_code = code_editor.get("1.0", tk.END)

        # Sandbox for the student code
        local_scope = {"mouse": mouse, "maze": maze, "pygame": pygame, "time": time}
        # print("--- Running Code ---")
        exec(student_code, {}, local_scope)
        root.wm_deiconify()

        if mouse.is_solved():
            console_output.insert(tk.END, "Maze Solved!\n")
            console_output.insert(tk.END, "The mouse took " + str(len(mouse.path)) + " steps to reach the end\n")

    except Exception as e:
        root.wm_deiconify()
        console_output.insert(tk.END, f"Error: {str(e)}\n")
        print(f"Error: {str(e)}")

pygame.init()

# Maze and Mouse Initialization
width, height = 10, 10
cell_size = 50
screen_width = width * cell_size + 1
screen_height = height * cell_size + 1

screen = pygame.display.set_mode((screen_width, screen_height))
pygame.display.set_caption("Maze Solver")

maze = MazeGenerator(width, height, cell_size, screen)
maze.generate_maze()

mouse = Mouse(maze, screen, draw_path=True, colour_repeates=True, connect_path=True)

maze.draw()
mouse.draw()
pygame.display.flip()
time.sleep(0.2)

# Initialize GUI
root = tk.Tk()
root.title("MicroMouse Learning Tool")

# Code editor frame
code_editor_frame = tk.Frame(root)
code_editor_frame.grid(row=0, column=0, rowspan=10)

# Code Editor
code_editor = scrolledtext.ScrolledText(code_editor_frame, width=70, height=30)
code_editor.config(font=("TkDefaultFont", 11))
code_editor.pack()

# Run Button
run_button = tk.Button(code_editor_frame, text="Run", command=run_student_code)
run_button.pack()

# Console Output
console_output = scrolledtext.ScrolledText(code_editor_frame, width=70, height=10)
console_output.config(font=("TkDefaultFont", 11))
console_output.pack()

# Text Frame
text_frame = tk.Frame(root)
text_frame.grid(row=0, column=1, rowspan=9)

# Text
text1 = tk.Text(text_frame, width=65, height=10, background="lightgrey")
text1.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
text1.configure(font=("TkDefaultFont", 11))
text1.insert(tk.END, "Welcome to the MicroMouse Learning Tool\n\n", "bold")
text1.insert(tk.END, "Instructions:\n", "bold")
text1.insert(tk.END, "1. Write your code in the code editor in python\n")
text1.insert(tk.END, "    -> Use the available functions to control the mouse\n")
text1.insert(tk.END, "2. Click the 'Run' button to execute your code\n")
text1.insert(tk.END, "3. The mouse will move according to your code\n")
text1.insert(tk.END, "4. The console output will display any errors\n")
text1.insert(tk.END, "5. The maze and mouse will reset after each run\n")
text1.config(state=tk.DISABLED)
text1.pack()

text2 = tk.Text(text_frame, width=65, height=16, background="lightgrey")
text2.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
text2.configure(font=("TkDefaultFont", 11))
text2.insert(tk.END, "Available Functions:\n", "bold")
text2.insert(tk.END, "1. ")
text2.insert(tk.END, "mouse.move_forward():\n", "bold")
text2.insert(tk.END, "    -> Move the mouse forward\n2.")
text2.insert(tk.END, " mouse.turn_left():\n", "bold")
text2.insert(tk.END, "    -> Turn the mouse left\n3. ")
text2.insert(tk.END, "mouse.turn_right():\n", "bold")
text2.insert(tk.END, "    -> Turn the mouse right\n4. ")
text2.insert(tk.END, "mouse.turn_around():\n", "bold")
text2.insert(tk.END, "    -> Turn the mouse around\n5. ")
text2.insert(tk.END, "mouse.check_for_walls():\n", "bold")
text2.insert(tk.END, "    -> Check for walls around the mouse\n")
text2.insert(tk.END, "    -> Returns a list of booleans from the mouse's perspective\n")
text2.insert(tk.END, "    -> [left, forward, right]\n")
text2.insert(tk.END, "    -> True if there is a wall, False if there is no wall\n6. ")
text2.insert(tk.END, "mouse.is_solved():\n", "bold")
text2.insert(tk.END, "    -> Check if the mouse has reached the end of the maze\n7. ")
text2.insert(tk.END, "maze.end:\n", "bold")
text2.insert(tk.END, "    -> Variable that holds the position of the maze end\n8. ")
text2.insert(tk.END, "mouse.x & mouse.y:\n", "bold")
text2.insert(tk.END, "    -> Variables that hold the current position of the mouse\n9. ")
text2.insert(tk.END, "maze.width & maze.height:\n", "bold")
text2.insert(tk.END, "    -> Variables that hold the width and height of the maze\n")
text2.config(state=tk.DISABLED)
text2.pack()

text3 = tk.Text(text_frame, width=65, height=10, background="lightgrey")
text3.tag_configure("bold", font=("TkDefaultFont", 11, "bold"))
text3.configure(font=("TkDefaultFont", 11))
text3.insert(tk.END, "Hints:\n")
text3.insert(tk.END, "1. Use a while loop to move the mouse until it reaches the end\n")
text3.config(state=tk.DISABLED)
text3.pack()

button_frame = tk.Frame(root)
button_frame.grid(row=9, column=1)

# New Maze Button
new_maze_button = tk.Button(button_frame, text="New Maze", command=generate_maze)
new_maze_button.grid(row=0, column=0)

# Save Code Button
save_code_button = tk.Button(button_frame, text="Save Code", command=save_code)
save_code_button.grid(row=0, column=1)

# Load Code Button
load_code_button = tk.Button(button_frame, text="Load Code", command=load_code)
load_code_button.grid(row=0, column=2)

# Save Maze Button
save_maze_button = tk.Button(button_frame, text="Save Maze", command=save_maze)
save_maze_button.grid(row=0, column=3)

# Load Maze Button
load_maze_button = tk.Button(button_frame, text="Load Maze", command=load_maze)
load_maze_button.grid(row=0, column=4)

# Settings Button
settings_button = tk.Button(button_frame, text="Settings", command=settings)
settings_button.grid(row=0, column=5)

# Exit Button
exit_button = tk.Button(button_frame, text="Exit", command=root.destroy)
exit_button.grid(row=0, column=6)

root.mainloop()

pygame.quit()
