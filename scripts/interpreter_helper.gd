extends Node

class_name InterpreterHelper

var interpreter  # will store reference to the parent

func init(interpreter_ref):
	interpreter = interpreter_ref
	return self  # allows chaining

func _split_top_level(input: String, delimiter: String = ",") -> Array:
	var result: Array = []
	var buffer: String = ""
	var depth := 0
	for i in input.length():
		var char := input[i]
		if char == "{" or char == "[":
			depth += 1
		elif char == "}" or char == "]":
			depth -= 1
		if char == delimiter and depth == 0:
			result.append(buffer.strip_edges())
			buffer = ""
		else:
			buffer += char
	if buffer != "":
		result.append(buffer.strip_edges())
	return result
	
func _resolve_value(var_type: String, raw: String) -> Variant:
	raw = raw.strip_edges()
	if interpreter.variables.has(raw.to_lower()):
		var entry = interpreter.variables[raw.to_lower()]
		if entry["type"] == var_type or entry["type"] == "LIST_" + var_type:
			return entry["value"]
	else:
		return _convert_value(var_type, raw)
	return null
	
func _convert_list_value(var_type: String, raw_value: String) -> Array:
	if not raw_value.begins_with("[") or not raw_value.ends_with("]"):
		push_error("List must be in format [item1,item2,...]")
		return []
	var trimmed = raw_value.substr(1, raw_value.length() - 2).strip_edges()
	var inner = raw_value.substr(1, raw_value.length() - 2).strip_edges()
	var items = _split_top_level(inner)
	var result: Array = []
	for item in items:
		var val = _convert_value(var_type, item.strip_edges())
		if val == null:
			push_error("Invalid item in list: %s" % item)
			return []
		result.append(val)
	return result

func _convert_value(var_type: String, raw_value: String) -> Variant:
	match var_type:
		"INT":
			return int(raw_value)
		"FLOAT":
			return float(raw_value)
		"STRING":
			return raw_value
		"VECTOR":
			return _parse_position(raw_value)
		_:
			push_error("Unknown type: %s" % var_type)
			return []
			
func _resolve_position(pos_str: String) -> Vector2i:
	pos_str = pos_str.strip_edges()
	pos_str = pos_str.to_lower()
	if pos_str.begins_with("{") and pos_str.ends_with("}"):
		var raw = pos_str.substr(1, pos_str.length() - 2).strip_edges()
		var parts = raw.split(",", false)
		if parts.size() != 2:
			push_error("Invalid coordinate format: " + pos_str)
			return Vector2i.ZERO
		return Vector2i(parts[0].to_int(), parts[1].to_int())
	else:
		if interpreter.variables.has(pos_str):
			var val = interpreter.variables[pos_str]["value"]
			if val is Vector2i:
				return val
			else:
				push_error("Variable '%s' is not a Vector2i" % pos_str)
				return Vector2i.ZERO
		else:
			push_error("Unknown variable: " + pos_str)
			return Vector2i.ZERO
			
func _parse_position(pos_str: String) -> Vector2i:
	pos_str = pos_str.to_lower()
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

func _is_centered(target: Variant) -> bool:
	var mouse = Globals.mouse_ref
	var target_pos: Vector2i
	if target is Vector2i:
		target_pos = target
	elif target is String:
		target_pos = _resolve_position(target)
	else:
		push_error("Invalid target passed to _is_centered(): " + str(target))
		return false

	var current_pos: Vector2 = mouse.global_position
	var center: Vector2 = mouse.get_cell_center(target_pos)
	var dist: float = current_pos.distance_to(center)

	if Globals.interpreter_debug_enabled:
		print_debug("Checking centeredness: pos=", current_pos, " target_center=", center, " dist=", dist)

	return dist < 10.0  # Adjust threshold if needed

func _compare_position(mode: String, target_pos: Vector2i) -> bool:
	var mouse = Globals.mouse_ref
	match mode:
		"if_facing", "while_facing":
			return mouse.is_facing_cell(target_pos)
		"if_on", "while_on":
			return mouse.get_current_cell() == target_pos
		_:
			push_error("Unknown position mode: " + mode)
			return false
