extends Camera

export(NodePath) var grid_path
signal ground_interaction(pos)

var from
var to
var clicked = false

const ray_length = 100000

func _ready():
	var grid = get_node(grid_path)
	connect("ground_interaction", grid, "interact")

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
			print(result.position)
			emit_signal("ground_interaction", result.position)
		clicked = false
