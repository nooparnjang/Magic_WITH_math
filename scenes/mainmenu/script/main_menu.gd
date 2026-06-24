extends Control

func _ready() -> void:
	await get_tree().process_frame
	MusicManager.play_music("res://assets/sound/Fame is a Gun - Addison Rae (Crimewave Remix).mp3")
