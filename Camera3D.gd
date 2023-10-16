extends Camera3D
## First attempt at an Orbital 3D Camera
##
## Set [code]poi[/code] (position of interest) to point the camera at it
## and orbit around it. Left-clicking and dragging left to right will orbit
## the point of interest around the y axis. Left-clicking and dragging up and
## down will orbit the point of interest around the x axis. Using the mousewheel
## or a two-fingered swipe vertically on the trackpad will increase/decrease
## the distance between the camera and the point of interest. (i.e., "zoom")
##
## TODO: animate setting the point of interest
##

## Point of interest
@export var poi = Vector3(0, 0, 0):
	set = _set_poi

## Orbital rotation in radians
@export var orbital_rotation = Vector2(0,0):
	get = _get_orbital_rotation, set = _set_orbital_rotation
	
## Distance from the point of interest
@export var DISTANCE: float = 4.0

func _ready():
	orbital_rotation.x = rotation.x
	orbital_rotation.y = rotation.y

func _set_poi(v: Vector3):
	poi = v
	# TODO: Tween Me
	look_at(poi)
	_update_tx()

func _get_orbital_rotation() -> Vector2:
	# return rad_to_deg(acos(Vector2(position.x, position.z).normalized().dot(Vector2(poi.x, poi.z))))
	return orbital_rotation
	
func _set_orbital_rotation(v: Vector2):
	orbital_rotation = v
	_update_tx()
	
func _update_tx():
	# make the point of interest the origin
	var tx = Transform3D(Basis(), poi)
	# rotate in local space (i.e., the point-of-interest's coordinate space)
	tx = tx.rotated_local(Vector3(0.0, 1.0, 0.0), orbital_rotation.x)
	tx = tx.rotated_local(Vector3(1.0, 0.0, 0.0), orbital_rotation.y)
	# translate back from the point of interest by DISTANCE, respecting
	# our local rotation
	tx = tx.translated_local(Vector3(0,0,DISTANCE))
	transform = tx

func _input(e: InputEvent):
	if e is InputEventMouseButton:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			DISTANCE -= 0.5
			_update_tx()
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			DISTANCE += 0.5
			_update_tx()
		return
	if e is InputEventPanGesture:
		e = e as InputEventPanGesture
		DISTANCE += e.delta.y/2
		_update_tx()
		return
	if e is InputEventMouseMotion:
		e = e as InputEventMouseMotion
		if e.button_mask & MOUSE_BUTTON_MASK_LEFT:
			orbital_rotation -= e.relative / 100.0
		return
		
	

