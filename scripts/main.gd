extends Node2D

func _ready():
	randomize()

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		$UI/MousePos.text = str(get_global_mouse_position()) \
			+ "\nAactive Tile: " \
			+ str($HexGrid.active)