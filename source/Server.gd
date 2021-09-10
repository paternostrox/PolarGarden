extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

signal server_populate(garden_data)
signal server_add(plant_data, pos)
signal server_remove(pos)

#func _ready():
#    connect_to_server()

func connect_to_server():
    network.create_client(ip, port)
    get_tree().set_network_peer(network)

    network.connect("connection_succeeded", self, "on_connection_succeeded")
    network.connect("connection_failed", self, "on_connection_failed")

func on_connection_succeeded():
    print("Successfully connected!")
    rpc_id(1, "serve_join", get_instance_id())

func on_connection_failed():
    print("Failed to connect!")

func grid_interact(requester, pos: Vector3):
    rpc_id(1, "serve_interaction", requester, pos)

remote func return_garden(requester, jgarden):
    var p = JSON.parse(jgarden)
    if typeof(p.result) == TYPE_ARRAY:
        emit_signal("server_populate", p.result)
    else:
        push_error("Parse error. Unexpected type.")

remote func return_add(requester, jplant_data, pos: Vector3):
    var p = JSON.parse(jplant_data)
    if typeof(p.result) == TYPE_ARRAY:
        emit_signal("server_add", p.result, pos)
    else:
        push_error("Parse error. Unexpected type.")

remote func return_remove(requester, pos: Vector3):
    emit_signal("server_remove", pos)
    print("FIRED");

