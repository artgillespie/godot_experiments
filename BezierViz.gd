extends Viz2D

@export var CONTROL_POINT_A: Vector2 = Vector2(-5, -2)
@export var CONTROL_POINT_B: Vector2 = Vector2(-3, 3)
@export var CONTROL_POINT_C: Vector2 = Vector2(3, 3)
@export var CONTROL_POINT_D: Vector2 = Vector2(5, -2)
@export var LINE_WIDTH: float = 0.25

@onready var ControlPointScene: PackedScene = load("res://control_point.tscn")
@onready var LineShaderMaterial: ShaderMaterial = load("res://line_shader_material.tres")

var time: float = 0.0

var _dragging_control_point: ControlPoint = null
var _curve_points: Array[Vector2] = []
var _function_points: Array[Vector2] = []
var _colors = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]
var animate: bool = false
@export var NUM_SEGMENTS: int = 10




func _ready():
	_add_control_point(CONTROL_POINT_A, 0, "A")
	_add_control_point(CONTROL_POINT_B, 1, "B")
	_add_control_point(CONTROL_POINT_C, 2, "C")
	_add_control_point(CONTROL_POINT_D, 3, "D")
	time = 0.0
	_curve_points.clear()
	
func _process(delta: float):
	time += 0.5 * delta
	if time > 1.0:
		_curve_points.clear()
		_function_points.clear()
		time = 0.0
	queue_redraw()
	
func _add_control_point(pt: Vector2, idx: int, name: String=""):
	var cp2 = ControlPointScene.instantiate()
	cp2.position = pt
	cp2.index = idx
	cp2.name = name
	cp2.connect("mouse_down", _on_mouse_down)	
	cp2.connect("mouse_up", _on_mouse_up)
	cp2.add_to_group("control_points")
	$ControlPoints.add_child(cp2)
	
func _quadratic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var t_1 = 1.0 - t
	var t_1_2 = t_1*t_1
	return p1 + t_1_2 * (p0 - p1) + t*t * (p2 - p1)

## so simple!
func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t_1 = 1.0 - t # (1 - t) term
	var t_1_2 = t_1*t_1 # (1 - t)^2 term
	var t_1_3 = t_1_2*t_1 # (1 - t)^3 term
	var t_2 = t*t # t^2 term
	var t_3 = t_2*t # t^3 term
	return t_1_3 * p0 + 3 * t_1_2 * t * p1 + 3 * t_1 * t_2 * p2 + t_3 * p3

func _draw_frame():
	var control_points = get_tree().get_nodes_in_group("control_points")
	var sort = func(a: ControlPoint, b: ControlPoint):
		return a.index < b.index
	control_points.sort_custom(sort)
	if animate:
		# draw lines between points
		var previous_pt: ControlPoint = null
		var previous_interp_pt: Vector2 = Vector2()
		var points: Array = control_points.map(func(x) -> Vector2: return x.position)
		
		for pt in _curve_points:
			draw_circle(pt, 0.25, Color.BLACK)
		for pt in _function_points:
			draw_circle(pt, 0.06, Color.AQUAMARINE)

		_draw_control_points(points)
		
		
		var bpt: Vector2 = _cubic_bezier(control_points[0].position, control_points[1].position, control_points[2].position, control_points[3].position, time)
		_function_points.push_back(bpt)
	else:
		var pts = control_points.map(func(x): return x.position) as Array[Vector2]
		var prev_pt = Vector2()
		# "linear tesselation"?
		var vertices: PackedVector2Array = PackedVector2Array()
		var uvs: PackedVector2Array = PackedVector2Array()
		for i in range(NUM_SEGMENTS+1):
			var t = i as float/NUM_SEGMENTS
			var pt = _cubic_bezier(pts[0], pts[1], pts[2], pts[3], t)
			if prev_pt == Vector2():
				prev_pt = pt
				continue
			# hrm, how do you get a perpendicular vector in 2D?
			var vec = pt-prev_pt;
			# the simplest! just swap components and negate! https://math.stackexchange.com/questions/137362/how-to-find-perpendicular-vector-to-another-vector#comment316390_137362
			var norm = Vector2(-vec.y, vec.x).normalized()
			var midpoint = lerp(prev_pt, pt, 0.5)
			## draw using the canvas item drawing method
			# draw_line(midpoint, midpoint+norm, Color.RED, 0.1)
			
			## draw triangles (wireframe) using canvas item drawing method
			# _draw_line_triangles(prev_pt, pt, Color.GREEN, LINE_WIDTH)
			
			## prepare mesh for rendering below
			_draw_line_mesh(prev_pt, pt, LINE_WIDTH, vertices, uvs)
			prev_pt = pt
		
		# render mesh
		var arrays = []
		arrays.resize(ArrayMesh.ARRAY_MAX)
		arrays[ArrayMesh.ARRAY_VERTEX] = vertices
		arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
		var mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, arrays)
		var idx = mesh.get_surface_count()
		$MeshInstance2D.material = LineShaderMaterial
		$MeshInstance2D.mesh = mesh
				
func _draw_control_points(points: Array, depth: int = 0):
	if points.size() == 1:
		_curve_points.push_back(points[0])
		draw_circle(points[0], 0.25, Color.RED)
		return
	var n = points.size() - 1
	var new_points = []
	for i in range(n):
		var cp_a = points[i]
		var cp_b = points[i+1]
		new_points.push_back(_draw_control_point_line(cp_a, cp_b, _colors[depth]))
	_draw_control_points(new_points, depth+1)
	
func _draw_line_triangles(pt_a: Vector2, pt_b: Vector2, color: Color, width: float = 0.25):
	# super-simple tesselation to quads
	var vec = pt_b - pt_a
	var norm = Vector2(-vec.y, vec.x).normalized()
	var vt_0 = pt_a + norm*width*0.5
	var vt_1 = pt_a - norm*width*0.5
	var vt_2 = pt_b + norm*width*0.5
	var vt_3 = pt_b - norm*width*0.5
	
	var line_w = 0.05
	
	# triangle one (note clockwise order)
	draw_line(vt_0, vt_3, color, line_w)
	draw_line(vt_3, vt_1, color, line_w)
	draw_line(vt_1, vt_0, color, line_w)
	
	# triangle two
	draw_line(vt_0, vt_2, color, line_w)
	draw_line(vt_2, vt_3, color, line_w)
	draw_line(vt_3, vt_0, color, line_w)
	
func _draw_line_mesh(pt_a: Vector2, pt_b: Vector2, width: float, vertices: PackedVector2Array, uvs: PackedVector2Array):

	var vec = pt_b - pt_a
	var norm = Vector2(-vec.y, vec.x).normalized()
	var vt_0 = pt_a + norm*width*0.5
	var vt_1 = pt_a - norm*width*0.5
	var vt_2 = pt_b + norm*width*0.5
	var vt_3 = pt_b - norm*width*0.5
	
	var line_w = 0.05
	
	# triangle one (note clockwise order)
	vertices.push_back(vt_0)
	uvs.push_back(Vector2(0.0, 0.0))
	vertices.push_back(vt_3)
	uvs.push_back(Vector2(1.0, 1.0))
	vertices.push_back(vt_1)
	uvs.push_back(Vector2(0.0, 1.0))
	
	vertices.push_back(vt_0)
	uvs.push_back(Vector2(0.0, 0.0))
	vertices.push_back(vt_2)
	uvs.push_back(Vector2(1.0, 0.0))
	vertices.push_back(vt_3)	
	uvs.push_back(Vector2(1.0, 1.0))
	
func _draw_control_point_line(pt_a: Vector2, pt_b: Vector2, color: Color = Color.MEDIUM_PURPLE) -> Vector2:
	draw_line(pt_a, pt_b, color)
	draw_circle(pt_a, 0.25, color)
	draw_circle(pt_b, 0.25, color)
	return lerp(pt_a, pt_b, time)
		
func _draw_mesh_interpolation(control_points: Array[ControlPoint]):
	# neat "mesh viz
	# draw interpolated curve lines
	var pt_a = control_points[0].position
	var pt_b = control_points[1].position
	var pt_c = control_points[2].position
	var pt_d = control_points[3].position	
	for i in range(10):
		var l_a = lerp(pt_a, pt_b, i/10.0)
		var l_b = lerp(pt_b, pt_c, i/10.0)
		var l_c = lerp(pt_c, pt_d, i/10.0)
		draw_line(l_a, l_b, Color.AQUA)
		draw_line(l_b, l_c, Color.AQUA)

func _on_mouse_down(cp: ControlPoint):
	_dragging_control_point = cp
	
func _on_mouse_up(cp: ControlPoint):
	_dragging_control_point = null

func _input(e: InputEvent):
	if e is InputEventMouseMotion and _dragging_control_point != null:
		e = make_input_local(e)
		_dragging_control_point.position = e.position
		time = 0.0
		_curve_points.clear()
		_function_points.clear()
