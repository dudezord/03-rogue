extends Spatial

var cards : Array

export var card_scene : PackedScene

var reposition_duration = 0.15
var destroy_duration = 0.4
var focus_duration = 0.25
var focus_distance = 0.75

var circle_radius = 4.5
var start_angle = 90.0
var end_angle = 20.0


func add_card(card : Card):
	var material = SpatialMaterial.new()
	material.albedo_color = Color(randf(), randf(), randf())
	card.get_node("MeshInstance").set_surface_material(0, material)
	
	card.connect_mouse(self, "_on_Card_mouse_entered", "_on_Card_mouse_exited")
	  
	cards.append(card)
	$Cards.add_child(card)
	_reposition_cards()


func remove_card(index : int):
	if index < 0 or index >= cards.size():
		return
		
	var c = cards[index]
	
	$TweenDestroy.interpolate_property(c, "translation:x", c.translation.x, c.translation.x + 10, destroy_duration)
	$TweenDestroy.interpolate_property(c, "translation:y", c.translation.y, c.translation.y + 10, destroy_duration)
	$TweenDestroy.start()
	
	cards.remove(index)
	_reposition_cards()


func _reposition_cards():
	var total_cards = cards.size()
	
	if total_cards == 0:
		return
	
	var step_angle =  (end_angle - start_angle) / (total_cards + 1.5)
	var card_index = 0
	

	for c in cards:
		card_index += 1
	
		var angle = deg2rad(start_angle + step_angle * card_index)
		var pos_x = cos(angle) * circle_radius
		var pos_y = sin(angle) * circle_radius
	
		$TweenReposition.interpolate_property(c, "translation:x", c.translation.x, pos_x, reposition_duration)
		$TweenReposition.interpolate_property(c, "translation:y", c.translation.y, pos_y, reposition_duration)
		$TweenReposition.interpolate_property(c, "rotation:z", c.rotation.z, angle - deg2rad(90), reposition_duration)
		c.translation.z = card_index * 0.01

	$TweenReposition.start()


func _on_ButtonAdd_pressed():
	add_card(card_scene.instance())
	pass


func _on_ButtonRemove_pressed():
	remove_card(rand_range(0, cards.size() - 1))
	pass


func _on_TweenDestroy_tween_completed(object, key):
	$Cards.remove_child(object)
	pass


func _on_Card_mouse_entered(card : Card):
	if card.focus_distance > 0:
		return
		
	$TweenFocus.interpolate_property(card, "translation", card.translation, card.translation + card.transform.basis.y * focus_distance, focus_duration)
	$TweenFocus.interpolate_property(card, "focus_distance", card.focus_distance, focus_distance, focus_duration)
	$TweenFocus.start()


func _on_Card_mouse_exited(card : Card):
	var real_focus_duration = (card.focus_distance / focus_distance) * focus_duration
	real_focus_duration = clamp(real_focus_duration, 0.2, focus_duration)
	
	$TweenFocus.interpolate_property(card, "translation", card.translation, card.translation - card.transform.basis.y * card.focus_distance, real_focus_duration)
	$TweenFocus.interpolate_property(card, "focus_distance", card.focus_distance, 0, real_focus_duration)
	$TweenFocus.start()

