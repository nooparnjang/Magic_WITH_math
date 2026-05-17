extends Node

@export var player: CharacterBody2D
@export var item_selector: Node
@export var camera_rig: Node2D

@export var min_stamina_to_use_target_item: float = 5.0

@export var bomb_item_id: String = "bomb"
@export var bomb_scene: PackedScene
@export var bomb_spawn_offset := Vector2(0, -16)

@export var target_icon_scene: PackedScene
@export var target_icon_offset := Vector2(0, -40)

@export var potion_item_id: String = "potion"
@export var potion_heal_amount: float = 30.0

@export var stamina_potion_item_id: String = "stamina_potion"
@export var stamina_potion_amount: float = 40.0

var is_item_targeting: bool = false
var current_item_id: String = ""

var current_target: Node2D = null
var current_target_index: int = -1
var current_target_icon: Node2D = null


func use_selected_item() -> void:
	if player == null or item_selector == null:
		return

	if _player_is_locked():
		return

	var selected_item_id: String = item_selector.get_selected_item_id()

	if selected_item_id == "":
		return

	match selected_item_id:
		bomb_item_id:
			cycle_target_item(bomb_item_id)

		potion_item_id:
			use_potion()

		stamina_potion_item_id:
			use_stamina_potion()

		"engine_part":
			print("engine_part เป็นไอเท็มเควส ยังใช้ตรงนี้ไม่ได้")

		"scrap":
			print("scrap ยังไม่มีระบบใช้")

		"gem":
			print("gem ยังไม่มีระบบใช้")

		"coin":
			print("coin ยังไม่มีระบบใช้")

		_:
			print("ยังไม่มีระบบใช้ไอเท็มนี้:", selected_item_id)


func confirm_item_use() -> void:
	if not is_item_targeting:
		return

	match current_item_id:
		bomb_item_id:
			throw_bomb_at_current_target()

		_:
			print("ไม่มี confirm action สำหรับ item:", current_item_id)


func cancel_item_use() -> void:
	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	clear_target_icon()

	current_target = null
	current_target_index = -1
	current_item_id = ""
	is_item_targeting = false

	if camera_rig != null and camera_rig.has_method("unlock_focus"):
		camera_rig.unlock_focus()


func cycle_target_item(item_id: String) -> void:
	if player == null:
		return

	if _player_is_locked():
		return

	if not BlessingManager.has_item(item_id, 1):
		print("ไม่มี item:", item_id)
		cancel_item_use()
		return

	if player.has_method("get_stamina"):
		var current_stamina: float = float(player.get_stamina())
		if current_stamina < min_stamina_to_use_target_item:
			print("stamina ไม่พอสำหรับใช้ item:", item_id)
			return

	var valid_targets: Array[Node2D] = _get_valid_targets_from_player()

	if valid_targets.is_empty():
		print("ไม่มี target สำหรับ item:", item_id)
		cancel_item_use()
		return

	if current_target != null and is_instance_valid(current_target):
		if current_target.has_method("set_selected"):
			current_target.set_selected(false)

	clear_target_icon()

	current_target_index += 1
	if current_target_index >= valid_targets.size():
		current_target_index = 0

	current_target = valid_targets[current_target_index]

	if current_target == null or not is_instance_valid(current_target):
		cancel_item_use()
		return

	current_item_id = item_id
	is_item_targeting = true

	if current_target.has_method("set_selected"):
		current_target.set_selected(true)

	if camera_rig != null and camera_rig.has_method("lock_focus"):
		camera_rig.lock_focus(current_target)

	show_target_icon(current_target)

	print("item target:", item_id, current_target.name)


func throw_bomb_at_current_target() -> void:
	if player == null:
		return

	if current_target == null or not is_instance_valid(current_target):
		print("ยังไม่ได้เลือก target")
		cancel_item_use()
		return

	if bomb_scene == null:
		push_warning("ยังไม่ได้ assign bomb_scene")
		return

	if not BlessingManager.has_item(bomb_item_id, 1):
		print("ไม่มี bomb ใน inventory")
		cancel_item_use()
		return

	var bomb = bomb_scene.instantiate()
	get_tree().current_scene.add_child(bomb)

	var spawn_pos: Vector2 = player.global_position + bomb_spawn_offset
	var target_pos: Vector2 = current_target.global_position

	if bomb is Node2D:
		bomb.global_position = spawn_pos

	if bomb is CollisionObject2D:
		bomb.add_collision_exception_with(player)

	if bomb.has_method("throw_to_position"):
		bomb.throw_to_position(spawn_pos, target_pos)
	else:
		push_warning("bomb_scene ไม่มี method throw_to_position(spawn_pos, target_pos)")

	var spent_ok: bool = BlessingManager.spend_item(bomb_item_id, 1)
	if not spent_ok:
		push_warning("หัก bomb ไม่สำเร็จ")

	print("โยน bomb แล้ว")

	cancel_item_use()

	if player.has_method("on_item_use_finished"):
		player.on_item_use_finished()


func use_potion() -> void:
	if player == null:
		return

	if not BlessingManager.has_item(potion_item_id, 1):
		print("ไม่มี potion")
		return

	if player.has_method("heal"):
		player.heal(potion_heal_amount)

	var spent_ok: bool = BlessingManager.spend_item(potion_item_id, 1)
	if not spent_ok:
		push_warning("หัก potion ไม่สำเร็จ")

	print("ใช้ potion ฟื้นเลือด:", potion_heal_amount)


func use_stamina_potion() -> void:
	if player == null:
		return

	if not BlessingManager.has_item(stamina_potion_item_id, 1):
		print("ไม่มี stamina potion")
		return

	if player.has_method("restore_stamina"):
		player.restore_stamina(stamina_potion_amount)

	var spent_ok: bool = BlessingManager.spend_item(stamina_potion_item_id, 1)
	if not spent_ok:
		push_warning("หัก stamina potion ไม่สำเร็จ")

	print("ใช้ stamina potion ฟื้น stamina:", stamina_potion_amount)


func show_target_icon(target: Node2D) -> void:
	clear_target_icon()

	if target_icon_scene == null:
		return

	if target == null or not is_instance_valid(target):
		return

	var icon = target_icon_scene.instantiate()
	target.add_child(icon)

	if icon is Node2D:
		icon.position = target_icon_offset
		icon.z_index = 999

	current_target_icon = icon


func clear_target_icon() -> void:
	if current_target_icon != null and is_instance_valid(current_target_icon):
		current_target_icon.queue_free()

	current_target_icon = null


func is_item_targeting_active() -> bool:
	return is_item_targeting


func has_focus_target() -> bool:
	return is_item_targeting and current_target != null and is_instance_valid(current_target)


func on_target_exited(target: Node2D) -> void:
	if current_target == target:
		cancel_item_use()


func _get_valid_targets_from_player() -> Array[Node2D]:
	var valid_targets: Array[Node2D] = []

	if player == null:
		return valid_targets

	if not player.has_method("get_targets_in_range"):
		push_warning("player ไม่มี method get_targets_in_range()")
		return valid_targets

	var raw_targets: Array = player.get_targets_in_range()

	for target in raw_targets:
		if target is Node2D and is_instance_valid(target):
			valid_targets.append(target)

	return valid_targets


func _player_is_locked() -> bool:
	if player == null:
		return true

	if player.has_method("is_player_dead") and player.is_player_dead():
		return true

	if player.has_method("is_player_interacting") and player.is_player_interacting():
		return true

	return false
