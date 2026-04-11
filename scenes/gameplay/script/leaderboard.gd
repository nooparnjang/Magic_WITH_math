extends Control

@onready var list = $MarginContainer/VBoxContainer/ScrollContainer/List
@onready var row_scene = preload("res://scenes/leaderboard/player_row.tscn")

func _ready():
	add_player(1, "BAM", 180, 12000)
	add_player(2, "SAIPARN", 170, 11000)
	add_player(3, "NICE", 160, 10000)
	add_player(4, "MAY", 160, 10000)
	add_player(5, "SUTHIDA", 160, 10000)
	add_player(6, "YATIP", 160, 10000)

func add_player(rank, name, kill, score):
	var row = row_scene.instantiate()
	row.get_node("Rank").text = str(rank)
	row.get_node("Name").text = name
	row.get_node("Kill").text = str(kill)
	row.get_node("Score").text = str(score)
	list.add_child(row)
