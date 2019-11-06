extends Node2D
class_name HexLandscapeGenerator

"""
Agent-based Procedural Ocean Landscape Generator

Agents:
	Island Agent:
		- Generate an Island
		- Get Points for being away from Map Edges and other Island Agents
		- When Done, leaves island with the radius R
	
	Coastline Agent:
		- Starts in the center of the island, moves to the random edge
		- Then starts a walk along the island edge on the water
		- Generates shallow water, but may be forced to leave some cells be deep
		- Gets points for ...
		- When Done, leaves a Beach agent on the island
		
	Beach Agent:
		- Walks along the island edge on the island
		- Changes Ground to the Sand if near the Shallow water
		- If not near the shallow water, but still near the ocean, may dig anyway
		- May randomly dig up to max_dig cells to be shallow water
		- Gets points for ...
		
	Reef Agent: TODO
		- Walks alongside the beach on the water
		- Leaves Reefs behind, sometimes in groups
		- Gets most points by leaving Reefs in Deep Water near Ground Beach
"""

export var islands: int = 2
export var island_radius: int = 3
export var island_max_walk: int = 10
export var island_fitness_edge_weight: float = 1.5
export var island_fitness_distance_weight: float = 0.9

export var coastline_max_thickness: int = 2
export var coastline_thickness_prob: float = 0.3
export var coastline_max_walk: int = 12

export var beach_max_walk: int = 10
export var beach_sand_anyway_prob: float = 0.3

export var beach_rand_dig: bool = true
export var beach_dig_prob: float = 0.1

# export var reefs_max_per_island: int = 4
# export var reefs_max_per_group: int = 2

var hexgrid

var stage = 0

func _ready():
	randomize()
	set_process_input(false)

func _on_HexGrid_ready():
	hexgrid = $"../HexGrid"
	set_process_input(true)

func _input(event):
	if event is InputEventKey and event.scancode == KEY_SPACE:
		print("Space")
		simulate_step()

func _process(delta):
	update()

func _draw():
	if stage >= 3: return
	for i in agents:
		for v in range(len(agents[i].visited)):
			draw_circle(
				Hex.pointy_vex_to_pixel(agents[i].visited[v], hexgrid.hex_size), 
				5, Color.yellow
			);
		for v in range(len(agents[i].ignored)):
			draw_circle(
				Hex.pointy_vex_to_pixel(agents[i].ignored[v], hexgrid.hex_size), 
				5, Color.red
			);
		draw_circle(
			Hex.pointy_vex_to_pixel(agents[i].coordinate, hexgrid.hex_size), 
			5, Color.green
		);

func tile_near_type(t: Vector2, type) -> bool:
	"""Small helper function for checking on neighbouring cells type
	"""
	var cn = Hex.vex_neighbours(t)
	for c in cn:
		if c in hexgrid.tiles and hexgrid.tiles[c].terrain == type:
			return true

	return false

#
# Variables for Agents
#
class Agent:
	var visited: Array = []
	var ignored: Array = []
	var coordinate: Vector2
	var moves: int

var agents: Dictionary

func simulate_step():
	## Run Generation agents
	# Run Island agents step by step
	if stage < 3:
		var all_done = true
		for i in range(islands):
			var stage_done = call_stage(stage, false, i)
			all_done = (all_done && stage_done)
		
		if all_done:
			for i in range(islands): call_stage(stage, true, i)
			stage += 1
	else:
		print("Done")

func call_stage(stage, done: bool, agent_id):
	if stage == 0:
		if not done: return island_agent_step(agent_id)
		else: island_agent_done(agent_id)
	elif stage == 1:
		if not done: return coastline_agent_step(agent_id)
		else: coastline_agent_done(agent_id)
	elif stage == 2:
		if not done: return beach_agent_step(agent_id)
		else: beach_agent_done(agent_id)

## Island Generation

func island_agent_step(i: int) -> bool:
	if not i in agents:
		agents[i] = Agent.new()
		agents[i].coordinate.y = int(randi() % hexgrid.map_h)
		agents[i].coordinate.x = randi() % (hexgrid.map_w - (int(agents[i].coordinate.y)/2))
		agents[i].moves = island_max_walk

	var s = agents[i]
	var best: Vector2 = Vector2.INF
	var best_score = -INF
	
	for ns in Hex.vex_neighbours(s.coordinate):
		if not ns in s.visited and not ns in s.ignored and ns in hexgrid.tiles:
			var score = island_agent_fitness(i, ns)
			if score > best_score:
				best = ns; best_score = score
	
	if best in hexgrid.tiles:
		print("MOV %d: %d:%d -> %d:%d, score: %f" % [i, s.coordinate.x, s.coordinate.y, best.x, best.y, island_agent_fitness(i, best)])
		s.visited.push_back(best)
		s.coordinate = best
	elif island_agent_fitness(i, s.coordinate) <= island_agent_fitness(i, s.visited[-1]):
		# step back and ignore this tile
		s.ignored.push_back(s.coordinate)
		print("BAK %d: %d:%d <- %d:%d" % [i, s.visited.back().x, s.visited.back().y, s.coordinate.x, s.coordinate.y])
		s.coordinate = s.visited.pop_back()
		
	s.moves -= 1
	
	if s.moves > 0:
		return false
	else:
		return true

func island_agent_fitness(i, c: Vector2) -> float:
	"""
	Calculates fitness score of the tile c for the agent i
	"""
	var score = 0.0
	
	var min_other_distance = +INF
	var min_edge_y_distance = +INF
	var min_edge_x_distance = +INF
	
	var min_x_edge = int(- c.y / 2)
	var min_y_edge = int(0)
	
	var max_x_edge = int(min_x_edge + hexgrid.map_w)
	var max_y_edge = int(hexgrid.map_h)
	
	# minimal distance from other agents
	for j in agents:
		if i == j: continue
		min_other_distance = min(min_other_distance, Hex.vex_distance(c, agents[j].coordinate))
	
	min_edge_y_distance = min(abs(max_y_edge - c.y), abs(c.y - min_y_edge))
	min_edge_x_distance = min(abs(max_x_edge - c.x), abs(c.x - min_x_edge))
	
	var min_edge_distance = min(min_edge_y_distance, min_edge_x_distance)
	
	score = min(
			min_edge_distance * island_fitness_edge_weight, 
			min_other_distance * island_fitness_distance_weight
	)
	
	return score

func island_agent_done(i):
	# Generate an island around itself
	var N = island_radius
	var c = agents[i].coordinate
	for dq in range(-N, N+1):
		for dr in range(max(-N, -dq-N), min(N, -dq+N) + 1):
			var o = Vector2(c.x + int(dq), c.y + int(dr))
			if o in hexgrid.tiles:
				hexgrid.tiles[o].set_terrain(TG.TerrainType.GRASS)
	
	# reset an agent: it's now a coastline walk agent
	agents[i].visited = []
	agents[i].ignored = []
	agents[i].moves = coastline_max_walk
	# move the agent to the shore
	# walk the ring in radius + 1 cells from the island center looking for valid cell
	var pos: Vector2 = agents[i].coordinate + Hex.d_neighbors[-2] * (island_radius + 1)
	for d in range(len(Hex.d_neighbors)):
		for j in range(island_radius + 1):
			if pos in hexgrid.tiles and hexgrid.tiles[pos].terrain == TG.TerrainType.OCEAN:
				agents[i].coordinate = pos
				return
			else:
				pos = pos + Hex.d_neighbors[d]
				continue

## Shore Generation

func coastline_agent_step(i: int) -> bool:
	var s = agents[i]
	var best: Vector2 = Vector2.INF
	var best_score = -INF
	
	for ns in Hex.vex_neighbours(s.coordinate):
		if (not ns in s.visited and 
			not ns in s.ignored and
			ns in hexgrid.tiles and
			tile_near_type(ns, TG.TerrainType.GRASS) and
			hexgrid.tiles[ns].terrain == TG.TerrainType.OCEAN
		):
			var score = coastline_agent_fitness(i, ns)
			if score > best_score:
				best = ns; best_score = score
	
	if best in hexgrid.tiles:
		if s.moves > 0:
			s.visited.push_back(best)
			s.coordinate = best
			hexgrid.tiles[best].set_terrain(TG.TerrainType.SHALLOW)
			# randomly drop an additional shallow tile nearby if allowed
			if coastline_max_thickness > 1 and randf() < coastline_thickness_prob:
				var add_thicc = randi() % coastline_max_thickness
				for tile in range(add_thicc):
					var placed_tile = false
					var tn = Hex.vex_neighbours(best)
					for tnt in tn:
						if (not tile_near_type(tnt, TG.TerrainType.GRASS) and 
							tnt in hexgrid.tiles and
							hexgrid.tiles[tnt].terrain == TG.TerrainType.OCEAN
						):
							placed_tile = true
							hexgrid.tiles[tnt].set_terrain(TG.TerrainType.SHALLOW)
							break
							
					if not placed_tile:
						# nowhere to place tiles
						break
	else:
		# can't go anywhere, go back
		if len(s.visited) > 0:
			s.ignored.push_back(s.coordinate)
			s.coordinate = s.visited.pop_back()
			s.moves += 1 # compensate a move
		else:
			# can't go anywhere at all, done
			return true
	
	s.moves -= 1
	if s.moves > 0:
		return false
	else:
		return true

func coastline_agent_fitness(i, c: Vector2) -> float:
	"""
	Calculates fitness score of the tile c for the coastline agent i
	"""
	var score = 0.0
	
	# TODO
	
	return score

func coastline_agent_done(i):
	# reset an agent: it's now a beach walk agent
	agents[i].visited = []
	agents[i].ignored = []
	agents[i].moves = beach_max_walk
	# move the agent to the beach
	var tn = Hex.vex_neighbours(agents[i].coordinate)
	for tnt in tn:
		if (tnt in hexgrid.tiles and
			hexgrid.tiles[tnt].terrain == TG.TerrainType.GRASS
		):
			agents[i].coordinate = tnt
			break
	# TODO

## Beach Generation

func beach_agent_step(i: int) -> bool:
	var s = agents[i]
	var best: Vector2 = Vector2.INF
	var best_score = -INF
	var sand_anyway = false
	
	for ns in Hex.vex_neighbours(s.coordinate):
		if ns in s.visited or ns in s.ignored or not ns in hexgrid.tiles:
			continue
		
		var score = beach_agent_fitness(i, ns)
		if score > 0.0 and score > best_score:
			best = ns; best_score = score
	
	if best in hexgrid.tiles:
		if s.moves > 0:
			s.visited.push_back(best)
			s.coordinate = best
			hexgrid.tiles[best].set_terrain(TG.TerrainType.BEACH)
			# randomly dig a shallow tile
			if beach_rand_dig and randf() < beach_dig_prob:
				if tile_near_type(best, TG.TerrainType.GRASS):
					hexgrid.tiles[best].set_terrain(TG.TerrainType.SHALLOW)
			
				# find a neighbour to move to
				var tn = Hex.vex_neighbours(best)
				for tnt in tn:
					if (tnt in hexgrid.tiles and
						not tnt in s.visited and
						not tnt in s.ignored and
						hexgrid.tiles[tnt].terrain == TG.TerrainType.GRASS
					):
						s.coordinate = tnt
						break
					
	else:
		# can't go anywhere, go back
		if len(s.visited) > 0:
			s.ignored.push_back(s.coordinate)
			s.coordinate = s.visited.pop_back()
			s.moves += 1 # compensate a move
		else:
			# can't go anywhere at all, done
			return true
	
	s.moves -= 1
	if s.moves > 0:
		return false
	else:
		return true

func beach_agent_fitness(i, c: Vector2) -> float:
	"""
	Calculates fitness score of the tile c for the beach agent i
	"""
	var score = 0.0
	
	# best case scenario: near the shallow water, on the grass
	if (tile_near_type(c, TG.TerrainType.SHALLOW) and
		hexgrid.tiles[c].terrain == TG.TerrainType.GRASS
	):
		score = 1.0
	
	# not near the shallow water, but still near the water
	# must be enabled and triggered by probability, but still pretty good
	elif (tile_near_type(c, TG.TerrainType.OCEAN) and
		hexgrid.tiles[c].terrain == TG.TerrainType.GRASS
	):
		score = 0.5 + randf() * beach_sand_anyway_prob
	
	# No more shore to fill with sand, so maybe try to make sand thiccer?
	elif (tile_near_type(c, TG.TerrainType.BEACH) and
		hexgrid.tiles[c].terrain == TG.TerrainType.GRASS
	):
		score = 0.1 + (beach_sand_anyway_prob - randf())
	
	return score

func beach_agent_done(i):
	# reset an agent: it's now a reef walk agent
	agents[i].visited = []
	agents[i].ignored = []
	agents[i].moves = beach_max_walk
	# move the agent to the beach
	# TODO