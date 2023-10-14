extends Node3D	

const count = 16

func _ready():
	
#	for i in range(count):
#		for j in range (count):
#			for k in range (count):
#					var mesh_instance = MeshInstance3D.new()
#					var mesh: ArrayMesh = ArrayMesh.new()
#					mesh_instance.mesh = mesh
#
#					# by default, lying flat on the x and z axis
#					var box_geometry: BoxMesh = BoxMesh.new()
#					mesh_instance.position = Vector3(-count/2.*1.0 + j*1.0, 0.5 + k*1.0, count/2.*1.0 - i*1.0)
#					mesh_instance.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, box_geometry.get_mesh_arrays())
#
#					$Procedural.add_child(mesh_instance)
		
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
