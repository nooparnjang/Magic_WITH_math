extends Control

@onready var name_input: LineEdit = \
	$VBoxContainer/PanelContainer/VBoxContainer/VBoxContainer/LineEdit

@onready var country_option: OptionButton = \
	$VBoxContainer/PanelContainer/VBoxContainer/VBoxContainer2/OptionButton

@onready var error_warning: Label = \
	$VBoxContainer/PanelContainer/VBoxContainer/errorwarning

@onready var finish_button: Button = \
	$VBoxContainer/PanelContainer/VBoxContainer/Button


const MAIN_MENU_PATH := "res://scenes/mainmenu/MainMenu.tscn"


func _ready() -> void:
	error_warning.hide()


func _on_button_pressed() -> void:
	error_warning.hide()

	var username := name_input.text.strip_edges()

	var country_code := str(
		country_option.get_item_metadata(
			country_option.selected
		)
	)

	if username.length() < 3:
		show_error("Name must be at least 3 characters.")
		return

	if username.length() > 20:
		show_error("Name must be 20 characters or less.")
		return

	if country_code.is_empty():
		show_error("Please choose your country.")
		return

	var success := PlayerProfile.create_profile(
		username,
		country_code
	)

	if not success:
		show_error("Could not save profile.")
		return

	print("Profile created")
	print("Name: ", PlayerProfile.player_name)
	print("Country: ", PlayerProfile.country_code)

	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func show_error(message: String) -> void:
	error_warning.text = message
	error_warning.show()
