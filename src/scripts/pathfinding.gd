extends Node

var grid
var astar = AStar2D.new()
var free = AStar2D.new()

func reset(new_grid):
	grid = new_grid
	astar.clear()
	free.clear()
	# add points to astar
	for tile in grid:
		# print(tile, grid.find(tile))
		astar.add_point(grid.find(tile), tile)
		free.add_point(grid.find(tile), tile)
	# connect points in astar
	for tile in grid:
		var point_index = grid.find(tile)
		var points_relative = PoolVector2Array([
			Vector2(tile.x + Config.grid_size.x, tile.y + Config.grid_size.y),
			Vector2(tile.x - Config.grid_size.x, tile.y + Config.grid_size.y),
			Vector2(tile.x + Config.grid_size.x, tile.y - Config.grid_size.y),
			Vector2(tile.x - Config.grid_size.x, tile.y - Config.grid_size.y)
		])
		for point_relative in points_relative:
			var point_relative_index = grid.find(point_relative)
			if not astar.has_point(point_relative_index):
				continue
			astar.connect_points(point_index, point_relative_index, false)
			free.connect_points(point_index, point_relative_index, false)

func disable_tile(position, disabled):
	var point = grid.find(position)
	if point == -1:
		printt('invalid position:', position)
	else:
		astar.set_point_disabled(point, disabled)


func is_tile_disabled(position):
	return astar.is_point_disabled(grid.find(position))


func calculate_path(from, to, ignore_disabled = false):
	if ignore_disabled:
		return free.get_point_path(
			grid.find(from), 
			grid.find(to)
		)
	var point_from = grid.find(from)
	var point_to = grid.find(to)
	var is_blocked = astar.is_point_disabled(point_to)
	if is_blocked:
		astar.set_point_disabled(point_to, false)
	var path = astar.get_point_path(point_from, point_to)
	if is_blocked:
		astar.set_point_disabled(point_to, true)
	return path

func distance_to(from, to):
	return free.get_point_path(grid.find(from), grid.find(to)).size()
