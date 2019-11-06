extends Node2D

var terrain = TG.TerrainType.OCEAN

# var improvement = null
# var unit = null

var active: bool

var coordinate: Vector2
var pixel_coordinate: Vector2

var frame_time = 0.6
var time_elapsed = 0.0
var tile_offset = 0

func init(coord: Vector2):
	self.coordinate = coord
	self.active = false
	
func _ready():
	
	pixel_coordinate = Hex.pointy_vex_to_pixel(self.coordinate, get_parent().hex_size)
	
	$TileSprite.texture = TG.tileset.tile_get_texture(0)
	$TileSprite.region_enabled = true
	$TileSprite.position = pixel_coordinate
	$TileSprite.scale = get_parent().sprite_scale
	
	$CoordLabel.margin_left = -get_parent().hex_size.x
	$CoordLabel.margin_right = get_parent().hex_size.x
	$CoordLabel.margin_top = -get_parent().hex_size.y
	$CoordLabel.margin_bottom = get_parent().hex_size.y
	
	$CoordLabel.text = "%d:%d" % [self.coordinate.x, self.coordinate.y]
	$CoordLabel.rect_position = pixel_coordinate - get_parent().hex_size
	
	set_terrain(TG.TerrainType.OCEAN)

func _process(delta):
	time_elapsed += delta
	if time_elapsed >= frame_time:
		time_elapsed -= frame_time
		tile_offset = (tile_offset + 1) % TG.tile_count[TG.type_to_tile[self.terrain]]
		update_sprite()

func set_terrain(type):
	assert(type >= 0)
	assert(type < TG.TerrainType.LAST)
	
	self.terrain = type
	tile_offset = randi() % TG.tile_count[TG.type_to_tile[self.terrain]]
	update_sprite()
	
func update_sprite():
	var tile_id = TG.tileset.find_tile_by_name(TG.type_to_tile[self.terrain])
	
	var region = TG.tileset.tile_get_region(tile_id)
	var size = TG.tileset.autotile_get_size(tile_id)
	var spacing = TG.tileset.autotile_get_spacing(tile_id)
	
	$TileSprite.region_rect.position = region.position + Vector2(0, size.y + spacing) * tile_offset
	$TileSprite.region_rect.size = size

func set_active():
	self.active = true
	$CoordLabel.text = "ACT"

func reset_active():
	self.active = false
	$CoordLabel.text = "%d:%d" % [self.coordinate.x, self.coordinate.y]
