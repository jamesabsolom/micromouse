while not mouse.is_solved():
	walls = mouse.check_for_walls()

	if not walls[0]:
		mouse.turn_left()
		mouse.move_forward()

	elif not walls[1]:
		mouse.move_forward()

	elif not walls[2]:
		mouse.turn_right()
		mouse.move_forward()

	else:
		mouse.turn_around()

