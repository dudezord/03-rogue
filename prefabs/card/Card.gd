class_name Card 
extends Spatial

var focus_distance = 0.0


func connect_mouse(target, method_entered, method_exited):
	$Area.connect("mouse_entered", target, method_entered, [self])
	$Area.connect("mouse_exited", target, method_exited, [self])
	pass
