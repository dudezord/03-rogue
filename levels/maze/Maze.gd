extends Spatial

var MAZE_WIDTH = 0
var MAZE_HEIGHT = 0

var MAZE_COLUMNS = 25
var MAZE_ROWS = 25

enum Walls {
	None = 0,
	N = 1 << 0,
	S = 1 << 1,
	W = 1 << 2,
	E = 1 << 3
	All = -1
}
	
var cells = null

var _astar = null

var _dict = {}

var _player_pos = [MAZE_COLUMNS / 2, MAZE_ROWS - 2]

var _enemies = []
var _enemies_pos = [
	[1, 1], 
	[MAZE_COLUMNS - 2, 1], 
	
	[1, MAZE_ROWS / 2], 
	[MAZE_COLUMNS / 2, MAZE_ROWS / 2], 
	[MAZE_COLUMNS - 2, MAZE_ROWS / 2], 
	
	[1, MAZE_ROWS - 2], 
	[MAZE_COLUMNS - 2, MAZE_ROWS - 2]
]

var _end_pos = [MAZE_COLUMNS / 2, 3]

var _current_cell = null


func _ready():
	Global.maze = self
	Global.player_maze = $PlayerMaze
	
	$Plane.scale.x = MAZE_COLUMNS
	$Plane.scale.z = MAZE_ROWS
	
	MAZE_WIDTH = $Plane.scale.x
	MAZE_HEIGHT = $Plane.scale.z

func generate():
	while true:
		randomize()

		if cells:
			remove_child(cells)
			cells.queue_free()
			_dict = {}
			
		cells = Spatial.new()
		cells.name = "Cells"
		add_child(cells)
		
		_add_default_cells()
		_randomize_cells_walls()
		_create_navigation()
		
		if _is_navigation_valid():
			break

	var player_cell = _get_cell(_player_pos[0], _player_pos[1])
	$PlayerMaze.translation = player_cell.translation
	_current_cell = player_cell
	
	var end_cell = _get_cell(_end_pos[0], _end_pos[1])
	$MobEndMaze.translation = end_cell.translation
	
	for enemy in _enemies:
		enemy.queue_free()
	_enemies.clear()
	
	for enemy_pos in _enemies_pos:
		var enemy = preload("res://prefabs/mob_enemy/MobEnemyMaze.tscn").instance()
		
		var enemy_cell = _get_cell(enemy_pos[0], enemy_pos[1])
		enemy.translation = enemy_cell.translation
		add_child(enemy)
		_enemies.append(enemy)


func _is_navigation_valid():
	var player_index = _get_cell_index(_player_pos[0], _player_pos[1])
	var end_index = _get_cell_index(_end_pos[0], _end_pos[1])
	
	var end_path = _astar.get_id_path(player_index, end_index)
	if end_path.size() == 0:
		return false
	
	for enemy in _enemies_pos:
		var enemy_index = _get_cell_index(enemy[0], enemy[1])
		var enemy_path = _astar.get_id_path(player_index, enemy_index)
		if enemy_path.size() == 0:
			return false
		
	return true


func _add_default_cells():
	var step_x = 2 * MAZE_WIDTH / MAZE_COLUMNS
	var step_y = 2 * MAZE_HEIGHT / MAZE_ROWS
	var origin_x = -step_x * (MAZE_COLUMNS / 2.0) + step_x / 2.0
	var origin_y =  -step_y * (MAZE_ROWS / 2.0) + step_y / 2.0
	
	for x in range(0, MAZE_COLUMNS):
		for y in range(0, MAZE_ROWS):
			var cell = preload("res://prefabs/maze/cell/Cell.tscn").instance()
			cell.name = "Cell|%d,%d" % [x, y]
			cell.x = x
			cell.y = y

			var region = [0, 0, MAZE_COLUMNS - 1, MAZE_ROWS - 1]
				
			cell.translation = Vector3(origin_x + step_x * x, 0, origin_y + step_y * y)
			cell.scale = Vector3(step_x / 2, 1, step_y / 2)
			
			_update_cell(cell, region)
				
			cells.add_child(cell)


func _randomize_cells_walls():
	for _i in range(0, 500):
		var width = 1 + randi() % 16
		var height = 1 + randi() % 16
		
		var step = 100
		var div = _i / step
		
		if div > 0:
			width /= div
			height  /= div
			
		var x = randi() % (MAZE_COLUMNS - width + 1)
		var y = randi() % (MAZE_ROWS - height + 1)
		var region = [x, y, x + width - 1, y + height - 1]

		for _x in range(x, x + width):
			for _y in range(y, y + height):
				var cell = _get_cell(_x, _y)
				_update_cell(cell, region, false)


func _get_cell(x, y):
	if x < 0 || x >= MAZE_COLUMNS:
		return null
		
	if y < 0 || y >= MAZE_ROWS:
		return null
		
	var index = _get_cell_index(x, y)
	
	if not _dict.has(index):
		if not cells.has_node("Cell|%d,%d" % [x, y]):
			return null
			
		var cell = cells.get_node("Cell|%d,%d" % [x, y])
		_dict[index] = cell
	
	return _dict[index]


func _get_cell_index(x, y):
	return x + y * MAZE_ROWS


func _update_cell(cell, region, outside_walls = true):
	var width = (region[2] - region[0]) + 1
	var height = (region[3] - region[1]) + 1
	
	if outside_walls:
		width = 1
		height = 1
		
	var prob_x = 1.0 / width
	var prob_y = 1.0 / height
	
	var walls = Walls.None
	
	if cell.x == 0 || (cell.x == region[0] and randf() > prob_y):
		walls |= Walls.W
	if cell.x == MAZE_COLUMNS - 1 || (cell.x == region[2] and randf() > prob_y):
		walls |= Walls.E
		
	if cell.y == 0 || (cell.y == region[1] and randf() > prob_x):
		walls |= Walls.N
	if cell.y == MAZE_ROWS - 1 || (cell.y == region[3] and randf() > prob_x):
		walls |= Walls.S
				
	var has_north = (walls & Walls.N)
	var has_south = (walls & Walls.S)
	var has_west = (walls & Walls.W)
	var has_east = (walls & Walls.E)
	
	cell.get_node("N").visible = has_north
	cell.get_node("S").visible = has_south
	cell.get_node("W").visible = has_west
	cell.get_node("E").visible = has_east
	
	if outside_walls:
		return
		
	var left_cell = _get_cell(cell.x - 1, cell.y)
	if left_cell:
		left_cell.get_node("E").visible = has_west
		
	var right_cell = _get_cell(cell.x + 1, cell.y)
	if right_cell:
		right_cell.get_node("W").visible = has_east
		
	var top_cell = _get_cell(cell.x, cell.y - 1)
	if top_cell:
		top_cell.get_node("S").visible = has_north
		
	var bottom_cell = _get_cell(cell.x, cell.y + 1)
	if bottom_cell:
		bottom_cell.get_node("N").visible = has_south


func _create_navigation():
	_astar = AStar2D.new()
	
	for x in range(0, MAZE_COLUMNS):
		for y in range(0, MAZE_ROWS):
			var cell = _get_cell(x, y)
			var index = _get_cell_index(cell.x, cell.y)
			_astar.add_point(index, Vector2(cell.translation.x, cell.translation.z))
			
	for x in range(0, MAZE_COLUMNS):
		for y in range(0, MAZE_ROWS):
			var cell = _get_cell(x, y)
			var index = _get_cell_index(cell.x, cell.y)
			
			var right_cell = _get_cell(cell.x + 1, cell.y)
			if right_cell and not cell.get_node("E").visible:
				var right_index = _get_cell_index(right_cell.x, right_cell.y)
				_astar.connect_points(index, right_index)
				
			var bottom_cell = _get_cell(cell.x, cell.y + 1)
			if bottom_cell and not cell.get_node("S").visible:
				var bottom_index = _get_cell_index(bottom_cell.x, bottom_cell.y)
				_astar.connect_points(index, bottom_index)
				
	
	Global.astar = _astar;


func _on_ButtonGenerate_pressed():
	generate()
	_update_reachable_cells()


func on_Cell_clicked(cell):
	var start_pos = Vector2(Global.player_maze.translation.x, Global.player_maze.translation.z)
	var end_pos = Vector2(cell.translation.x, cell.translation.z)
	
	var start_id = Global.astar.get_closest_point(start_pos)
	var end_id = Global.astar.get_closest_point(end_pos)
	
	var path = Global.astar.get_point_path(start_id, end_id)
	if path.size() > 1 and path.size() <= Global.action_points + 1:
		Global.player_maze.move(path)
		_current_cell = cell
	
	
func on_Player_step():
	Global.action_points -= 1
	
	$ButtonRoll.text = "Roll: %d" % Global.action_points
	
	for enemy in _enemies:
		enemy.step()
		
	_update_reachable_cells()


func _on_ButtonRoll_pressed():
	Global.roll_action_points()
	$ButtonRoll.text = "Roll: %d" % Global.action_points

	_update_reachable_cells()
	
	
func _update_reachable_cells():
	for _cell in cells.get_children():
		_cell.get_node("Ground").scale = Vector3.ZERO
		
	var start_pos = Vector2(_current_cell.translation.x, _current_cell.translation.z)
	var start_id = Global.astar.get_closest_point(start_pos)
	
	for dx in range(-Global.action_points, Global.action_points + 1):
		for dy in range(-Global.action_points, Global.action_points + 1):
			if abs(dx) + abs(dy) > Global.action_points:
				continue
				
			var end_coords = Vector2(_current_cell.x, _current_cell.y) + Vector2(dx, dy)
			var end_cell = _get_cell(end_coords.x, end_coords.y)
			
			if not end_cell:
				continue
			
			var end_id = _get_cell_index(end_coords.x, end_coords.y)
			var path = Global.astar.get_id_path(start_id, end_id)
			if path.size() > 0 and path.size() <= Global.action_points + 1:
				end_cell.get_node("Ground").scale = Vector3.ONE
