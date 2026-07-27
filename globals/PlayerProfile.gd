extends Node

const SAVE_PATH := "user://player_profile.json"

var player_name: String = ""
var country_code: String = ""


func has_profile() -> bool:
	return not player_name.is_empty() and not country_code.is_empty()


func create_profile(username: String, country: String) -> bool:
	var clean_name := username.strip_edges()

	if clean_name.length() < 3:
		return false

	if clean_name.length() > 20:
		return false

	if country.is_empty():
		return false

	player_name = clean_name
	country_code = country

	return save_profile()


func save_profile() -> bool:
	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if file == null:
		push_error("Could not save player profile.")
		return false

	var data := {
		"player_name": player_name,
		"country_code": country_code
	}

	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_profile() -> void:
	player_name = ""
	country_code = ""

	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if file == null:
		return

	var parsed = JSON.parse_string(
		file.get_as_text()
	)

	if not parsed is Dictionary:
		return

	player_name = str(parsed.get("player_name", ""))
	country_code = str(parsed.get("country_code", ""))


func _ready() -> void:
	load_profile()
