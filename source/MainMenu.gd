extends Node

func load_game():
    get_tree().change_scene("res://scenes/Game.tscn")

func exit_game():
    get_tree().quit()