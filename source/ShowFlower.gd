extends Button

export(int) var plant_index 

export(NodePath) var plant_path

func _ready():
    var plant = get_node(plant_path)
    connect("button_down", plant, "toggle_plant", [plant_index])