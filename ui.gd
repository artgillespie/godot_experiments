extends Control

@onready var fps_label: Label = $MarginContainer/VBoxContainer/FPSLabel
@onready var draw_calls_label: Label = $MarginContainer/VBoxContainer/DrawCallsLabel
# @onready var perf = Performance.new()

func _process(delta):
	fps_label.text = "FPS: %.1f" % Engine.get_frames_per_second()
	draw_calls_label.text = "Draw Calls: %d" % Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var camera = get_viewport().get_camera_3d()
		
	
