from random import choice

mouse.move_delay = 0.01

while not mouse.is_solved():
	front = mouse.read_sensor("Front Prox")
	left = mouse.read_sensor("Left Prox")
	right = mouse.read_sensor("Right Prox")

	if front:
		if not left and right:
			mouse.turn_left(-90)
			mouse.step()
		elif not right and left:
			mouse.turn_right(-90)
			mouse.step()
		elif not left or not right:
			randbool = choice([True, False])
			if randbool == True:
				mouse.turn_left(-90)
			else:
				mouse.turn_right(-90)
			
		else:
			mouse.turn_right(180)
			mouse.step()

	else:
		if not left and right:
			mouse.turn_left(-90)
			mouse.step()
		elif not right and left:
			mouse.turn_right(-90)
			mouse.step()
		else:
			mouse.move_forward()






