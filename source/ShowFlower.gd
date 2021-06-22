extends Button

export(NodePath) var plant_path

func _ready():
	var plant = get_node(plant_path)
	connect("button_down", plant, "toggle_visible")
