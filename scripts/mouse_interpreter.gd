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
var variables := {}  # Dictionary to hold all variables


var Helper : InterpreterHelper = preload("res://scripts/interpreter_helper.gd").new().init(self)

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
	emit_signal("finished")

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
		while stack.size() > 0 and (indent < stack[-1]["indent"] or ((stack[-1]["action"] in ["repeat", "loop", "while", "while_facing", "while_on", "while_centered", "for_loop"]) and indent == stack[-1]["indent"])):
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
		elif content.begins_with("FOR ") and " IN " in content:
			var pieces = content.substr(4).split(" IN ", false)
			if pieces.size() != 2:
				push_error("Invalid FOR syntax: " + trimmed)
				return []
			var var_name = pieces[0].strip_edges().to_lower()
			var list_name = pieces[1].strip_edges().to_lower()
			var for_block = {
				"action": "for_loop",
				"var_name": var_name,
				"list_name": list_name,
				"body": [],
				"indent": indent
			}
			parent_body.append(for_block)
			stack.append(for_block)
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
			if stack.is_empty() or stack[-1]["action"] not in ["if", "if_facing", "if_on"]:
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
#--------------------------------------------------------------------------------
#							VARIABLE STATEMENTS
#--------------------------------------------------------------------------------
		elif content.begins_with("VAR "):
			var decl_str = trimmed.substr(len("VAR "))
			var eq_index = decl_str.find("=")
			if eq_index == -1:
				push_error("Missing '=' in VAR statement")
				return []
			var declaration = decl_str.substr(0, eq_index).strip_edges()
			var value_str = decl_str.substr(eq_index + 1).strip_edges()
			var parts = declaration.split(" ", false)
			if parts.size() != 2:
				push_error("Invalid VAR syntax: " + trimmed)
				return []

			var var_type = parts[0].to_upper()
			var var_name = parts[1].to_lower()
			var cmd = {
				"action": "declare_var",
				"type": var_type,
				"name": var_name,
				"value": value_str,
				"line": i
			}
			parent_body.append(cmd)

		elif content.begins_with("SET "):
			var decl_str := trimmed.substr(len("SET ")).strip_edges()
			var eq_index := decl_str.find("=")
			if eq_index == -1:
				push_error("Missing '=' in SET statement")
				return []

			var var_name := decl_str.substr(0, eq_index).strip_edges().to_lower()
			var value_str := decl_str.substr(eq_index + 1).strip_edges()

			var cmd = {
				"action": "set_var",
				"name": var_name,
				"value": value_str,
				"line": i
			}
			parent_body.append(cmd)
			
		elif content.begins_with("LIST "):
			var decl_str = trimmed.substr(len("LIST "))
			var eq_index = decl_str.find("=")
			if eq_index == -1:
				push_error("Missing '=' in LIST statement")
				return []
			var declaration = decl_str.substr(0, eq_index).strip_edges()
			var value_str = decl_str.substr(eq_index + 1).strip_edges()
			var parts = declaration.split(" ", false)
			if parts.size() != 2:
				push_error("Invalid LIST syntax: " + trimmed)
				return []
			var var_type = parts[0].to_upper()
			var var_name = parts[1].to_lower()
			var cmd = {
				"action": "declare_list",
				"type": var_type,
				"name": var_name,
				"value": value_str,
				"line": i
			}
			parent_body.append(cmd)
			
		elif content.begins_with("APPEND "):
			var append_parts = trimmed.substr(len("APPEND ")).strip_edges()
			var parts = append_parts.split(" ", false)
			if parts.size() != 2:
				push_error("Invalid APPEND syntax: " + trimmed)
				return []
			var cmd = {
				"action": "append_var",
				"name": parts[0].to_lower(),
				"value": parts[1],
				"line": i
			}
			parent_body.append(cmd)

		else:
			push_error("Unknown command: %s" % trimmed)
			return []
	return root_commands

func _run_command_list(commands: Array, token: int) -> void:
	for cmd in commands:
		if token != _run_id or stop_flag:
			return
		# Only highlight leaf/executable commands, not control structures
		if not cmd["action"].begins_with("while") and not cmd["action"].begins_with("if") and cmd["action"] not in ["loop", "repeat"]:
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
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)

			"if":
				var sensor_name: String = cmd["condition"]
				var raw_val: bool = mouse.read_sensor(sensor_name)
				var neg: bool = cmd.get("negate", false)
				var result: bool = raw_val if not neg else not raw_val
				if result:
					emit_signal("line_changed", cmd.get("line", -1))
					await _run_command_list(cmd["body"], token)
				else:
					emit_signal("line_changed", cmd.get("line", -1))
					await _run_command_list(cmd["else_body"], token)
				return

			"if_facing", "if_on":
				var target_str: String = cmd["target"]
				var target_pos: Vector2i = Helper._resolve_position(target_str)
				var neg = cmd["negate"]
				var result := not Helper._compare_position(cmd["action"], target_pos) if neg else Helper._compare_position(cmd["action"], target_pos)
				emit_signal("line_changed", cmd.get("line", -1))
				if result:
					await _run_command_list(cmd["body"], token)
				else:
					await _run_command_list(cmd["else_body"], token)
				return

			"while_facing", "while_on":
				var wcount := 0
				var target_str: String = cmd["target"]
				var neg = cmd["negate"]

				while token == _run_id and running and not stop_flag and (Helper._compare_position(cmd["action"], Helper._resolve_position(target_str)) != neg):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return

					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)
					wcount += 1

			"while_centered":
				var wcount := 0
				var target = Helper._resolve_position(cmd["target"])
				var neg = cmd["negate"]
				while token == _run_id and running and not stop_flag and (Helper._is_centered(target) != neg):
					if wcount >= max_iterations:
						push_error("Infinite loop detected — execution aborted.")
						running = false
						return
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)
					wcount += 1
				# Snap to exact center if condition was positive (i.e. user was trying to center)
				if not neg and token == _run_id and not stop_flag:
					mouse.snap_to_cell_center(Helper._parse_position(target))
					
			"declare_var":
				var name = cmd["name"]
				var var_type = cmd["type"]
				var value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					push_error("Invalid value for variable %s of type %s" % [name, var_type])
				else:
					variables[name] = { "type": var_type, "value": value }

			"set_var":
				var name = cmd["name"]
				if not variables.has(name):
					push_error("Variable '%s' not declared" % name)
					return
				var var_type = variables[name]["type"]
				var value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					push_error("Invalid value for %s of type %s" % [name, var_type])
				else:
					variables[name]["value"] = value
					
			"declare_list":
				var name = cmd["name"]
				var var_type = cmd["type"]
				var values = Helper._convert_list_value(var_type, cmd["value"])
				if values == null:
					push_error("Invalid list value for %s of type %s" % [name, var_type])
				else:
					variables[name] = { "type": "LIST_" + var_type, "value": values }

			"set_var":
				var name = cmd["name"]
				if not variables.has(name):
					push_error("Variable '%s' not declared" % name)
					return
				var var_type = variables[name]["type"]
				var value
				if var_type.begins_with("LIST_"):
					value = Helper._convert_list_value(var_type.replace("LIST_", ""), cmd["value"])
				else:
					value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					push_error("Invalid value for %s of type %s" % [name, var_type])
				else:
					variables[name]["value"] = value
					
			"append_var":
				var name = cmd["name"]
				if not variables.has(name):
					push_error("Cannot append: variable '%s' not found" % name)
					return
				if not variables[name]["type"].begins_with("LIST_"):
					push_error("Cannot append to non-list variable '%s'" % name)
					return
				var base_type = variables[name]["type"].replace("LIST_", "")
				var value = Helper._resolve_value(base_type, cmd["value"])
				if value == null:
					push_error("Invalid value to append: %s" % cmd["value"])
				else:
					variables[name]["value"].append(value)
					
			"for_loop":
				var list_name = cmd["list_name"]
				var var_name = cmd["var_name"]
				if not variables.has(list_name):
					push_error("List '%s' not declared" % list_name)
					return
				var list_data = variables[list_name]
				if typeof(list_data.value) != TYPE_ARRAY:
					push_error("Variable '%s' is not a list" % list_name)
					return

				for item in list_data.value:
					variables[var_name] = {"type": "VECTOR", "value": item}
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)

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
		elif cmd["action"] in ["repeat", "loop", "for_loop"]:
			info += " count=%s" % [cmd.get("count", "")]
		print(info)

		# recurse into bodies
		if cmd["action"]in ["if", "if_facing", "if_on"]:
			print("%s  body:" % prefix)
			dump_commands(cmd["body"], level + 1)
			print("%s  else_body:" % prefix)
			dump_commands(cmd["else_body"], level + 1)
		elif cmd["action"] in ["repeat", "loop", "while", "while_facing", "while_on", "while_centered", "for_loop"]:
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
