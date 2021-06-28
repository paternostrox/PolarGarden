extends MeshInstance

export(PackedScene) var plant_scene;

var grid_width : int = 10 # in units
var grid_height : int = 10 # in units
var ground_height : int = 1 # in meters
var cell_size : float = 1 # in meters
var grid = []

var offset: Vector3 = Vector3.ZERO

func _ready():
	create_grid()

func create_grid():
	# make ground geometry
	var cube_mesh = CubeMesh.new()
	cube_mesh.size = Vector3(grid_width*cell_size, ground_height, grid_height*cell_size)
	mesh = cube_mesh
	create_convex_collision() # not ideal but ok

	# make grid matrix
	for x in range(grid_width):
		grid.append([])
		for _y in range(grid_height):
			grid[x].append(-1)

	var offset_x = global_transform.origin.x - grid_width/2.0
	var offset_z = global_transform.origin.z - grid_height/2.0
	offset = Vector3(offset_x, 0, offset_z)
	
func interact(var pos: Vector3):
	var fixed_pos = pos - offset
	var x = clamp(floor(fixed_pos.x), 0, grid_width-1)
	var z = clamp(floor(fixed_pos.z), 0, grid_height-1)

	var index = grid[x][z]
	if index == -1:
		add_plant(x,z)
	else:
		remove_plant(x,z)

func add_plant(var x: int, var z: int):
	var new_plant = plant_scene.instance()
	new_plant.global_transform.origin = Vector3(x*cell_size, ground_height/2.0, z*cell_size)
	add_child(new_plant)
	grid[x][z] = new_plant.get_index()

func remove_plant(var x: int, var z: int):
	var index = grid[x][z]
	get_child(index).queue_free()
	grid[x][z] = -1
	
