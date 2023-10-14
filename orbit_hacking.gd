extends Node3D

@onready var ocube: MeshInstance3D = $OrbitingCube
@onready var fcube: MeshInstance3D = $Cube
var _rotation: float = 0.0
var _rotation_amt: float = 0.0
@onready var _base_tx: Transform3D = ocube.transform
# Called when the node enters the scene tree for the first time.
@export var DISTANCE: float = 0.0

func _ready():
	_rotation_amt = PI/2
	# ocube.look_at(fcube.position)
	DISTANCE = ocube.position.distance_to(fcube.position)
	_rotation = ocube.position.normalized().dot(fcube.position.normalized())

# If you make a Node3D a child of another Node3D, rotation will take place around
# the parent
func _process(delta):
	_rotation += _rotation_amt * delta
	_rotation = wrap(_rotation, 0., PI*2)

	var tx = Transform3D(Basis(), fcube.position)
	tx = tx.rotated_local(Vector3(0,1,0), _rotation);
	tx = tx.translated_local(Vector3(0,0,DISTANCE))
	ocube.transform = tx
	
