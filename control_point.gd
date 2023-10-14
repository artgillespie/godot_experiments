class_name ControlPoint
extends Node2D

signal mouse_entered(which:ControlPoint)
signal mouse_exited(which:ControlPoint)
signal mouse_down(which:ControlPoint)
signal mouse_up(which:ControlPoint)

@export var size: Vector2 = Vector2(0.5, 0.5)
@export var index: int = 0
var is_mouse_over: bool = false
@onready var _default_font: Font = ThemeDB.fallback_font
@onready var _default_font_size: int = ThemeDB.fallback_font_size

func _ready():
	$CanvasLayer/Label.text = name

func _draw():
	var color = Color.RED if is_mouse_over else Color.WHITE
	draw_rect(Rect2(-size.x/2, -size.y/2, size.x, size.y), color)
	draw_rect(Rect2(-size.x/2, -size.y/2, size.x, size.y), Color.BLACK, false, 0.1)
	draw_set_transform(Vector2(0,0), 0.0, Vector2(1/32., -1/32.))
	draw_string(_default_font, Vector2(-40, 0.0), name, HORIZONTAL_ALIGNMENT_LEFT, -1, 32)
	draw_set_transform(Vector2(0,0), 0.0, Vector2(32., -32.))

func _on_area_2d_mouse_entered():
	is_mouse_over = true
	emit_signal("mouse_entered", self)
	queue_redraw()

func _on_area_2d_mouse_exited():
	is_mouse_over = false
	emit_signal("mouse_exited", self)
	queue_redraw()

func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton:
		if event.is_pressed():
			emit_signal("mouse_down", self)
		else:
			emit_signal("mouse_up", self)
