extends Node3D	

const count = 16

func _ready():
		
	$Camera3D.poi = $Cube.position
	$Camera3D.look_at($Cube.position)

func _on_area_3d_input_event(camera, event, position, normal, shape_idx):
	var colors: Array[Color] = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW, Color.CHOCOLATE, Color.BISQUE, Color.AQUA]
	if event is InputEventMouseButton and event.is_pressed() and event.shift_pressed:
		# place a cube
		var mesh = BoxMesh.new()
		var material = StandardMaterial3D.new()
		material.albedo_color = colors.pick_random()
		mesh.material = material
		var inst = MeshInstance3D.new()
		inst.position = position
		inst.position.y = 0.5
		inst.mesh = mesh
		add_child(inst)
		$Camera3D.poi = inst.position
