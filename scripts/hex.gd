# extends Node
class_name Hex
"""
Represents operations on Hexagonal Tiles in Vector2 representation,
where x is q, y is r, and s can be calculated

Tiles are Pointy Topped and use Axial coordinates.
Based on https://www.redblobgames.com/grids/hexagons/
"""

const q_basis = Vector2(sqrt(3), 0.0)
const r_basis = Vector2(sqrt(3)/2.0, 3.0/2.0)

const qb_inv = Vector2(sqrt(3)/3.0, -1.0/3.0)
const rb_inv = Vector2(0.0, 2.0/3.0)

static func vex_s(v: Vector2) -> int: return int(- v.x - v.y)

static func pointy_hex_corner(center: Vector2, size: Vector2, i: int) -> Vector2:
	"""Get a coordinate of the i'th hex corner
	
	@param center: X/Y coordinate of the hex center
	@param size: radiuses of the hex in pixels
	@param i: corner number
	
	@return Coordinate of a i'th corner
	"""
	var angle_deg = 60 * i - 30
	var angle_rad = PI / 180.0 * angle_deg
	return Vector2(
		center.x + size.x * cos(angle_rad), 
		center.y + size.y * sin(angle_rad)
	)

static func pixel_to_pointy_hex(point: Vector2, size: Vector2) -> Vector2:
	"""Convert pixel coordinate to the Axial coordinate
	
	TODO: offsets
	
	@param index: pixel coordinate
	@param size: radiuses of the hex in pixels
	
	@return: Axial coordinate of the hex
	"""
	var q = (qb_inv.x * point.x + qb_inv.y * point.y) / size.x
	var r = (rb_inv.x * point.x + rb_inv.y * point.y) / size.y
	return cube_round(q, r, (-q-r))

static func pointy_vex_to_pixel(v_index: Vector2, size: Vector2) -> Vector2:
	"""Convert Axial coordinate in Vector representation to the center coordinate
	
	TODO: offsets
	
	@param index: axial coordinate of the hex
	@param size: radiuses of the hex in pixels
	"""
	
	var x = size.x * (v_index.x * q_basis.x + v_index.y * r_basis.x)
	var y = size.y * (v_index.x * q_basis.y + v_index.y * r_basis.y)
	return Vector2(x, y)

static func pixel_to_pointy_vex(point: Vector2, size: Vector2) -> Vector2:
	"""Convert pixel coordinate to the Axial coordinate in Vector representation
	
	TODO: offsets
	TODO: precision
	
	@param index: pixel coordinate
	@param size: radiuses of the hex in pixels
	
	@return: Axial coordinate of the hex in Vector representation
	"""
	var q = (qb_inv.x * point.x + qb_inv.y * point.y) / size.x
	var r = (rb_inv.x * point.x + rb_inv.y * point.y) / size.y
	return cube_round(q, r, (-q-r))

# clockwise, starting from north-west
const d_neighbors = [
	Vector2(-1,  0), Vector2(-1, +1), 
	Vector2( 0, +1), Vector2(+1,  0),
	Vector2(+1, -1), Vector2(0,  -1), 
]

static func vex_neighbours(point: Vector2) -> Array:
	var ret = d_neighbors.duplicate()
	for d in range(len(ret)):
		ret[d] += point
		
	return ret

static func vex_cells_in_radius(point: Vector2, radius: int) -> Array:
	var pos: Vector2 = point + d_neighbors[-2] * (radius)
	var ret = []
	for d in range(len(d_neighbors)):
		for j in range(radius + 1):
			ret.append(pos)
			pos += d_neighbors[d]
	
	return ret

static func vex_distance(v1: Vector2, v2: Vector2) -> int:
	return int(max(abs(v1.x - v2.x), abs(v1.y - v2.y)))

static func cube_round(q, r, s):
	# TODO: does it even work?
	var rq = round(q)
	var rr = round(r)
	var rs = round(s)

	var q_diff = abs(rq - q)
	var r_diff = abs(rr - r)
	var s_diff = abs(rs - s)

	if q_diff > r_diff and q_diff > s_diff:
		rq = -rr - rs
	elif r_diff > s_diff:
		rr = -rq - rs
	else:
		rs = -rq - rr
	
	assert(rq + rr + rs <= 0.01)
	
	return Vector2(int(rq), int(rr))

static func get_vec_tile_polygon(v_index: Vector2, size: Vector2) -> PoolVector2Array:
	"""Get a polygon from the given vex
	
	@param index: axial coordinate of the hex
	@param size: radiuses of the hex in pixels
	
	@return Array of Polygon Points that make a Hex
	"""
	var poly = PoolVector2Array()
	var center = pointy_vex_to_pixel(v_index, size)
	for i in range(0, 6):
		poly.append(pointy_hex_corner(center, size, i))
	
	return poly
