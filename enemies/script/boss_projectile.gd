extends Area2D

@export var lifetime: float = 4.0
@export var arm_delay: float = 0.05
@export var blocker_group_name: String = "projectile_blocker"

var direction: Vector2 = Vector2.RIGHT
var speed: float = 220.0
var damage: int = 10
var owner_ref: Node = null
var is_destroyed := false
var is_hitting := false
var is_armed := false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")

	# ปิดชนแป๊บหนึ่ง กัน spawn แล้วชนตัวเองทันที
	if collision != null:
		collision.disabled = true

	await get_tree().create_timer(arm_delay).timeout

	if is_destroyed:
		return

	is_armed = true

	if collision != null:
		collision.set_deferred("disabled", false)

	await get_tree().create_timer(max(lifetime - arm_delay, 0.01)).timeout
	if not is_destroyed:
		destroy_projectile()

func setup_projectile(new_direction: Vector2, new_speed: float, new_damage: int, new_owner: Node = null) -> void:
	direction = new_direction.normalized()
	speed = new_speed
	damage = new_damage
	owner_ref = new_owner
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if is_destroyed or is_hitting:
		return

	global_position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	if is_destroyed or is_hitting or not is_armed:
		return

	if body == owner_ref:
		return

	# ชน player = โดนดาเมจ + แตก
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

		start_hit()
		return

	# ชน body ที่เป็นตัวกันกระสุน = แตก
	if body.is_in_group(blocker_group_name):
		start_hit()
		return

	# อย่างอื่นผ่าน
	pass

func _on_area_entered(area: Area2D) -> void:
	if is_destroyed or is_hitting or not is_armed:
		return

	if area == self:
		return

	if area == owner_ref:
		return

	# ชน area ที่เป็นตัวกันกระสุน = แตก
	if area.is_in_group(blocker_group_name):
		start_hit()
		return

	# อย่างอื่นผ่าน
	pass

func start_hit() -> void:
	if is_hitting or is_destroyed:
		return

	is_hitting = true
	direction = Vector2.ZERO

	if collision != null:
		collision.set_deferred("disabled", true)

	set_deferred("monitoring", false)
	set_deferred("monitorable", false)

	if sprite != null and sprite.sprite_frames != null and sprite.sprite_frames.has_animation("hit"):
		sprite.play("hit")
		await sprite.animation_finished

	destroy_projectile()

func destroy_projectile() -> void:
	if is_destroyed:
		return

	is_destroyed = true
	queue_free()
