extends Mob

var _steps_remaining = 0

var _current_path : PoolVector2Array = []

func _ready():
	pass


func step():
	randomize()

	if _current_path.size() == 0:
		var path = []
		
		var current_pos = Vector2(translation.x, translation.z)
		var current_id = Global.astar.get_closest_point(current_pos)
			
		while true:
			var next_pos = current_pos + Vector2(rand_range(-8, 8), rand_range(-8, 8))
			var next_id = Global.astar.get_closest_point(next_pos)
			
			path = Global.astar.get_point_path(current_id, next_id)
			if path.size() == 6:
				break
		
		path.remove(0)
		_current_path = path
	
	var next_pos = _current_path[0]
	_current_path.remove(0)
	
	$Tween.interpolate_property(self, "translation:x", translation.x, next_pos.x, 0.3)
	$Tween.interpolate_property(self, "translation:z", translation.z, next_pos.y, 0.3)
	$Tween.start()
