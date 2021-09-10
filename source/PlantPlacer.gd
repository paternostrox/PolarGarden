extends Camera

signal grid_interaction(requester, pos)

var from
var to
var clicked = false

const ray_length = 100000

func _ready():
	connect("grid_interaction", Server, "grid_interact")

func _input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		  from = project_ray_origin(event.position)
		  to = from + project_ray_normal(event.position) * ray_length
		  clicked = true

func _physics_process(_delta):
	if clicked:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		if result:
			#print(result.position)
			emit_signal("grid_interaction", get_instance_id(), result.position)
		clicked = false
