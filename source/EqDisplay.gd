extends VBoxContainer

export(NodePath) var grid_path

export(PackedScene) var eq_label

var labels = []

func _ready():
	var grid = get_node(grid_path)
	grid.connect("plant_added", self, "display_eq")

func display_eq(var plant_data):
	
	var dif = (plant_data.size() / 5) - labels.size()

	for i in range(dif):
		var label = eq_label.instance()
		add_child(label)
		labels.append(label)

	for i in range(labels.size()-1,-dif-1,-1):
		labels[i].visible = false

	labels[0].visible = true
	labels[0].text = "STALK EQ: " + plant_data[0] + " | len = " + str(plant_data[1])
	for i in range(5, plant_data.size(), 5): # think about making plant-part size (5) global
		labels[i/5].visible = true
		labels[i/5].text = "HEAD(%d) EQ: " % (i/5) + plant_data[i] + " | len = " + str(plant_data[i+1])

