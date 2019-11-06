extends Node2D
class_name HexGrid

var Tile = preload("res://scenes/Tile.tscn")

# Properties

export var map_w = 3
export var map_h = 3

export var sprite_scale: Vector2 = Vector2.ONE

"""Size of the Sprite that fits inside the Hex. 
Sprite itself may contain elements outside of Hex borders"""
export var sprite_size: Vector2 = Vector2(32, 28)

# Local Variables

var hex_size: Vector2

var tiles: Dictionary
var active: Vector2 = Vector2(-INF, -INF)
var active_tile = null

func _ready():
	
	# scale sprites and calculate hex radiuses
	sprite_size *= sprite_scale
	hex_size = sprite_size * Vector2(1.0 / sqrt(3), 0.5)
	
	# allocate tile objects
	for y in range(map_h):
		for x in range(map_w):
			var tile = Tile.instance()
			var axial = Vector2(x-(y/2), y)
			
			tile.init(axial)
			add_child(tile)
			
			tiles[axial] = tile
			
	# tiles[Vector2(1, 2)].set_terrain(TG.TerrainType.REEF)

func _input(event):
	if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
		var pos = get_global_mouse_position()
		
		if active_tile: active_tile.reset_active()
		
		active = Hex.pixel_to_pointy_vex(pos, hex_size)
		
		if tiles.has(active):
			active_tile = tiles[active]
			active_tile.set_active()
