extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

func _ready():
    connect_to_server()

func connect_to_server():
    network.create_client(ip, port)
    get_tree().set_network_peer(network)

    network.connect("connection_succeeded", self, "on_connection_succeeded")
    network.connect("connection_failed", self, "on_connection_failed")

func on_connection_succeeded():
    print("Successfully connected!")

func on_connection_failed():
    print("Failed to connect!")

func request_plant(requester, pos: Vector3):
    rpc_id(1, "serve_plant", requester, pos)

remote func return_plant(requester, plant_data: PlantData ,pos: Vector3):
    # Build plant on pos
    pass

