extends Node

var player_number

var grid_width : int = 40 # in units
var grid_depth : int = 40 # in units
var cell_size : float = 1 # in meters

func world2grid(pos):
	pos.x += GameVars.grid_width/2
	pos.z += GameVars.grid_depth/2
	var x = clamp(floor(pos.x), 0, GameVars.grid_width)
	var z = clamp(floor(pos.z), 0, GameVars.grid_depth)
	var gridpos = Vector3(x,0,z)
	return gridpos

func grid2world(pos, y):
    pos.x -= GameVars.grid_width/2
    pos.z -= GameVars.grid_depth/2
    var worldpos = Vector3(pos.x + cell_size/2,y,pos.z + cell_size/2)
    return worldpos