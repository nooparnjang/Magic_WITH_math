extends Node

var questions: Array = []

@export_file("*.json") var json_path: String = "res://data/story_questions.json"

func _ready() -> void:
	_load_json()

func _load_json() -> void:
	if not FileAccess.file_exists(json_path):
		push_error("QuizDatabase: JSON not found")
		return

	var file := FileAccess.open(json_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())

	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("questions"):
		questions = parsed["questions"]
		print("QuizDatabase loaded:", questions.size())
	else:
		push_error("Invalid JSON format")

func get_question(index: int) -> Dictionary:
	if index >= 0 and index < questions.size():
		return questions[index]
	return {}

func get_total_questions() -> int:
	return questions.size()
