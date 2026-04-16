extends Node

const POPUP_SCENE := preload("res://scenes/shop/shop.tscn")
const POPUP_LAYER := 100

var popup_layer: CanvasLayer = null
var popup_instance: Control = null
var is_popup_open := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if event.is_echo():
		return

	toggle_popup()

func toggle_popup() -> void:
	if is_popup_open:
		close_popup()
	else:
		open_popup()

func open_popup() -> void:
	if popup_layer == null or not is_instance_valid(popup_layer):
		popup_layer = CanvasLayer.new()
		popup_layer.layer = POPUP_LAYER
		popup_layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		get_tree().root.add_child(popup_layer)

	if popup_instance == null or not is_instance_valid(popup_instance):
		popup_instance = POPUP_SCENE.instantiate() as Control

		if popup_instance == null:
			push_error("popup root ต้องเป็น Control")
			return

		popup_instance.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
		popup_layer.add_child(popup_instance)

	if popup_instance.has_method("show_popup"):
		popup_instance.show_popup()
	else:
		popup_instance.visible = true

	is_popup_open = true
	get_tree().paused = true

func close_popup() -> void:
	if popup_instance != null and is_instance_valid(popup_instance):
		if popup_instance.has_method("hide_popup"):
			popup_instance.hide_popup()
		else:
			popup_instance.visible = false

		popup_instance.queue_free()
		popup_instance = null

	if popup_layer != null and is_instance_valid(popup_layer):
		popup_layer.queue_free()
		popup_layer = null

	is_popup_open = false
	get_tree().paused = false
