# res://scripts/progress_io.gd
extends Object
class_name ProgressIO

const PROGRESS_FILE := "user://campaign_progress.json"

static func load_into_globals() -> void:
	if not FileAccess.file_exists(PROGRESS_FILE):
		return
	var f := FileAccess.open(PROGRESS_FILE, FileAccess.READ)
	if f == null:
		push_error("Cannot open %s for read" % PROGRESS_FILE)
		return
	var txt := f.get_as_text()
	f.close()

	# Godot 4: returns Variant (Dictionary/Array) or null on failure
	var obj = JSON.parse_string(txt)
	if typeof(obj) != TYPE_DICTIONARY:
		push_error("Invalid JSON in %s" % PROGRESS_FILE)
		return

	if obj.has("campaign_results") and typeof(obj["campaign_results"]) == TYPE_DICTIONARY:
		Globals.campaign_results.clear()
		for k in obj["campaign_results"].keys():
			Globals.campaign_results[int(k)] = float(obj["campaign_results"][k])

static func save_from_globals() -> void:
	print("saving to" + OS.get_user_data_dir())
	var out: Dictionary = {}
	for k in Globals.campaign_results.keys():
		out[str(k)] = Globals.campaign_results[k]

	var payload := { "campaign_results": out }

	var f := FileAccess.open(PROGRESS_FILE, FileAccess.WRITE)
	if f == null:
		push_error("Cannot open %s for write" % PROGRESS_FILE)
		return
	# Godot 4: stringify, not print
	f.store_string(JSON.stringify(payload))
	f.close()

static func record(level_num: int, seconds: float, keep_best := true) -> void:
	if keep_best and level_num in Globals.campaign_results:
		Globals.campaign_results[level_num] = min(Globals.campaign_results[level_num], seconds)
	else:
		Globals.campaign_results[level_num] = seconds
	save_from_globals()
