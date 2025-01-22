class MazeSolver:
    def __init__(self, maze, mouse):
        self.maze = maze
        self.mouse = mouse

    def is_solved(self):
        return (self.mouse.x, self.mouse.y) == self.maze.end

    def follow_left_hand_rule(self):
        found_walls = self.mouse.check_for_walls()

        if not found_walls[0]:
            self.mouse.turn_left()
            self.mouse.move_forward()
        elif not found_walls[1]:
            self.mouse.move_forward()
        elif not found_walls[2]:
            self.mouse.turn_right()
            self.mouse.move_forward()
        else:
            self.mouse.turn_around()
