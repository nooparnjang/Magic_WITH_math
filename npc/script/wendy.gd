extends CharacterBody2D

enum State {
	BEFORE_QUEST,
	QUEST_ACCEPTED,
	HAS_ITEM,
	QUEST_DONE
}

@export var interact_key := "ui_talk"
@export var required_item := "engine_part"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hint = $hintE
@onready var bubble = $BubbleAnchor/DialogBubble
@onready var area: Area2D = $Area2D

var player_in_range := false
var current_state = State.BEFORE_QUEST
var current_player: Node2D = null
var is_talking := false

func _ready() -> void:
	if bubble.has_method("hide_bubble"):
		bubble.hide_bubble()
	else:
		bubble.hide()

	if hint.has_method("hide_hint"):
		hint.hide_hint()
	else:
		hint.hide()

	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if not player_in_range:
		return

	if Input.is_action_just_pressed(interact_key):
		if not is_talking:
			interact()
		else:
			var finished = bubble.advance_or_finish_line()
			if finished:
				finish_dialog_state()
				end_dialog()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		current_player = body

		if hint.has_method("show_hint"):
			hint.show_hint()
		else:
			hint.show()

func _on_body_exited(body: Node2D) -> void:
	if body == current_player:
		player_in_range = false
		current_player = null
		end_dialog()

		if hint.has_method("hide_hint"):
			hint.hide_hint()
		else:
			hint.hide()

func interact() -> void:
	if current_player != null and current_player.has_method("begin_interaction"):
		current_player.begin_interaction()

	is_talking = true

	if hint.has_method("hide_hint"):
		hint.hide_hint()
	else:
		hint.hide()

	sprite.play("talk")

	if current_player != null:
		sprite.flip_h = current_player.global_position.x < global_position.x

	if current_state == State.QUEST_ACCEPTED and BlessingManager.has_item(required_item):
		current_state = State.HAS_ITEM

	var lines := get_dialog_lines()
	bubble.start_dialog("WENDY", lines)

func end_dialog() -> void:
	is_talking = false

	if bubble.has_method("hide_bubble"):
		bubble.hide_bubble()
	else:
		bubble.hide()

	if sprite.animation != "idle":
		sprite.play("idle")

	if current_player != null and current_player.has_method("end_interaction"):
		current_player.end_interaction()

	if player_in_range:
		if hint.has_method("show_hint"):
			hint.show_hint()
		else:
			hint.show()

func get_dialog_lines() -> Array[String]:
	match current_state:
		State.BEFORE_QUEST:
			return [
				"Hey... You look lost.",
				"I'm Wendy.",
				"If you're trying to get somewhere, I can help.",
				"But first... I need my dad's engine back.",
				"A giant robot stole it."
			]

		State.QUEST_ACCEPTED:
			return [
				"Please find the engine.",
				"That giant robot ran toward the dark alley."
			]

		State.HAS_ITEM:
			return [
				"You found it?!",
				"...I can't believe it.",
				"Thank you."
			]

		State.QUEST_DONE:
			return [
				"Hop in.",
				"I'll take you wherever you want to go."
			]

	return []

func finish_dialog_state() -> void:
	match current_state:
		State.BEFORE_QUEST:
			current_state = State.QUEST_ACCEPTED

		State.HAS_ITEM:
			if BlessingManager.has_item(required_item):
				BlessingManager.spend_item(required_item, 1)
			current_state = State.QUEST_DONE

		State.QUEST_ACCEPTED, State.QUEST_DONE:
			pass
