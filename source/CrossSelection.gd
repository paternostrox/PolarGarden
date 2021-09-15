extends Node

export(PackedScene) var selection_aura

export var max_selection = 4
var selected_amount = 0
var auras = []

func _ready():
	for i in range(max_selection):
		var aura = selection_aura.instance()
		aura.visible = false
		add_child(aura)
		auras.append(aura)

func select(pos: Vector3):
	if(selected_amount < max_selection):
		auras[selected_amount].transform.origin = GameVars.grid2world(GameVars.world2grid(pos),0.0001)
		auras[selected_amount].visible = true
		selected_amount += 1
	else:
		deselect()

func deselect():
	for i in range(max_selection):
		auras[i].visible = false
	selected_amount = 0

func get_positions():
	var poss = []
	for i in range(selected_amount):
		poss.append(auras[i].transform.origin)
	return poss

func get_selected_amount():
	return selected_amount
