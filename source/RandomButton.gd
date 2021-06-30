extends Button

export(NodePath) var garden_path

func _ready():
	var plant = get_node(garden_path)
	connect("button_down", plant, "randomize")
