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

func run_script(script_text: String, mouse_ref: Node):#
	mouse = mouse_ref
	command_queue = parse_script(script_text)
	print("=== PARSE TREE ===")
	dump_commands(command_queue)
	print("=== END PARSE TREE ===")
	if command_queue.is_empty():
		push_error("No commands to run.")
		return
	running = true
	stop_flag = false
	await _run_command_list(command_queue)

func parse_script(script: String) -> Array:
	var lines = script.split("\n", false)
	var root_commands: Array = []
	var stack: Array = []
	for i in range(lines.size()):
		var raw_line: String = lines[i]
		# → DEBUG: show raw content and computed indent
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
		print("DEBUG parse: line %d → indent=%d, trimmed=\"%s\"" % [i+1, indent, trimmed])
		if trimmed == "" or trimmed.begins_with("#"):
			continue
		var content := trimmed.to_upper()
		# Pop finished or same-level blocks
		while stack.size() > 0 and (indent < stack[-1]["indent"] or ((stack[-1]["action"] in ["repeat", "loop", "while"]) and indent == stack[-1]["indent"])):
			stack.pop_back()
		# Determine where to append this command
		var parent_body: Array
		if stack.is_empty():
			parent_body = root_commands
		else:
			var top = stack[-1]
			if top["action"] == "if" and top.get("state", "body") == "else":
				parent_body = top["else_body"]
			else:
				parent_body = top["body"]
				
		# Parse commands
		if content == "LOOP":
			var loop_block = {"action":"loop", "body":[], "indent":indent}
			parent_body.append(loop_block)
			stack.append(loop_block)
		elif content.begins_with("REPEAT"):
			var count := int(content.substr(6).strip_edges())
			var repeat_block = {"action":"repeat", "count":count, "body":[], "indent":indent}
			parent_body.append(repeat_block)
			stack.append(repeat_block)
		elif content.begins_with("WHILE NOT SENSOR"):
			var name = trimmed.substr(len("WHILE NOT SENSOR")).strip_edges()
			var while_block = {"action":"while", "condition":name, "negate":true, "body":[], "indent":indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("WHILE SENSOR"):
			var name = trimmed.substr(len("WHILE SENSOR")).strip_edges()
			var while_block = {"action":"while", "condition":name, "negate":false, "body":[], "indent":indent}
			parent_body.append(while_block)
			stack.append(while_block)
		elif content.begins_with("IF SENSOR"):
			var name := trimmed.substr(len("IF SENSOR")).strip_edges()
			var if_block = {"action":"if", "condition":name, "negate":false, "body":[], "else_body":[], "indent":indent, "state":"body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content.begins_with("IF NOT SENSOR"):
			# New support for inverted sensor check
			var name := trimmed.substr(len("IF NOT SENSOR")).strip_edges()  # length of "IF NOT SENSOR"
			var if_block = {"action":"if", "condition":name, "negate":true, "body":[], "else_body":[], "indent":indent, "state":"body"}
			parent_body.append(if_block)
			stack.append(if_block)
		elif content == "ELSE":
			if stack.is_empty() or stack[-1]["action"] != "if":
				push_error("ELSE without matching IF")
				return []
			# Switch to else body for this if block
			stack[-1]["state"] = "else"
		elif content == "MOVE":
			parent_body.append({"action":"move", "line":i})
		elif content == "LEFT":
			parent_body.append({"action":"left", "line":i})
		elif content == "RIGHT":
			parent_body.append({"action":"right", "line":i})
		else:
			push_error("Unknown command: %s" % trimmed)
			return []
	print_debug("=== PARSE TREE ===")
	_debug_print_commands(root_commands)
	print_debug("=== END PARSE TREE ===")
	return root_commands

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

			"while":
				# wcount must be typed so GDScript infers it correctly
				var wcount: int = 0
				# explicitly type your command‐fields
				var sensor_name: String = cmd["condition"]
				var negate: bool = cmd.get("negate", false)
				# loop only while the (possibly‐negated) sensor stays true
				while running \
				  and not stop_flag \
				  and (mouse.read_sensor(sensor_name) != negate):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					await _run_command_list(cmd["body"])
					wcount += 1
				# jump straight back to the outer LOOP when the sensor flips
				return

			"repeat":
				for i in range(cmd["count"]):
					if stop_flag:
						return
					await _run_command_list(cmd["body"])

			"if":
				var sensor_name: String = cmd["condition"]
				var raw_val: bool    = mouse.read_sensor(sensor_name)
				var neg: bool        = cmd.get("negate", false)
				# Godot inline‐if instead of C‐style ternary:
				var result: bool = raw_val if not neg else not raw_val
				if result:
					await _run_command_list(cmd["body"])
				else:
					await _run_command_list(cmd["else_body"])
		
		var delay: float
		match cmd["action"]:
			"left", "right":
				delay = Globals.turn_delay
			"repeat", "loop":
				delay = Globals.repeat_delay
			_:
				delay = Globals.move_delay
		await get_tree().create_timer(delay).timeout

	if not stop_flag:
		emit_signal("finished")
		
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
		if cmd["action"] == "if":
			info += " condition=\"%s\" negate=%s" % [cmd["condition"], cmd.get("negate", false)]
		elif cmd["action"] == "repeat" or cmd["action"] == "loop":
			info += " count=%s" % [cmd.get("count", "")]
		print(info)

		# recurse into bodies
		if cmd["action"] == "if":
			print("%s  body:" % prefix)
			dump_commands(cmd["body"], level + 1)
			print("%s  else_body:" % prefix)
			dump_commands(cmd["else_body"], level + 1)
		elif cmd["action"] in ["repeat", "loop", "while"]:
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
