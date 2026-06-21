extends Area2D

@export var player_group: StringName = "player"
@export var kill_delay: float = 0.0

var already_triggered: bool = false


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if already_triggered:
		return

	if not body.is_in_group(player_group):
		return

	already_triggered = true

	if kill_delay > 0.0:
		await get_tree().create_timer(kill_delay).timeout

	kill_player(body)
	

func kill_player(player: Node) -> void:
	# วิธีที่ดีที่สุด: ให้ Player มีฟังก์ชัน die()
	if player.has_method("die"):
		player.die()
		return

	# สำรอง: ถ้าไม่มี die() แต่มี take_damage()
	if player.has_method("take_damage"):
		player.take_damage(999999)
		return

	# สำรองสุดท้าย: ลบ Player ออกจากฉาก
	player.queue_free()
