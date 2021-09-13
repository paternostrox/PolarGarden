extends Node

var grid_width : int = 20 # in units
var grid_depth : int = 20 # in units
var cell_size : float = 1 # in meters

func world2grid(var pos: Vector3):
    var x = clamp(floor(pos.x), 0, GameVars.grid_width-1)
    var z = clamp(floor(pos.z), 0, GameVars.grid_depth-1)
    return Vector3(x,0,z)

func grid2world(var pos: Vector3, var y: float):
    return Vector3(pos.x*cell_size + cell_size/2.0, y, pos.z*cell_size + cell_size/2.0)