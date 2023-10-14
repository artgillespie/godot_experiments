class_name Viz2D

extends Node2D

@export var GRID_COLOR: Color = Color.DIM_GRAY
@export var GRID_SPACING: int = 32

var _scale: Vector2
var _size: Vector2
var _origin: Vector2
var _min: Vector2
var _max: Vector2

var _mouse_coords: Vector2
var _tx_stack: Array[Transform2D]

var rot: float = 0.0
var _dist: float = 0.0
var _current_pos: Vector2 = Vector2()
var _tx: Transform2D

@onready var label = $CanvasLayer/VBoxContainer/MarginContainer/Label

# Called when the node enters the scene tree for the first time.
func _ready():
	_origin = Vector2(0, 0)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rot += 20*delta
	label.text = "x: %.1f y: %.1f\nd: %.2f\n%.1f, %.1f\n%.1f, %.1f\n%.1f, %.1f" % \
		[_current_pos.x, _current_pos.y, _dist, _tx.x.x, 
		 _tx.x.y, _tx.y.x, _tx.y.y, _tx.origin.x, _tx.origin.y]
	queue_redraw()
	
func push(tx: Transform2D):
	"""make tx the current transform"""
	_tx_stack.push_back(tx)
	draw_set_transform_matrix(tx)
	
func pop() -> Transform2D:
	var tx = _tx_stack.pop_back()
	draw_set_transform_matrix(tx)
	return tx

func draw_grid():
	for i in range(_min.x, _max.x):
		draw_line(Vector2(i, _min.y), Vector2(i, _max.y), GRID_COLOR)
	for i in range(_min.y, _max.y):
		draw_line(Vector2(_min.x, i), Vector2(_max.x, i), GRID_COLOR)

func draw_axes():
	draw_line(Vector2(_min.x, _origin.y), Vector2(_max.x, _origin.y), Color.RED)
	draw_line(Vector2(_origin.x, _min.y), Vector2(_origin.x, _max.y), Color.GREEN)

func draw_mouse():
	draw_rect(Rect2(_mouse_coords.x-0.25, _mouse_coords.y-0.25, .5, .5), Color.AQUA)

func _draw_frame():
	# draw the thing we're rotating around
	var pt_a = Vector2(2,2)
	draw_rect(Rect2(pt_a.x-0.5, pt_a.y-0.5, 1, 1), Color.BLUE)
	
	# draw the thing we're rotating
	_dist = pt_a.distance_to(_current_pos)
	# current pos
	
	# 1 0 4
	# 0 1 4
	_tx = Transform2D(0, Vector2(4, 4))
	# translate to point of interest
	#
	# 1 0 2
	# 0 1 2
	_tx = _tx.translated_local(-pt_a)
	
	#
	# cos(rot) -sin(rot) 2
	# sin(rot) cos(rot) 2
	#
	_tx = _tx.rotated_local(deg_to_rad(rot))
	_tx = _tx.translated_local(Vector2(_dist, 0))
	_current_pos = _tx.origin
	push(_tx)
	draw_rect(Rect2(-0.5, -0.5, 1, 1), Color.GREEN_YELLOW)
	pop()

func _draw():
	var view_size = get_viewport_rect().size
	_scale = Vector2(GRID_SPACING, -GRID_SPACING)
	_size = ceil(view_size / _scale)
	var _tx = floor(Vector2(view_size.x / 2, view_size.y / 2))
	_min = Vector2(-_tx.x, -_tx.y)
	_max = Vector2(_tx.x, _tx.y)
	var tx = Transform2D()
	tx = tx.scaled(_scale)
	tx = tx.translated(_tx)
	transform = tx
	draw_grid()
	draw_axes()
	draw_mouse()
	_draw_frame()

func _input(e: InputEvent):
	if e is InputEventMouseMotion:
		e = make_input_local(e)
		_mouse_coords = e.position
		queue_redraw()
