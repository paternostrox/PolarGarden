extends VBoxContainer

export(NodePath) var grid_path

func _ready():
	var grid = get_node(grid_path)
	grid.connect("flower_added", self, "display_eq")

func display_eq(var strings):
	var prefixes = ["stalk eq: ", "stalk dstrb: ", "flower eq: "]
	var labels = get_children()
	for i in range(labels.size()):
		labels[i].text = prefixes[i] + strings[i]
