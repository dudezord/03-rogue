extends Spatial

var _current_path : PoolVector2Array

var _is_idle = true

var walking_speed = 2.0


func _ready():
	pass


func _process(delta):
	_check_adjacent_enemies()
	_step_path()


func _step_path():
	if _is_idle and _current_path.size() > 0:
		_is_idle = false
		var next_pos = _current_path[0]
		_current_path.remove(0)
		
		var duration = 1.0 / walking_speed
		$Tween.interpolate_property(self, "translation:x", translation.x, next_pos.x, duration)
		$Tween.interpolate_property(self, "translation:z", translation.z, next_pos.y, duration)

		$Tween.start()
		
	
func _check_adjacent_enemies():
	if not _is_idle:
		return
 
	randomize()
	
	var dirs = [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	dirs.shuffle()
	
	var raycast = $RayCast
		
	for dir in dirs:
		raycast.cast_to	= dir * 2
		raycast.force_raycast_update()
		
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			
			if collider.owner is Cell:
				continue
				
			if collider.owner is Mob:
				Global.emit_signal("start_battle", collider.owner)
				continue
				
			break
	
	
func move(path):
	if not _is_idle:
		return

	if path.size() < 2:
		return
		
	_current_path = path
	_current_path.remove(0)


func _on_Tween_tween_all_completed():
	_is_idle = true
	Global.maze.on_Player_step()
