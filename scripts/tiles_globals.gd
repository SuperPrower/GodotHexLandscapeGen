extends Node

enum TerrainType {OCEAN = 0, SHALLOW, BEACH, GRASS, REEF, LAST} # SHORE, GROUND, OIL_RIG}

var type_to_tile: Dictionary = {
	TerrainType.OCEAN: "Deep",
	TerrainType.SHALLOW: "Shallow",
	TerrainType.BEACH: "Sand",
	TerrainType.GRASS: "Grass",
	TerrainType.REEF: "Reefs",
}

var tile_count: Dictionary
var tileset: TileSet = preload("res://assets/hexes.tres")

func _ready():
	# Calculate amount of tiles in each atlas tile
	# Constraint: Sprites are Vertical (from top to bottom)
	for t in tileset.get_tiles_ids():
		var name = tileset.tile_get_name(t)
		var region = tileset.tile_get_region(t)
		var size = tileset.autotile_get_size(t)
		var spacing = tileset.autotile_get_spacing(t)
		
		TG.tile_count[name] = int((region.size.y + spacing) / (size.y + spacing))