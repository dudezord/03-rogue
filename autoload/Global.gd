extends Node

var astar : AStar2D

var maze

var player_maze

var action_points = 0

signal start_battle


func _ready():
	connect("start_battle", self, "_on_start_battle")


func roll_action_points():
	action_points = rand_range(1, 10) as int


func _on_start_battle(mob : Mob):
	pass
