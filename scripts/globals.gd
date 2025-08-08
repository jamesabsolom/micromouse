# res://scripts/globals.gd
extends Node

## DEBUG SETTINGS ##
var interpreter_debug_enabled := false
var debug_enabled := false
var sensor_debug := false
var print_parse_tree = false

## MOUSE SETTINGS ##
var move_speed := 5
var move_delay := 0.001
var turn_delay := 0.01
var repeat_delay := 0

## GLOBAL VARIABLES ##
var mouse_ref = null
var campaign_completed = []
var incomplete_color = Color8(220, 0, 1, 255)
var complete_color = Color8(41, 176, 111, 255)
var campaign_level = ""
var campaign_level_num = 0
