# res://scripts/interpreter/parser.gd
extends Node

class_name InterpreterParser

var interpreter  # will store reference to the parent

const BLOCK_TYPES = ["repeat", "loop", "while", "while_facing", "while_on", "while_centered", "for_loop", "if", "if_facing", "if_on"]

func init(interpreter_ref):
	interpreter = interpreter_ref
	return self  # allows chaining

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

		while stack.size() > 0:
			var top = stack[-1]
			var is_if_waiting_else = top["action"] in ["if", "if_on", "if_facing"] and top.get("state", "body") == "body"
			var same_level = indent == top["indent"]

			if indent < top["indent"]:
				stack.pop_back()
			elif same_level and top["action"] in BLOCK_TYPES and not is_if_waiting_else:
				stack.pop_back()
			else:
				break

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
#--------------------------------------------------------------------------------
#							EXIT STATEMENTS
#--------------------------------------------------------------------------------
		elif content == "BREAK":
			parent_body.append({"action": "break", "line": i})
		elif content == "CONTINUE":
			parent_body.append({"action": "continue", "line": i})


		else:
			push_error("Unknown command: %s" % trimmed)
			return []
	return root_commands
