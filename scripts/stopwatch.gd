extends Label

var time_elapsed := 0.0
var is_stopped := true      # start “stopped” so the first start() will reset

func _ready():
	set_process(true)       # ensure _process is called

func _process(delta: float) -> void:
	if not is_stopped:
		time_elapsed += delta

func start() -> void:
	# ALWAYS reset, not just when is_stopped == true
	time_elapsed = 0.0
	is_stopped = false
	self.text = "0.00 seconds"
		
func stop() -> void:
	is_stopped = true
	self.text = str(time_elapsed).pad_decimals(2) + " seconds"
