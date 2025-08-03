# mouse_interpreter.gd
extends Node

class_name MouseInterpreter

signal line_changed(line_number: int)
signal finished
var command_queue: Array = []
var running := false
var mouse: Node = null
var max_iterations := 1000
var stop_flag := false

func stop():
	running = false
	stop_flag = true
	emit_signal("finished")

func run_script(script_text: String, mouse_ref: Node):
	mouse = mouse_ref
	command_queue = parse_script(script_text)
	if command_queue.is_empty():
		push_error("No commands to run.")
		return
	running = true
	stop_flag = false
	await _run_command_list(command_queue)

func parse_script(script: String) -> Array:
	var lines = script.split("\n", false)
	var tokens := []
	var stack := []

	for i in lines.size():
		var raw_line = lines[i]
		var line = raw_line.strip_edges().to_upper()
		if line == "" or line.begins_with("#"):
			continue
		
		match line:
			"LOOP":
				var loop_block := {"action": "loop", "body": []}
				stack.append(loop_block)
			"ENDLOOP":
				var finished = stack.pop_back()
				if stack.is_empty():
					tokens.append(finished)
				else:
					_append_command(stack, finished)
			"MOVE":
				_append_command(stack, {"action": "move", "line": i})
			"LEFT":
				_append_command(stack, {"action": "left", "line": i})
			"RIGHT":
				_append_command(stack, {"action": "right", "line": i})
			"ENDREPEAT":
				var finished = stack.pop_back()
				if stack.is_empty():
					tokens.append(finished)
				else:
					_append_command(stack, finished)
			_:
				if line.begins_with("REPEAT"):
					var count = int(line.substr(6).strip_edges())
					var repeat_block := {"action": "repeat", "count": count, "body": []}
					stack.append(repeat_block)
				elif line.begins_with("IF SENSOR"):
					var name = line.substr(10).strip_edges()
					var cond = {"action": "if", "condition": name, "body": [], "else_body": []}
					stack.append(cond)
				elif line == "ELSE":
					var if_block = stack.pop_back()
					if if_block["action"] != "if":
						push_error("ELSE without matching IF")
						return []
					stack.append(if_block)
					stack.append({"action": "else_body", "body": []})
				elif line == "ENDIF":
					var last = stack.pop_back()
					if last["action"] == "else_body":
						var wrapper = stack.pop_back()
						wrapper["else_body"] = last["body"]
						if stack.is_empty():
							tokens.append(wrapper)
						else:
							_append_command(stack, wrapper)
					else:
						if stack.is_empty():
							tokens.append(last)
						else:
							_append_command(stack, last)
				else:
					push_error("Unknown command: %s" % line)
	return tokens

func _append_command(stack: Array, cmd: Dictionary):
	if stack.is_empty():
		command_queue.append(cmd)
	else:
		if stack[-1].has("body") and typeof(stack[-1]["body"]) == TYPE_ARRAY:
			stack[-1]["body"].append(cmd)
		else:
			push_error("Cannot append command — stack top has no valid 'body'")

func _run_command_list(commands: Array) -> void:
	for cmd in commands:
		emit_signal("line_changed", cmd.get("line", -1))
		if stop_flag:
			push_warning("Execution stopped manually.")
			return

		if Globals.interpreter_debug_enabled:
			print_debug("Running command:", cmd)

		match cmd["action"]:
			"move":
				mouse.move_forward()
			"left":
				mouse.turn_left()
			"right":
				mouse.turn_right()
			"loop":
				var count := 0
				while running and not stop_flag:
					if count > max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					await _run_command_list(cmd["body"])
					count += 1
			"repeat":
				for i in cmd["count"]:
					if stop_flag:
						return
					await _run_command_list(cmd["body"])
			"if":
				var result = mouse.read_sensor(cmd["condition"])
				if result:
					await _run_command_list(cmd["body"])
				else:
					await _run_command_list(cmd.get("else_body", []))

		if cmd["action"] == "LEFT" or cmd["action"] == "RIGHT":
			await get_tree().create_timer(Globals.turn_delay).timeout
		elif "REPEAT" in cmd["action"]:
			await get_tree().create_timer(Globals.repeat_delay).timeout
		else:
			await get_tree().create_timer(Globals.move_delay).timeout
	if not stop_flag:
		emit_signal("finished")
