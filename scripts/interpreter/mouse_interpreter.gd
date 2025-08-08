# res://scripts/interpreter/mouse_interpreter.gd
extends Node

class_name MouseInterpreter

signal line_changed(line_number: int)
signal finished
signal error(message: String)

var command_queue: Array = []
var running := false
var mouse: Node = null
var max_iterations := 10000
var stop_flag := false
var _run_id: int = 0
var variables := {}  # Dictionary to hold all variables
var loop_stack: Array = []

var Helper : InterpreterHelper
var Parser : InterpreterParser

func init():
	Helper = preload("res://scripts/interpreter/interpreter_helper.gd").new().init(self)
	Parser = preload("res://scripts/interpreter/parser.gd").new().init(self)
	return [self, Helper, Parser]

func stop():
	stop_flag = true            # tell all loops to break out
	running = false
	_run_id += 1
	command_queue.clear()
	emit_signal("line_changed", -1)
	emit_signal("finished")

func run_script(script_text: String, mouse_ref: Node, time_holder: Node):#
	mouse = mouse_ref
	stop_flag = false
	command_queue = Parser.parse_script(script_text)
	if Globals.print_parse_tree:
		print("=== PARSE TREE ===")
		dump_commands(command_queue)
		print("=== END PARSE TREE ===")
	if command_queue.is_empty():
		emit_signal("error", "No commands to run.")
		return
	var my_token := _run_id
	running = true
	stop_flag = false
	time_holder.start()
	await _run_command_list(command_queue, my_token)
	stop()
	emit_signal("finished")

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
				loop_stack.append({"type": "loop", "break": false, "continue": false})
				while token == _run_id and running and not stop_flag:
					if count > max_iterations:
						emit_signal("error", "Infinite loop detected — execution aborted.")
						stop()
						break
					await _run_command_list(cmd["body"], token)
					var loop_ctx = loop_stack[-1]
					if loop_ctx["break"]:
						break
					if loop_ctx["continue"]:
						loop_ctx["continue"] = false
						continue
					count += 1
				loop_stack.pop_back()

			"while":
				var wcount: int = 0
				var sensor_name: String = cmd["condition"]
				var negate: bool = cmd.get("negate", false)
				loop_stack.append({"type": "while", "break": false, "continue": false})
				while token == _run_id and running and not stop_flag and (mouse.read_sensor(sensor_name) != negate):
					if wcount >= max_iterations:
						emit_signal("error", "Infinite loop detected — execution aborted.")
						stop()
						break
					await _run_command_list(cmd["body"], token)
					var loop_ctx = loop_stack[-1]
					if loop_ctx["break"]:
						break
					if loop_ctx["continue"]:
						loop_ctx["continue"] = false
						continue
					wcount += 1
				loop_stack.pop_back()
				return

			"repeat":
				loop_stack.append({"type": "repeat", "break": false, "continue": false})
				for i in range(cmd["count"]):
					if stop_flag or token != _run_id:
						return
					await _run_command_list(cmd["body"], token)
					var loop_ctx = loop_stack[-1]
					if loop_ctx["break"]:
						break
					if loop_ctx["continue"]:
						loop_ctx["continue"] = false
						continue
				loop_stack.pop_back()

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

			"while_facing", "while_on":
				var wcount := 0
				var target_str: String = cmd["target"]
				var neg = cmd["negate"]
				loop_stack.append({"type": cmd["action"], "break": false, "continue": false})
				while token == _run_id and running and not stop_flag and (Helper._compare_position(cmd["action"], Helper._resolve_position(target_str)) != neg):
					if wcount >= max_iterations:
						emit_signal("error", "Infinite loop detected — execution aborted.")
						running = false
						break
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)
						var loop_ctx = loop_stack[-1]
						if loop_ctx["break"]:
							break
						if loop_ctx["continue"]:
							loop_ctx["continue"] = false
							continue
					wcount += 1
				loop_stack.pop_back()

			"while_centered":
				var wcount := 0
				var target_str = cmd["target"]         # keep the literal string
				var neg = cmd["negate"]
				loop_stack.append({"type": "while_centered", "break": false, "continue": false})
				# re-resolve on each iteration
				while token == _run_id and running and not stop_flag and (Helper._is_centered(Helper._resolve_position(target_str)) != neg):
					if wcount >= max_iterations:
						emit_signal("error", "Infinite loop detected — execution aborted.")
						running = false
						break
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)
						var loop_ctx = loop_stack[-1]
						if loop_ctx["break"]:
							break
						if loop_ctx["continue"]:
							loop_ctx["continue"] = false
							continue
					wcount += 1
				loop_stack.pop_back()
				# only after a WHILE NOT CENTERED do we snap to the newly-resolved center
				if neg and token == _run_id and not stop_flag:
					var final_target = Helper._resolve_position(target_str)
					mouse.snap_to_cell_center(final_target)


			"for_loop":
				var list_name = cmd["list_name"]
				var var_name = cmd["var_name"]
				if not variables.has(list_name):
					emit_signal("error", "List '%s' not declared" % list_name)
					return
				var list_data = variables[list_name]
				if typeof(list_data.value) != TYPE_ARRAY:
					emit_signal("error", "Variable '%s' is not a list" % list_name)
					return
				loop_stack.append({"type": "for_loop", "break": false, "continue": false})
				for item in list_data.value:
					variables[var_name] = {"type": "VECTOR", "value": item}
					for inner_cmd in cmd["body"]:
						if token != _run_id or stop_flag:
							return
						emit_signal("line_changed", inner_cmd.get("line", -1))
						await _run_command_list([inner_cmd], token)
						var loop_ctx = loop_stack[-1]
						if loop_ctx["break"]:
							break
						if loop_ctx["continue"]:
							loop_ctx["continue"] = false
							continue
				loop_stack.pop_back()

			"break":
				if loop_stack.is_empty():
					emit_signal("error", "BREAK used outside of loop")
					return
				loop_stack[-1]["break"] = true
				return

			"continue":
				if loop_stack.is_empty():
					emit_signal("error", "CONTINUE used outside of loop")
					return
				loop_stack[-1]["continue"] = true
				return
					
			"declare_var":
				var name = cmd["name"]
				var var_type = cmd["type"]
				var value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					emit_signal("error", "Invalid value for variable %s of type %s" % [name, var_type])
				else:
					variables[name] = { "type": var_type, "value": value }

			"set_var":
				var name = cmd["name"]
				if not variables.has(name):
					emit_signal("error", "Variable '%s' not declared" % name)
					return
				var var_type = variables[name]["type"]
				var value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					emit_signal("error", "Invalid value for %s of type %s" % [name, var_type])
				else:
					variables[name]["value"] = value
					
			"declare_list":
				var name = cmd["name"]
				var var_type = cmd["type"]
				var values = Helper._convert_list_value(var_type, cmd["value"])
				if values == null:
					emit_signal("error", "Invalid list value for %s of type %s" % [name, var_type])
				else:
					variables[name] = { "type": "LIST_" + var_type, "value": values }

			"set_var":
				var name = cmd["name"]
				if not variables.has(name):
					emit_signal("error", "Variable '%s' not declared" % name)
					return
				var var_type = variables[name]["type"]
				var value
				if var_type.begins_with("LIST_"):
					value = Helper._convert_list_value(var_type.replace("LIST_", ""), cmd["value"])
				else:
					value = Helper._convert_value(var_type, cmd["value"])
				if value == null:
					emit_signal("error", "Invalid value for %s of type %s" % [name, var_type])
				else:
					variables[name]["value"] = value
					
			"append_var":
				var name = cmd["name"]
				if not variables.has(name):
					emit_signal("error", "Cannot append: variable '%s' not found" % name)
					return
				if not variables[name]["type"].begins_with("LIST_"):
					emit_signal("error", "Cannot append to non-list variable '%s'" % name)
					return
				var base_type = variables[name]["type"].replace("LIST_", "")
				var value = Helper._resolve_value(base_type, cmd["value"])
				if value == null:
					emit_signal("error", "Invalid value to append: %s" % cmd["value"])
				else:
					variables[name]["value"].append(value)
					
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
