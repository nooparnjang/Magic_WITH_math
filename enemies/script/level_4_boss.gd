extends CharacterBody2D

# ==============================================================================
# Boss Core
# ==============================================================================
@export var boss_name: String = "Projectile Laser Boss"

@export_category("Boss Stats")
@export var max_hp: int = 100
@export var gravity: float = 1200.0
## 📡 ระยะที่บอสจะตื่นและเริ่มสู้ ต้องกว้างกว่า shoot_range เสมอ
@export var activation_range: float = 900.0

@export_category("Movement")
@export var move_speed: float = 80.0
## 🛑 ไกลกว่านี้บอสจะเดินเข้าหา ใกล้กว่านี้ถึงจะยอมยืนยิง
## ต้องตั้งให้ >= shoot_range ไม่งั้นบอสจะเดินเข้ามาก่อนแทนที่จะยิงจากไกล
@export var stop_distance: float = 700.0
@export var too_close_distance: float = 90.0
@export var retreat_when_too_close: bool = true
@export var max_vertical_attack_gap: float = 220.0

@export_category("Contact Damage")
@export var contact_damage: int = 10
@export var contact_damage_cooldown: float = 0.8
## 🚶 ถ้าเปิด ผู้เล่นที่เดินชน Hitbox จะโดนดาเมจทันทีโดยไม่ต้องรอท่าตบ
## ปิดไว้ = โดนเฉพาะตอนบอสตบจริง ๆ (แนะนำให้ปิด เพราะตอนนี้ Hitbox คือระยะตบ)
@export var hitbox_contact_damage: bool = false

@export_category("Melee Skill")
## ⚔️ ท่าตบใช้พื้นที่ของโหนด Hitbox เป็นระยะโจมตี (Hitbox จะหันตามทิศที่บอสหัน)
@export var melee_damage: int = 18
@export var melee_cooldown: float = 1.2
## 📏 ระยะสำรอง เผื่อ Collision Mask ของ Hitbox ตั้งไม่ตรง layer ผู้เล่น
## ผู้เล่นอยู่ใน Hitbox "หรือ" ใกล้กว่าระยะนี้ ก็ถือว่าเข้าระยะตบ (ตั้ง 0 = ใช้ Hitbox อย่างเดียว)
@export var melee_range: float = 70.0
@export var melee_vertical_gap: float = 70.0
## 🐞 เปิดเพื่อ print ระยะและสถานะออก Output ตอนดีบัก
@export var debug_melee: bool = false

@export_category("Projectile Skill")
@export var projectile_scene: PackedScene
@export var projectile_speed: float = 260.0
@export var projectile_damage: int = 12
@export var shoot_cooldown: float = 1.8
@export var shoot_min_range: float = 90.0
## 🎯 ระยะไกลสุดที่บอสยังยิงถึง (ขยายค่านี้ = ยิงได้จากไกลขึ้น)
@export var shoot_range: float = 700.0
@export var shoot_windup: float = 0.15

@export_category("Floor Laser Skill")
@export var marker_root: NodePath
@export var floor_laser_scene: PackedScene
@export var floor_laser_cooldown: float = 2.6
@export var floor_laser_range: float = 9999.0
@export var floor_laser_windup: float = 0.22
@export var floor_laser_count: int = 3
@export var floor_laser_offset_y: float = -100.0

@export_category("Skill AI")
@export var alternate_skills: bool = true
@export_range(0.0, 1.0, 0.01)
var floor_laser_chance: float = 0.45

@export_category("Drops & Rewards")
@export_enum("none", "blessings", "item", "both")
var drop_type: String = "blessings"

@export var blessing_reward: int = 50
@export var hit_effect_scene: PackedScene
@export var floating_text_scene: PackedScene

@export var item_drop_scene: PackedScene
@export var item_drop_count: int = 1
@export var item_drop_id: String = "coin"
@export var item_drop_amount: int = 1
@export var item_drop_texture: Texture2D
@export var randomize_drop: bool = false

@export_range(0.0, 1.0, 0.01)
var blessing_drop_chance: float = 1.0

@export_range(0.0, 1.0, 0.01)
var item_drop_chance: float = 1.0

@export_category("Math Target Config")
@export_enum("3 digits with 1 digit", "2 digits with 1 digit", "1 digit with 1 digit")
var question_pattern := 2

@export var allowed_operators: Array[String] = ["+", "-", "*"]

@export_category("Animation Names")
@export var idle_animation: StringName = &"idle"
@export var walk_animation: StringName = &"walk"
@export var shoot_animation: StringName = &"attack"
@export var laser_animation: StringName = &"fight"
## ⚔️ ชื่ออนิเมชันท่าตบ ถ้าไม่มีอนิเมชันชื่อนี้ จะใช้ laser_animation แทนอัตโนมัติ
@export var melee_animation: StringName = &"melee"
@export var dead_animation: StringName = &"dead"

# ==============================================================================
# Runtime State
# ==============================================================================
var hp: int = 0
var player_ref: Node2D = null

var is_dead: bool = false
var is_activated: bool = false
var is_shooting: bool = false
var is_casting_laser: bool = false
var is_meleeing: bool = false

var can_shoot: bool = true
var can_cast_laser: bool = true
var can_melee: bool = true
var can_contact_damage: bool = true

var markers: Array[Marker2D] = []
var last_skill: String = ""

# ↔️ ทิศที่หันและตำแหน่งเดิมของโหนดที่ต้องสลับฝั่ง (วางไว้ตอนบอสหันขวาใน Editor)
var facing_dir: int = 1
var hitbox_base_x: float = 0.0
var hitbox_shape_base_x: float = 0.0
var shoot_point_base_x: float = 0.0

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
# รองรับทั้ง CollisionShape2D และ CollisionPolygon2D
@onready var body_collision: Node = _get_body_collision()
@onready var hitbox: Area2D = get_node_or_null("Hitbox") as Area2D
@onready var hitbox_collision: CollisionShape2D = get_node_or_null("Hitbox/CollisionShape2D") as CollisionShape2D
@onready var shoot_point: Marker2D = get_node_or_null("ShootPoint") as Marker2D
@onready var status_bar: Node2D = get_node_or_null("Bossstatus") as Node2D


func _get_body_collision() -> Node:
	var shape := get_node_or_null("CollisionShape2D")

	if shape != null:
		return shape

	return get_node_or_null("CollisionPolygon2D")


func _ready() -> void:
	hp = max_hp
	randomize()

	add_to_group("targetable")
	add_to_group("boss")

	# ↔️ จำตำแหน่งเดิมไว้ใช้สลับซ้าย/ขวา
	if hitbox != null:
		hitbox_base_x = hitbox.position.x
	if hitbox_collision != null:
		hitbox_shape_base_x = hitbox_collision.position.x
	if shoot_point != null:
		shoot_point_base_x = shoot_point.position.x

	player_ref = get_tree().get_first_node_in_group("player") as Node2D

	load_laser_markers()

	if hitbox != null:
		if not hitbox.body_entered.is_connected(_on_hitbox_body_entered):
			hitbox.body_entered.connect(_on_hitbox_body_entered)
	else:
		push_warning("Boss ไม่มี Hitbox node")

	if status_bar != null and status_bar.has_method("setup"):
		status_bar.setup(max_hp, hp)


func load_laser_markers() -> void:
	markers.clear()

	if marker_root.is_empty():
		push_warning("marker_root ว่าง: floor laser จะยังใช้ไม่ได้")
		return

	var root := get_node_or_null(marker_root)

	if root == null:
		push_warning("หา marker_root ไม่เจอ: " + str(marker_root))
		return

	for child in root.get_children():
		if child is Marker2D:
			markers.append(child as Marker2D)

	if markers.is_empty():
		push_warning("marker_root ไม่มี Marker2D ลูกเลย")


func activate(player: Node2D) -> void:
	if is_dead:
		return

	player_ref = player
	is_activated = true


func set_player(player: Node2D) -> void:
	player_ref = player


func _physics_process(delta: float) -> void:
	if is_dead:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		return

	update_player_ref()

	if player_ref == null or not is_instance_valid(player_ref):
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		update_animation(Vector2.ZERO)
		return

	var to_player: Vector2 = player_ref.global_position - global_position
	var horizontal_distance: float = abs(to_player.x)
	var vertical_distance: float = abs(to_player.y)

	if to_player.length() <= activation_range:
		is_activated = true

	if not is_activated:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		update_animation(to_player)
		return

	# กำลังร่ายท่าอยู่ ห้ามขยับและห้ามหัน (ไม่งั้น Hitbox จะสลับฝั่งกลางท่า)
	if is_shooting or is_casting_laser or is_meleeing:
		velocity.x = 0.0
		_apply_gravity(delta)
		move_and_slide()
		update_animation(to_player)
		return

	# ↔️ หันตัว + Hitbox + ShootPoint ไปหาผู้เล่นก่อน แล้วค่อยตัดสินใจ
	face_player(to_player)

	decide_movement_and_skill(to_player, horizontal_distance, vertical_distance)

	_apply_gravity(delta)
	move_and_slide()
	update_animation(to_player)


func update_player_ref() -> void:
	if player_ref != null and is_instance_valid(player_ref):
		return

	player_ref = get_tree().get_first_node_in_group("player") as Node2D


func decide_movement_and_skill(to_player: Vector2, horizontal_distance: float, vertical_distance: float) -> void:
	if debug_melee:
		print("h=", int(horizontal_distance), " v=", int(vertical_distance),
			" | in_hitbox=", _is_player_in_hitbox(),
			" in_range=", _is_player_in_melee_range(),
			" can_melee=", can_melee)

	# ⚔️ [ระยะประชิด] ผู้เล่นเข้าระยะตบแล้ว
	if _should_melee():
		velocity.x = 0.0

		if can_melee:
			try_melee_attack()
		elif retreat_when_too_close:
			# ตบไม่ได้เพราะติดคูลดาวน์ ก็ถอยออกไปตั้งหลักก่อน
			velocity.x = -sign(to_player.x) * move_speed

		return

	if vertical_distance > max_vertical_attack_gap:
		# ถ้าผู้เล่นสูง/ต่ำกว่าบอสมาก ให้พยายามใช้เลเซอร์ก่อน
		velocity.x = 0.0

		if can_cast_laser:
			try_cast_floor_laser()
		elif can_shoot and horizontal_distance <= shoot_range:
			try_shoot_projectile()

		return

	if horizontal_distance > stop_distance:
		velocity.x = sign(to_player.x) * move_speed
		return

	# 🚶 ใกล้เกินกว่าจะยิง แต่ยังไม่ถึงระยะตบ
	if horizontal_distance < too_close_distance:
		if can_melee and vertical_distance <= melee_vertical_gap:
			# ท่าตบพร้อมใช้ -> เดินเข้าไปตบ (ห้ามถอย ไม่งั้นจะไม่มีวันได้ตบ)
			velocity.x = sign(to_player.x) * move_speed
		elif retreat_when_too_close:
			# ตบไม่ได้ ค่อยถอยไปตั้งระยะยิง
			velocity.x = -sign(to_player.x) * move_speed
		else:
			velocity.x = 0.0

		return

	velocity.x = 0.0
	try_use_available_skill(horizontal_distance)


func try_use_available_skill(horizontal_distance: float) -> void:
	var shoot_ready := can_shoot and horizontal_distance >= shoot_min_range and horizontal_distance <= shoot_range
	var laser_ready := can_cast_laser and horizontal_distance <= floor_laser_range and not markers.is_empty()

	if shoot_ready and laser_ready:
		if alternate_skills:
			if last_skill == "projectile":
				try_cast_floor_laser()
			elif last_skill == "laser":
				try_shoot_projectile()
			else:
				if randf() <= floor_laser_chance:
					try_cast_floor_laser()
				else:
					try_shoot_projectile()
		else:
			if randf() <= floor_laser_chance:
				try_cast_floor_laser()
			else:
				try_shoot_projectile()

		return

	if shoot_ready:
		try_shoot_projectile()
		return

	if laser_ready:
		try_cast_floor_laser()
		return


# ==============================================================================
# Melee Skill (ใช้พื้นที่ Hitbox เป็นระยะตบ)
# ==============================================================================
# ⚔️ ผู้เล่นอยู่ในพื้นที่ Hitbox หรือไม่
func _is_player_in_hitbox() -> bool:
	if hitbox == null:
		return false

	if player_ref == null or not is_instance_valid(player_ref):
		return false

	if not (player_ref is PhysicsBody2D):
		return false

	return hitbox.overlaps_body(player_ref)


# 📏 ระยะสำรอง (ใช้ตอน Collision Mask ของ Hitbox ตั้งไม่ตรง)
func _is_player_in_melee_range() -> bool:
	if melee_range <= 0.0:
		return false

	if player_ref == null or not is_instance_valid(player_ref):
		return false

	var to_player: Vector2 = player_ref.global_position - global_position

	return abs(to_player.x) <= melee_range and abs(to_player.y) <= melee_vertical_gap


# ⚔️ เข้าระยะตบหรือยัง (อยู่ใน Hitbox หรือใกล้กว่า melee_range)
func _should_melee() -> bool:
	return _is_player_in_hitbox() or _is_player_in_melee_range()


# 🎬 ชื่ออนิเมชันที่จะใช้ตอนตบ (ถ้าไม่มี melee_animation จะใช้ laser_animation แทน)
func get_melee_animation() -> StringName:
	if has_animation(melee_animation):
		return melee_animation

	return laser_animation


func try_melee_attack() -> void:
	if is_dead or is_shooting or is_casting_laser or is_meleeing or not can_melee:
		return

	if not _should_melee():
		return

	is_meleeing = true
	can_melee = false
	last_skill = "melee"
	velocity.x = 0.0

	var anim: StringName = get_melee_animation()
	play_animation_once(anim)

	# 🎬 รอให้อนิเมชันตบเล่นจนจบก่อน
	await wait_current_animation_or_delay(anim, 0.2)

	if is_dead:
		return

	# 💥 ดาเมจออกตอนอนิเมชันจบ และเฉพาะตอนที่ผู้เล่นยังอยู่ในระยะตบ
	if _should_melee() and player_ref != null and is_instance_valid(player_ref) \
			and player_ref.has_method("take_damage"):
		if debug_melee:
			print("💥 บอสตบโดน! ดาเมจ: ", melee_damage)

		player_ref.take_damage(melee_damage)

	is_meleeing = false

	await get_tree().create_timer(melee_cooldown).timeout

	if not is_dead:
		can_melee = true


# ==============================================================================
# Projectile Skill
# ==============================================================================
func try_shoot_projectile() -> void:
	if is_dead or is_shooting or is_casting_laser or is_meleeing or not can_shoot:
		return

	if projectile_scene == null:
		push_warning("projectile_scene ยังไม่ได้ assign")
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	is_shooting = true
	can_shoot = false
	last_skill = "projectile"
	velocity.x = 0.0

	play_animation_once(shoot_animation)

	await get_tree().create_timer(shoot_windup).timeout

	if is_dead:
		return

	shoot_projectile()

	await wait_current_animation_or_delay(shoot_animation, 0.12)

	if is_dead:
		return

	is_shooting = false

	await get_tree().create_timer(shoot_cooldown).timeout

	if not is_dead:
		can_shoot = true


func shoot_projectile() -> void:
	if projectile_scene == null:
		return

	if player_ref == null or not is_instance_valid(player_ref):
		return

	var projectile := projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)

	var spawn_pos := global_position + Vector2(0, -20)

	if shoot_point != null:
		spawn_pos = shoot_point.global_position

	if projectile is Node2D:
		(projectile as Node2D).global_position = spawn_pos

	var dir := (player_ref.global_position - spawn_pos).normalized()

	if projectile.has_method("setup_projectile"):
		projectile.setup_projectile(dir, projectile_speed, projectile_damage, self)
	else:
		push_warning("Projectile ไม่มี method setup_projectile(dir, speed, damage, owner)")


# ==============================================================================
# Floor Laser Skill
# ==============================================================================
func try_cast_floor_laser() -> void:
	if is_dead or is_shooting or is_casting_laser or is_meleeing or not can_cast_laser:
		return

	if floor_laser_scene == null:
		push_warning("floor_laser_scene ยังไม่ได้ assign")
		return

	if markers.is_empty():
		push_warning("ไม่มี Marker2D สำหรับ floor laser")
		return

	is_casting_laser = true
	can_cast_laser = false
	last_skill = "laser"
	velocity.x = 0.0

	if player_ref != null and is_instance_valid(player_ref):
		face_player(player_ref.global_position - global_position)

	play_animation_once(laser_animation)

	await get_tree().create_timer(floor_laser_windup).timeout

	if is_dead:
		return

	spawn_floor_lasers()

	await wait_current_animation_or_delay(laser_animation, 0.15)

	if is_dead:
		return

	is_casting_laser = false

	await get_tree().create_timer(floor_laser_cooldown).timeout

	if not is_dead:
		can_cast_laser = true


func spawn_floor_lasers() -> void:
	var available_markers: Array[Marker2D] = []

	for marker in markers:
		if marker != null:
			available_markers.append(marker)

	available_markers.shuffle()

	var attack_count: int = min(floor_laser_count, available_markers.size())

	for i in range(attack_count):
		var target_marker: Marker2D = available_markers[i]

		if target_marker == null:
			continue

		var laser: Node = floor_laser_scene.instantiate()
		get_tree().current_scene.add_child(laser)

		if laser is Node2D:
			var laser_node := laser as Node2D
			laser_node.global_position = target_marker.global_position + Vector2(0, floor_laser_offset_y)

		if laser.has_method("setup"):
			laser.call("setup", self)

		play_floor_laser_animation(laser)


func play_floor_laser_animation(laser: Node) -> void:
	if laser == null:
		return

	var effect_sprite := laser.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if effect_sprite == null:
		return

	if effect_sprite.sprite_frames == null:
		return

	if effect_sprite.sprite_frames.has_animation("attack"):
		effect_sprite.play("attack")
		return

	if effect_sprite.sprite_frames.has_animation("default"):
		effect_sprite.play("default")
		return

	var anim_names := effect_sprite.sprite_frames.get_animation_names()

	if anim_names.size() > 0:
		effect_sprite.play(anim_names[0])


# ==============================================================================
# Damage / Death
# ==============================================================================
func take_damage(amount: int) -> void:
	if is_dead:
		return

	is_activated = true
	hp -= amount
	hp = max(hp, 0)

	if status_bar != null and status_bar.has_method("set_health"):
		status_bar.set_health(hp, max_hp)

	flash_hit()

	if hp <= 0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	is_shooting = false
	is_casting_laser = false
	is_meleeing = false
	can_shoot = false
	can_cast_laser = false
	can_melee = false
	velocity = Vector2.ZERO

	LeaderboardManager.add_kill()

	remove_from_group("targetable")

	if body_collision != null:
		body_collision.set_deferred("disabled", true)

	if hitbox_collision != null:
		hitbox_collision.set_deferred("disabled", true)

	if status_bar != null:
		status_bar.visible = false

	handle_drops()
	spawn_death_effect()

	# 💀 เล่นอนิเมชันตาย แล้วลบตัวเองทิ้งเสมอ
	# ใช้ตัวจับเวลาแทนการ await animation_finished เพราะถ้า animation ตั้ง Loop ไว้
	# สัญญาณ animation_finished จะไม่ยิงเลย ทำให้บอสค้างอยู่บนจอไม่หายไป
	if has_animation(dead_animation):
		sprite.sprite_frames.set_animation_loop(dead_animation, false)
		sprite.play(dead_animation)

		await get_tree().create_timer(get_animation_length(dead_animation) + 0.05).timeout

	queue_free()


# ⏱️ คำนวณความยาวของอนิเมชันเป็นวินาที (ใช้กันบอสค้างตอนตาย)
func get_animation_length(animation_name: StringName) -> float:
	if not has_animation(animation_name):
		return 0.0

	var frames := sprite.sprite_frames
	var speed: float = frames.get_animation_speed(animation_name)
	var frame_count: int = frames.get_frame_count(animation_name)

	if speed <= 0.0 or frame_count <= 0:
		return 0.5

	var total: float = 0.0

	for i in range(frame_count):
		total += frames.get_frame_duration(animation_name, i) / speed

	return total


func handle_drops() -> void:
	match drop_type:
		"none":
			pass

		"blessings":
			try_drop_blessing()

		"item":
			try_drop_item()

		"both":
			try_drop_blessing()
			try_drop_item()


func try_drop_blessing() -> void:
	if randomize_drop and randf() > blessing_drop_chance:
		return

	if blessing_reward <= 0:
		return

	BlessingManager.add_blessings(blessing_reward)
	show_blessing_popup()


func show_blessing_popup() -> void:
	if floating_text_scene == null:
		return

	var popup := floating_text_scene.instantiate()
	get_tree().current_scene.add_child(popup)

	if popup.has_method("show_at"):
		popup.show_at(global_position + Vector2(-40, -98), blessing_reward)


func try_drop_item() -> void:
	if item_drop_scene == null:
		return

	if item_drop_id.is_empty():
		return

	if randomize_drop and randf() > item_drop_chance:
		return

	for i in range(item_drop_count):
		var item := item_drop_scene.instantiate()
		get_tree().current_scene.add_child(item)

		if item is Node2D:
			(item as Node2D).global_position = global_position + Vector2(
				randf_range(-12.0, 12.0),
				randf_range(-8.0, 8.0)
			)
			(item as Node2D).z_index = 999

		if item.has_method("setup_item"):
			item.setup_item(item_drop_id, item_drop_amount, item_drop_texture)

		if item.has_method("initialize_spawn"):
			item.initialize_spawn()


func spawn_death_effect() -> void:
	if hit_effect_scene == null:
		return

	var effect := hit_effect_scene.instantiate()
	get_tree().current_scene.add_child(effect)

	if effect is Node2D:
		(effect as Node2D).global_position = global_position
		(effect as Node2D).z_index = 100

	var effect_sprite := effect.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if effect_sprite == null:
		return

	if effect_sprite.sprite_frames == null:
		return

	if effect_sprite.sprite_frames.has_animation("default"):
		effect_sprite.sprite_frames.set_animation_loop("default", false)
		effect_sprite.play("default")


func flash_hit() -> void:
	if sprite == null:
		return

	sprite.modulate = Color(1.8, 0.7, 0.7)

	await get_tree().create_timer(0.08).timeout

	if not is_dead and sprite != null:
		sprite.modulate = Color(1, 1, 1)


# ==============================================================================
# Contact Damage
# ==============================================================================
func _on_hitbox_body_entered(body: Node) -> void:
	if is_dead:
		return

	if not body.is_in_group("player"):
		return

	player_ref = body as Node2D
	is_activated = true

	# 🚫 ปิดอยู่ = ไม่ทำดาเมจตอนเดินชน ปล่อยให้ท่าตบเป็นคนออกดาเมจเอง
	if not hitbox_contact_damage:
		return

	if not can_contact_damage:
		return

	if body.has_method("take_damage"):
		body.take_damage(contact_damage)

	start_contact_damage_cooldown()


func start_contact_damage_cooldown() -> void:
	can_contact_damage = false

	await get_tree().create_timer(contact_damage_cooldown).timeout

	if not is_dead:
		can_contact_damage = true


# ==============================================================================
# Animation / Movement Helpers
# ==============================================================================
func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0


# ↔️ หันรูป พร้อมสลับฝั่งของ Hitbox และ ShootPoint ไปทางเดียวกัน
func face_player(to_player: Vector2) -> void:
	if to_player.x == 0.0:
		return

	facing_dir = -1 if to_player.x < 0.0 else 1

	if sprite != null:
		sprite.flip_h = facing_dir < 0

	var side: float = float(facing_dir)

	if hitbox != null:
		hitbox.position.x = hitbox_base_x * side
	if hitbox_collision != null:
		hitbox_collision.position.x = hitbox_shape_base_x * side
	if shoot_point != null:
		shoot_point.position.x = shoot_point_base_x * side


func update_animation(direction: Vector2) -> void:
	if sprite == null or is_dead:
		return

	if is_meleeing:
		var melee_anim: StringName = get_melee_animation()

		if has_animation(melee_anim):
			if sprite.animation != melee_anim:
				sprite.play(melee_anim)
		return

	if is_shooting:
		if has_animation(shoot_animation):
			if sprite.animation != shoot_animation:
				sprite.play(shoot_animation)
		return

	if is_casting_laser:
		if has_animation(laser_animation):
			if sprite.animation != laser_animation:
				sprite.play(laser_animation)
		return

	face_player(direction)

	if abs(velocity.x) > 5.0:
		if has_animation(walk_animation) and sprite.animation != walk_animation:
			sprite.play(walk_animation)
	else:
		if has_animation(idle_animation) and sprite.animation != idle_animation:
			sprite.play(idle_animation)


func play_animation_once(animation_name: StringName) -> void:
	if sprite == null:
		return

	if not has_animation(animation_name):
		return

	sprite.sprite_frames.set_animation_loop(animation_name, false)
	sprite.play(animation_name)


func wait_current_animation_or_delay(animation_name: StringName, fallback_delay: float) -> void:
	if sprite == null:
		await get_tree().create_timer(fallback_delay).timeout
		return

	if not has_animation(animation_name):
		await get_tree().create_timer(fallback_delay).timeout
		return

	# เช็ก is_playing ด้วย กันค้างถ้าอนิเมชันเล่นจบไปก่อนแล้ว
	if sprite.animation == animation_name and sprite.is_playing():
		await sprite.animation_finished
	else:
		await get_tree().create_timer(fallback_delay).timeout


func has_animation(animation_name: StringName) -> bool:
	if sprite == null:
		return false

	if sprite.sprite_frames == null:
		return false

	return sprite.sprite_frames.has_animation(animation_name)
