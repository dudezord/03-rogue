extends Node

var astar : AStar2D

var maze

var player_maze

var action_points = 0


func roll_action_points():
	action_points = rand_range(1, 10) as int
