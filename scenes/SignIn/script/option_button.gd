extends OptionButton

const COUNTRIES_PATH := "res://data/countries.json"


func _ready() -> void:
	load_countries()


func load_countries() -> void:
	clear()

	# ตัวเลือกแรกไว้กัน user ไม่ได้เลือกประเทศจริง
	add_item("Select Country")
	set_item_metadata(0, "")

	if not FileAccess.file_exists(COUNTRIES_PATH):
		push_error("Countries file not found: " + COUNTRIES_PATH)
		return

	var file := FileAccess.open(
		COUNTRIES_PATH,
		FileAccess.READ
	)

	if file == null:
		push_error("Could not open countries.json")
		return

	var json_text := file.get_as_text()
	var data = JSON.parse_string(json_text)

	if not data is Array:
		push_error("countries.json root must be an Array")
		return

	for country in data:
		if not country is Dictionary:
			continue

		var country_name := str(
			country.get("name", "")
		)

		var country_code := str(
			country.get("code", "")
		)

		if country_name.is_empty() or country_code.is_empty():
			continue

		add_item(country_name)

		var index := item_count - 1

		# เช่น Thailand แสดงใน UI
		# แต่เก็บ TH ไว้ใน metadata
		set_item_metadata(index, country_code)

	select(0)


func get_selected_country_code() -> String:
	if selected < 0:
		return ""

	return str(
		get_item_metadata(selected)
	)


func get_selected_country_name() -> String:
	if selected < 0:
		return ""

	if selected == 0:
		return ""

	return get_item_text(selected)


func has_selected_country() -> bool:
	return not get_selected_country_code().is_empty()
