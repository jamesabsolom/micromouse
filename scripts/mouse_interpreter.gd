# mouse_interpreter.gd
extends Node

class_name MouseInterpreter

signal line_changed(line_number: int)
signal finished
var command_queue: Array = []
var running := false
var mouse: Node = null
var max_iterations := 10000
var stop_flag := false
var _run_id: int = 0

func stop():
	reset()
	emit_signal("line_changed", -1)
	emit_signal("finished")
	
func reset():
	# cancel any pending run immediately
	_run_id += 1
	running = false
	stop_flag = false
	command_queue.clear()
	emit_signal("finished")  # so UI toggles back

func run_script(script_text: String, mouse_ref: Node):#
	mouse = mouse_ref
	command_queue = parse_script(script_text)
	if command_queue.is_empty():
		push_error("No commands to run.")
		return
	var my_token := _run_id
	running = true
	stop_flag = false
	await _run_command_list(command_queue, my_token)

func _run_command_list(commands: Array, token: int) -> void:
	for cmd in commands:
		if token != _run_id or stop_flag:
			return
		emit_signal("line_changed", cmd.get("line", -1))
		if stop_flag:
			push_warning("Execution stopped manually.")
			return

		if Globals.interpreter_debug_enabled:
			print_debug("Running command:", cmd)

		match cmd["action"]:
			"move":
				if token == _run_id:
					mouse.move_forward()
			"left":
				if token == _run_id:
					mouse.turn_left()
			"right":
				if token == _run_id:
					mouse.turn_right()
			"loop":
				var count := 0
				while token == _run_id and running and not stop_flag:
					if count > max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					await _run_command_list(cmd["body"], token)
					count += 1

			"while":
				# wcount must be typed so GDScript infers it correctly
				var wcount: int = 0
				# explicitly type your command‐fields
				var sensor_name: String = cmd["condition"]
				var negate: bool = cmd.get("negate", false)
				# loop only while the (possibly‐negated) sensor stays true
				while token == _run_id and running and not stop_flag and (mouse.read_sensor(sensor_name) != negate):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					await _run_command_list(cmd["body"], token)
					wcount += 1
				# jump straight back to the outer LOOP when the sensor flips
				return

			"repeat":
				for i in range(cmd["count"]):
					if stop_flag or token != _run_id:
						print("TOKEN INVALIDATED")
						return
					await _run_command_list(cmd["body"], token)

			"if":
				var sensor_name: String = cmd["condition"]
				var raw_val: bool = mouse.read_sensor(sensor_name)
				var neg: bool = cmd.get("negate", false)
				# Godot inline‐if instead of C‐style ternary:
				var result: bool = raw_val if not neg else not raw_val
				if result:
					await _run_command_list(cmd["body"], token)
				else:
					await _run_command_list(cmd["else_body"], token)
			
			"if_facing", "if_on":
				var target = cmd["target"]
				var neg = cmd["negate"]
				var match_result = _compare_position(cmd["action"], target)
				var result = not match_result if neg else match_result
				if result:
					await _run_command_list(cmd["body"], token)
				else:
					await _run_command_list(cmd["else_body"], token)

			"while_facing", "while_on":
				var wcount := 0
				var target = cmd["target"]
				var neg = cmd["negate"]
				while token == _run_id and running and not stop_flag and (_compare_position(cmd["action"], target) != neg):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						await _run_command_list([inner_cmd], token)  # Run one-by-one
					wcount += 1

		if token != _run_id or stop_flag:
			return

		var delay: float
		match cmd["action"]:
			"left", "right":
				delay = Globals.turn_delay
			"repeat", "loop":
				delay = Globals.repeat_delay
			_:
				delay = Globals.move_delay
		if delay != 0:
			await get_tree().create_timer(delay).timeout

	if not stop_flag:
		emit_signal("finished")

func _compare_position(mode: String, target_str: String) -> bool:
	var target_pos: Vector2i
	if target_str.begins_with("{") and target_str.ends_with("}"):
		var raw = target_str.substr(1, target_str.length() - 2).strip_edges()
		var parts = raw.split(",", false)
		if parts.size() != 2:
			push_error("Invalid coordinate format: " + target_str)
			return false
		target_pos = Vector2i(parts[0].to_int(), parts[1].to_int())
	else:
		# In future: support variables
		push_error("Variables not supported yet: " + target_str)
		return false

	match mode:
		"if_facing", "while_facing":
			return mouse.is_facing_cell(target_pos)
		"if_on", "while_on":
			return mouse.get_current_cell() == target_pos
		_:
			push_error("Unknown position mode: " + mode)
			return false

func _debug_print_commands(commands: Array, level: int = 0) -> void:
	for cmd in commands:
		# use String.repeat(), not "*" operator
		var prefix: String      = "    ".repeat(level)
		var indent_val: String  = str(cmd.get("indent", "?"))
		var action: String      = cmd.get("action", "")
		var extra: String       = ""

		if action == "if":
			extra = " condition=%s negate=%s" % [cmd["condition"], cmd.get("negate", false)]
		elif action == "repeat":
			extra = " count=%s" % cmd["count"]
		# loop has no extra

		print_debug("%s- %s (indent=%s)%s" % [prefix, action, indent_val, extra])

		if cmd.has("body") and cmd["body"].size() > 0:
			_debug_print_commands(cmd["body"], level + 1)
		if cmd.has("else_body") and cmd["else_body"].size() > 0:
			print_debug("%s  else:" % prefix)
			_debug_print_commands(cmd["else_body"], level + 1)
