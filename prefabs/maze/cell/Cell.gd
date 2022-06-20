extends Spatial

var x = -1
var y = -1


func _ready():
	pass


func _on_Area_input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == 1 and event.pressed:
			Global.maze.on_Cell_clicked(self)
