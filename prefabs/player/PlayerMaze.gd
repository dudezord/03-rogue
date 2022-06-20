extends Spatial

var _current_path : PoolVector2Array

var _is_moving = false

var walking_speed = 2.0


func _ready():
	pass


func _process(delta):
	if not _is_moving and _current_path.size() > 0:
		var next_pos = _current_path[0]
		_current_path.remove(0)
		
		var duration = 1.0 / walking_speed
		$Tween.interpolate_property(self, "translation:x", translation.x, next_pos.x, duration)
		$Tween.interpolate_property(self, "translation:z", translation.z, next_pos.y, duration)
		$Tween.interpolate_property(self, "_is_moving", 1.0, 0, duration)

		$Tween.start()
		
		Global.maze.on_Player_step()


func move(path):
	if _is_moving:
		return

	if path.size() < 2:
		return
		
	_current_path = path
	_current_path.remove(0)
