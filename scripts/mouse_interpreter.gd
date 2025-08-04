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
	if Globals.print_parse_tree:
		print("=== PARSE TREE ===")
		dump_commands(command_queue)
		print("=== END PARSE TREE ===")
	if command_queue.is_empty():
		push_error("No commands to run.")
		return
	var my_token := _run_id
	running = true
	stop_flag = false
	await _run_command_list(command_queue, my_token)

func parse_script(script: String) -> Array:
	var lines = script.split("\n", false)
	var root_commands: Array = []
	var stack: Array = []
	for i in range(lines.size()):
		var raw_line: String = lines[i]
		var indent := 0
		var rest := raw_line
		while rest.begins_with("\t") or rest.begins_with("    "):
			if rest.begins_with("\t"):
				indent += 1
				rest = rest.substr(1)
			else:
				indent += 1
				rest = rest.substr(4)
		var trimmed := rest.strip_edges()
		#print("DEBUG parse: line %d → indent=%d, trimmed=\"%s\"" % [i+1, indent, trimmed])
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		var content := trimmed.to_upper()
		# Pop finished or same-level blocks
		while stack.size() > 0 and (indent < stack[-1]["indent"] or ((stack[-1]["action"] in ["repeat", "loop", "while", "while_facing", "while_on", "while_centered"]) and indent == stack[-1]["indent"])):
			stack.pop_back()
		# Determine where to append this command
		var parent_body: Array
		if stack.is_empty():
			parent_body = root_commands
		else:
			var top = stack[-1]
			if top["action"] in ["if", "if_facing", "if_on"] and top.get("state", "body") == "else":
				parent_body = top["else_body"]
			else:
				parent_body = top["body"]
				
		# Parse commands
#--------------------------------------------------------------------------------
#							LOOP STATEMENTS
#--------------------------------------------------------------------------------
		if content == "LOOP":
			var loop_block = {"action":"loop", "body":[], "indent":indent}
			parent_body.append(loop_block)
			stack.append(loop_block)
		elif content.begins_with("REPEAT"):
			var count := int(content.substr(6).strip_edges())
			var repeat_block = {"action":"repeat", "count":count, "body":[], "indent":indent}
			parent_body.append(repeat_block)
			stack.append(repeat_block)
#--------------------------------------------------------------------------------
#							WHILE STATEMENTS
#--------------------------------------------------------------------------------
		elif content.begins_with("WHILE SENSOR"):
			var name = trimmed.substr(len("WHILE SENSOR")).strip_edges()
			var while_block = {"action":"while", "condition":name, "negate":false, "body":[], "indent":indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE NOT SENSOR"):
			var name = trimmed.substr(len("WHILE NOT SENSOR")).strip_edges()
			var while_block = {"action":"while", "condition":name, "negate":true, "body":[], "indent":indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE FACING"):
			var pos = trimmed.substr(len("WHILE FACING")).strip_edges()
			var while_block = {"action": "while_facing", "target": pos, "negate": false, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE NOT FACING"):
			var pos = trimmed.substr(len("WHILE NOT FACING")).strip_edges()
			var while_block = {"action": "while_facing", "target": pos, "negate": true, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE ON"):
			var pos = trimmed.substr(len("WHILE ON")).strip_edges()
			var while_block = {"action": "while_on", "target": pos, "negate": false, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE NOT ON"):
			var pos = trimmed.substr(len("WHILE NOT ON")).strip_edges()
			var while_block = {"action": "while_on", "target": pos, "negate": true, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE CENTERED"):
			var pos = trimmed.substr(len("WHILE CENTERED")).strip_edges()
			var while_block = {"action": "while_centered", "target": pos, "negate": false, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE NOT CENTERED"):
			var pos = trimmed.substr(len("WHILE NOT CENTERED")).strip_edges()
			var while_block = {"action": "while_centered", "target": pos, "negate": true, "body": [], "indent": indent}
			parent_body.append(while_block)
			stack.append(while_block)
#--------------------------------------------------------------------------------
#							IF STATEMENTS
#--------------------------------------------------------------------------------
		elif content.begins_with("IF SENSOR"):
			var name := trimmed.substr(len("IF SENSOR")).strip_edges()
			var if_block = {"action":"if", "condition":name, "negate":false, "body":[], "else_body":[], "indent":indent, "state":"body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF NOT SENSOR"):
			var name := trimmed.substr(len("IF NOT SENSOR")).strip_edges()  # length of "IF NOT SENSOR"
			var if_block = {"action":"if", "condition":name, "negate":true, "body":[], "else_body":[], "indent":indent, "state":"body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF FACING"):
			var pos = trimmed.substr(len("IF FACING")).strip_edges()
			var if_block = {"action": "if_facing", "target": pos, "negate": false, "body": [], "else_body": [], "indent": indent, "state": "body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF NOT FACING"):
			var pos = trimmed.substr(len("IF NOT FACING")).strip_edges()
			var if_block = {"action": "if_facing", "target": pos, "negate": true, "body": [], "else_body": [], "indent": indent, "state": "body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF ON"):
			var pos = trimmed.substr(len("IF ON")).strip_edges()
			var if_block = {"action": "if_on", "target": pos, "negate": false, "body": [], "else_body": [], "indent": indent, "state": "body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF NOT ON"):
			var pos = trimmed.substr(len("IF NOT ON")).strip_edges()
			var if_block = {"action": "if_on", "target": pos, "negate": true, "body": [], "else_body": [], "indent": indent, "state": "body"}
			parent_body.append(if_block)
			stack.append(if_block)
#--------------------------------------------------------------------------------
#							ELSE STATEMENTS
#--------------------------------------------------------------------------------
		elif content == "ELSE":
			if stack.is_empty() or stack[-1]["action"] != "if":
				push_error("ELSE without matching IF")
				return []
			# Switch to else body for this if block
			stack[-1]["state"] = "else"
#--------------------------------------------------------------------------------
#							MOVEMENT STATEMENTS
#--------------------------------------------------------------------------------
		elif content == "MOVE":
			parent_body.append({"action":"move", "line":i})
		elif content == "LEFT":
			parent_body.append({"action":"left", "line":i})
		elif content == "RIGHT":
			parent_body.append({"action":"right", "line":i})
		else:
			push_error("Unknown command: %s" % trimmed)
			return []
	return root_commands

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
					
			"while_centered":
				var wcount := 0
				var target = cmd["target"]
				var neg = cmd["negate"]
				while token == _run_id and running and not stop_flag and (_is_centered(target) != neg):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						await _run_command_list([inner_cmd], token)
					wcount += 1
				# Snap to exact center if condition was positive (i.e. user was trying to center)
				if not neg and token == _run_id and not stop_flag:
					mouse.snap_to_cell_center(_parse_position(target))

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
			
func _is_centered(target_str: String) -> bool:
	var target_pos: Vector2i
	if target_str.begins_with("{") and target_str.ends_with("}"):
		var raw: String = target_str.substr(1, target_str.length() - 2).strip_edges()
		var parts: PackedStringArray = raw.split(",", false)
		if parts.size() != 2:
			push_error("Invalid coordinate format: " + target_str)
			return false
		target_pos = Vector2i(parts[0].to_int(), parts[1].to_int())
	else:
		push_error("Invalid position format: " + target_str)
		return false

	var current_pos: Vector2 = mouse.global_position
	var center: Vector2 = mouse.get_cell_center(target_pos)
	var dist: float = current_pos.distance_to(center)

	if Globals.interpreter_debug_enabled:
		print_debug("Checking centeredness: pos=", current_pos, " target_center=", center, " dist=", dist)

	return dist < 10.0  # Adjust as needed

func _parse_position(pos_str: String) -> Vector2i:
	if pos_str.begins_with("{") and pos_str.ends_with("}"):
		var trimmed = pos_str.substr(1, pos_str.length() - 2).strip_edges()
		var parts = trimmed.split(",", false)
		if parts.size() != 2:
			push_error("Invalid coordinate format: " + pos_str)
			return Vector2i.ZERO
		return Vector2i(parts[0].to_int(), parts[1].to_int())
	else:
		push_error("Expected coordinate in format {x, y}, got: " + pos_str)
		return Vector2i.ZERO


# Dump the parsed command tree so you can see exactly
# which commands ended up in which bodies/else_bodies.
func dump_commands(cmds: Array, level: int = 0) -> void:
	for cmd in cmds:
		# indent the printout by one tab per tree‐level
		var prefix := ""
		for temp in range(level):
			prefix += "\t"
		# print the basic info
		var info := "%s- action=%s (indent=%s)" % [prefix, cmd["action"], cmd.get("indent", "?")]
		if cmd["action"] in ["if", "if_facing", "if_on"]:
			info += " condition=\"%s\" negate=%s" % [cmd["condition"], cmd.get("negate", false)]
		elif cmd["action"] == "repeat" or cmd["action"] == "loop":
			info += " count=%s" % [cmd.get("count", "")]
		print(info)

		# recurse into bodies
		if cmd["action"]in ["if", "if_facing", "if_on"]:
			print("%s  body:" % prefix)
			dump_commands(cmd["body"], level + 1)
			print("%s  else_body:" % prefix)
			dump_commands(cmd["else_body"], level + 1)
		elif cmd["action"] in ["repeat", "loop", "while", "while_facing", "while_on", "while_centered"]:
			print("%s  body:" % prefix)
			dump_commands(cmd["body"], level + 1)

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
