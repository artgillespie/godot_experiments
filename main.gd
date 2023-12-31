extends Node3D	

const count = 16

var A = Vector3(-0.5, 0.5, 0.5) # x, y, d
var B = Vector3(0.5, 0.5, 0.5) # -1, 1, d
var C = Vector3(-0.5, -0.5, 0.5) # -1, -1, d
var D = Vector3(0.5, -0.5, 0.5) # -1, 1, d
var E = Vector3(0.5, 0.5, -0.5) # B * (1,1,-1)
var F = Vector3(-0.5, 0.5, -0.5) # A * (1,1,-1)
var G = Vector3(0.5, -0.5, -0.5) # D * (1,1,-1)
var H = Vector3(-0.5, -0.5, -0.5) # C * (1,1,-1)

var FRONT_FACE = [A,D,C,A,B,D]
var BACK_FACE = [E,H,G,E,F,H]
var BOTTOM_FACE = [C,G,H,C,D,G]
var TOP_FACE = [F,B,A,F,E,B]
var LEFT_FACE = [F,C,H,F,A,C]
var RIGHT_FACE = [B,G,D,B,E,G]

var FRONT_NORMAL = Vector3(0,0,1)
var BACK_NORMAL = Vector3(0,0,-1)
var BOTTOM_NORMAL = Vector3(0,-1,0)
var TOP_NORMAL = Vector3(0,1,0)
var LEFT_NORMAL = Vector3(-1,0,0)
var RIGHT_NORMAL = Vector3(1,0,0)

## triangle 1: upper left, bottom right, bottom left (e.g., ADC)
## triangle 2: upper left, top right, bottom left (e.g., ABD)
var UVS = [Vector2(0,0), Vector2(1,1), Vector2(0,1), Vector2(0,0), Vector2(1,0), Vector2(1,1)]

##
##    F--------E
##   /|        /|
##  / |       / |
##  A H------B-G
##  | /      | /
##  |/       |/
##  C--------D
##

var VOXEL_GRID_SIZE: int = 16
var voxel_grid: Array = []

@onready var ray = $RayCast3D

class HitTestResult:
	var hit: bool
	var where: Vector3

func _init():
	voxel_grid.clear()
	voxel_grid.resize(VOXEL_GRID_SIZE*VOXEL_GRID_SIZE*VOXEL_GRID_SIZE)
	fill_grid(true)
	set_voxel(0,0, 0, false)
	set_voxel(0,1,0,false)
	set_voxel(0,15, 0, false)
	set_voxel(15,15, 0, false)

func _ready():
	$OrbitalCamera.poi = Vector3(0,0,0)
	var mesh_instance = _make_mesh()
	mesh_instance.position = Vector3(0,1,0)
	$Procedural.add_child(mesh_instance)

	voxel_grid.clear()
	voxel_grid.resize(VOXEL_GRID_SIZE*VOXEL_GRID_SIZE*VOXEL_GRID_SIZE)
	fill_grid(true)
	set_voxel(0,0, 0, false)
	
func fill_grid(v: bool):
	for i in range(VOXEL_GRID_SIZE):
		for j in range(VOXEL_GRID_SIZE):
			for k in range(VOXEL_GRID_SIZE):
				set_voxel(i,j,k,v)

func set_voxel(i:int,j:int,k:int,v:bool):
	voxel_grid[i+j*VOXEL_GRID_SIZE+k*VOXEL_GRID_SIZE*VOXEL_GRID_SIZE] = v

func voxel_at(i:int,j:int,k:int) -> bool:
	if i < 0 or j < 0 or k < 0 or i >= VOXEL_GRID_SIZE or j >= VOXEL_GRID_SIZE or k >= VOXEL_GRID_SIZE:
		return false
	return voxel_grid[i+j*VOXEL_GRID_SIZE+k*VOXEL_GRID_SIZE*VOXEL_GRID_SIZE]

func _make_mesh() -> MeshInstance3D:
	
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	var mesh = ArrayMesh.new()
	
	var vertices = PackedVector3Array()
	var indices = PackedInt32Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	# arrays[ArrayMesh.ARRAY_INDEX] = indices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	arrays[ArrayMesh.ARRAY_TEX_UV] = uvs
	for i in range(VOXEL_GRID_SIZE):
		for j in range(VOXEL_GRID_SIZE):
			for k in range(VOXEL_GRID_SIZE):
				if not voxel_at(i,j,k):
					continue
				var pos = Vector3(i,j,k)
				## no voxel in front of this voxel?
				if k == 0 or not voxel_at(i,j,k+1):
					_make_face(pos, FRONT_FACE, FRONT_NORMAL, vertices, indices, normals, uvs)
				## no voxel behind this voxel?
				if k == VOXEL_GRID_SIZE-1 or not voxel_at(i,j,k-1):
					_make_face(pos, BACK_FACE, BACK_NORMAL, vertices, indices, normals, uvs)
				if j == 0 or not voxel_at(i,j-1,k):
					_make_face(pos, BOTTOM_FACE, BOTTOM_NORMAL, vertices, indices, normals, uvs)
				if j == VOXEL_GRID_SIZE-1 or not voxel_at(i,j-1,k):
					_make_face(pos, TOP_FACE, TOP_NORMAL, vertices, indices, normals, uvs)
				if k == 0 or not voxel_at(i-1,j,k):
					_make_face(pos, LEFT_FACE, LEFT_NORMAL, vertices, indices, normals, uvs)
				if k == VOXEL_GRID_SIZE-1 or not voxel_at(i+1,j,k):
					_make_face(pos, RIGHT_FACE, RIGHT_NORMAL, vertices, indices, normals, uvs)
	
	mesh.add_surface_from_arrays(ArrayMesh.PRIMITIVE_TRIANGLES, arrays)

	print(mesh.get_surface_count())
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	return instance

func _make_face(pos, face, normal, vertices: PackedVector3Array, indices: PackedInt32Array, normals: PackedVector3Array, uvs: PackedVector2Array):
	for i in range(6):
		vertices.push_back(face[i]+pos)
		normals.push_back(normal)
		uvs.push_back(UVS[i])

func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	# called when a mouse click "hits" the floor
	pass
	
func intersects(ray_origin: Vector3, ray_norm: Vector3, inv_norm: Vector3) -> HitTestResult:
	var tmin = -INF
	var tmax = INF
	
	var tx1 = (0.0 - ray_origin.x) * inv_norm.x
	var tx2 = (VOXEL_GRID_SIZE - ray_origin.x) * inv_norm.x
	tmin = max(tmin, min(tx1, tx2))
	tmax = min(tmax, max(tx1, tx2))

	tx1 = (0.0 - ray_origin.y) * inv_norm.y
	tx2 = (VOXEL_GRID_SIZE - ray_origin.y) * inv_norm.y
	tmin = max(tmin, min(tx1, tx2))
	tmax = min(tmax, max(tx1, tx2))	
	
	tx1 = (0.0 - ray_origin.z) * inv_norm.z
	tx2 = (VOXEL_GRID_SIZE - ray_origin.z) * inv_norm.z
	tmin = max(tmin, min(tx1, tx2))
	tmax = min(tmax, max(tx1, tx2))	

	var result = HitTestResult.new()
	result.hit = tmax >= tmin
	if result.hit:
		result.where = ray_origin + ray_norm * tmin
	else:
		result.where = Vector3()
	return result

func _input(evt: InputEvent):
	if evt is InputEventMouseButton:
		if evt.is_pressed() and evt.shift_pressed:
			# cast a ray into the scene and see if it's hitting our mesh
			var cam = $OrbitalCamera
			var mousepos = get_viewport().get_mouse_position()
	
			var origin = cam.project_ray_origin(mousepos)
			var end = origin + cam.project_ray_normal(mousepos) * 1000

			var normal = cam.project_ray_normal(mousepos)
			var inv_normal = normal.inverse()
			ray.transform.origin = origin
			ray.target_position = end
			var hit = intersects(origin, normal, inv_normal)
			print("intersects: ", hit.hit, ", ", hit.where)
			if hit.hit:
				$RaySphereViz.visible = true
				$RaySphereViz.position = hit.where - normal * 0.5
			else:
				$RaySphereViz.visible = false
				
				
			
			
						
			
		
