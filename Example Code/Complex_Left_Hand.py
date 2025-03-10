mouse.move_delay = 0.01
while not mouse.is_solved():
	walls = mouse.check_for_walls()
	if walls[1] == True:
		if walls[0] == False:
			for i in range(18):
				mouse.turn_left()

		elif walls[2] == False:
			for i in range(18):
				mouse.turn_right()

		else:
			for i in range(36):
				mouse.turn_right()

	else:
		mouse.move_forward()





