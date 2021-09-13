extends Camera

export(NodePath) var selection_path
export(NodePath) var garden_grid_path

signal grid_interaction(requester, pos)
#signal try_crossing(parents_poss, pos)

var from
var to
var clicked_left = false
var clicked_right = false

const ray_length = 100000

var selection
var garden_grid

func _ready():
	garden_grid = get_node(garden_grid_path)
	selection = get_node(selection_path)
	connect("grid_interaction", Server, "grid_interact")
	#connect("try_crossing", garden_grid, "try_cross")

func _input(event):
	if event is InputEventMouseButton and event.pressed:
		from = project_ray_origin(event.position)
		to = from + project_ray_normal(event.position) * ray_length
		if event.button_index == 1:
			clicked_left = true
		if event.button_index == 2:
			clicked_right = true


func _physics_process(_delta):
	if clicked_left:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		if result:
			if(selection.get_selected_amount() > 1):
				garden_grid.try_cross(selection.get_positions(),result.position)
				selection.deselect()
			else:
				emit_signal("grid_interaction", get_instance_id(), result.position)
		clicked_left = false
		
	if clicked_right:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		if result:
			if(garden_grid.check_plant(result.position)):
				selection.select(result.position)
		clicked_right = false
