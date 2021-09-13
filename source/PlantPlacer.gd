extends Camera

export(NodePath) var selection_path

signal grid_interaction(requester, pos)
signal plant_crossing(requester, parents_poss, pos)

var from
var to
var clicked_left = false
var clicked_right = false

const ray_length = 100000

var selection

func _ready():
	selection = get_node(selection_path)
	connect("grid_interaction", Server, "grid_interact")
	connect("plant_crossing", Server, "grid_cross")

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
				emit_signal("", get_instance_id(), selection.get_positions(),result.position)
				selection.deselect()
			else:
				emit_signal("grid_interaction", get_instance_id(), result.position)
		clicked_left = false
		
	if clicked_right:
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(from, to)
		if result:
			#print(result.position)
			selection.select(result.position)
		clicked_right = false
