extends Control

@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var overlay_control: Control = $CanvasLayer/Control
@onready var animated_sprite: AnimatedSprite2D = $CanvasLayer/Control/AnimatedSprite2D


func _ready() -> void:
	stop_loading()


func start_loading() -> void:
	canvas_layer.show()

	overlay_control.mouse_filter = Control.MOUSE_FILTER_STOP

	if animated_sprite != null:
		animated_sprite.play("loading")


func stop_loading() -> void:
	if animated_sprite != null:
		animated_sprite.stop()

	# ไม่ให้ loading ขวาง mouse
	overlay_control.mouse_filter = Control.MOUSE_FILTER_IGNORE

	canvas_layer.hide()
