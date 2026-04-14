extends Control

@onready var value_label: Label = get_node_or_null("value")

var current_value: int = 0
var tween: Tween

func _ready() -> void:
	if value_label == null:
		push_error("value_label หาไม่เจอ! เช็ค path")
		return

	# sync ค่าตอนเริ่ม
	set_value(BlessingManager.get_blessings())

	# กันการ connect ซ้ำ
	if not BlessingManager.blessings_changed.is_connected(_on_blessings_changed):
		BlessingManager.blessings_changed.connect(_on_blessings_changed)

func _on_blessings_changed(new_value: int) -> void:
	# ถ้าอยากให้เลขเด้งเฉพาะตอนเพิ่ม/ลด ให้เช็กก่อน
	if new_value != current_value:
		set_value(new_value)
		play_feedback()

func set_value(v: int) -> void:
	if value_label == null:
		return

	current_value = max(v, 0)
	value_label.text = str(current_value)

func play_feedback() -> void:
	if tween != null and tween.is_running():
		tween.kill()

	scale = Vector2(1.15, 1.15)

	tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.12)
