extends Spatial

# Control variables
export var maxPitch : float = 45
export var minPitch : float = -45
export var maxZoom : float = 20
export var minZoom : float = 4
export var zoomStep : float = 2
export var zoomYStep : float = 0.15
export var verticalSensitivity : float = 0.002
export var horizontalSensitivity : float = 0.002
export var camYOffset : float = 4.0
export var camLerpSpeed : float = 16.0
export(NodePath) var target

# Private variables
var _camTarget : Spatial = null
var _cam : Camera
var _curZoom : float = 0.0
var drag = false

func _ready() -> void:
	# Setup node references
	_camTarget = get_node(target)
	_cam = get_node("Camera")
	
	# Setup camera position in rig
	_cam.translate(Vector3(0,camYOffset,maxZoom))
	_curZoom = maxZoom

func _input(event) -> void:
		
	if event is InputEventMouseButton:
		# Change zoom level on mouse wheel rotation
		if event.is_pressed():
			if event.button_index == BUTTON_MIDDLE:
				drag = true
			if event.button_index == BUTTON_WHEEL_UP and _curZoom > minZoom:
				_curZoom -= zoomStep
				camYOffset -= zoomYStep
			if event.button_index == BUTTON_WHEEL_DOWN and _curZoom < maxZoom:
				_curZoom += zoomStep
				camYOffset += zoomYStep
		else:
			drag = false

	# Camera Rotation (Mouse Wheel)
	if event is InputEventMouseMotion and drag:
		# Rotate the rig around the target
		rotate_y(-event.relative.x * horizontalSensitivity)
		rotation.x = clamp(rotation.x - event.relative.y * verticalSensitivity, deg2rad(minPitch), deg2rad(maxPitch))
		orthonormalize()
	
	# Camera Movement (W,A,S,D)
	if event is InputEventKey:
		if event.pressed:
			var dir: Vector3
			if event.scancode == KEY_W:
				dir = global_transform.basis.xform(Vector3.FORWARD)
			elif event.scancode == KEY_S:
				dir = global_transform.basis.xform(Vector3.BACK)
			elif event.scancode == KEY_D:
				dir = global_transform.basis.xform(Vector3.RIGHT)
			elif event.scancode == KEY_A:
				dir = global_transform.basis.xform(Vector3.LEFT)
			else:
				return
			dir = Vector3(dir.x,0,dir.z)
			dir = dir.normalized()
			_camTarget.global_translate(dir)

func _process(delta) -> void:
	# zoom the camera accordingly
	_cam.set_translation(_cam.translation.linear_interpolate(Vector3(0,camYOffset,_curZoom),delta * camLerpSpeed))
	# set the position of the rig to follow the target
	set_translation(_camTarget.global_transform.origin)
