extends Area2D

@export_category("Laser Settings")
@export var damage_amount := 15 # ความแรงของเลเซอร์

## 📐 ระยะขยับแกน Y ขึ้นข้างบน (หน่วยเป็น Pixel)
## ถ้าอยากให้เลเซอร์ขยับขึ้นไปอีก ให้เพิ่มค่านี้ใน Inspector (เช่น 50, 100, 150)
@export var y_offset_up := 0.0 

## 🎬 ชื่อของ Animation ที่ต้องการให้เล่นตอนโผล่ออกมา
## (เปลี่ยนให้ตรงกับที่คุณตั้งไว้ใน AnimatedSprite2D เช่น "attack" หรือ "default")
@export var play_animation_name := "attack"

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# 1. ขยับแกน Y ขึ้นไปด้านบนตามค่าที่ตั้งไว้ใน Inspector ทันทีที่เลเซอร์เกิด
	if y_offset_up != 0.0:
		global_position.y -= y_offset_up

	# 2. เชื่อมสัญญาณตรวจจับดาเมจผู้เล่น
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	# 3. สั่งเล่นอนิมชันเลเซอร์โผล่ขึ้นมาตามชื่อที่ตั้งไว้
	if sprite != null and sprite.sprite_frames.has_animation(play_animation_name):
		# บังคับให้อนิเมชันเลเซอร์เล่นรอบเดียว ไม่วนลูปซ้ำ
		sprite.sprite_frames.set_animation_loop(play_animation_name, false)
		sprite.play(play_animation_name)
		
		# รอให้อนิเมชันเลเซอร์ยิงจนเสร็จสิ้น จากนั้นลบตัวเองออกจากหน่วยความจำ
		await sprite.animation_finished
	else:
		push_warning("⚠️ [Laser Warning] ไม่พบชื่ออนิเมชัน '" + play_animation_name + "' กรุณาเช็กชื่อใน AnimatedSprite2D ของเลเซอร์")
		# หากระบุชื่ออนิเมชันผิด ให้คงอยู่ 0.5 วินาทีเพื่อป้องกันเกมค้าง แล้วค่อยหายไป
		await get_tree().create_timer(0.5).timeout
	
	queue_free()

# ฟังก์ชันทำดาเมจเมื่อเลเซอร์ผ่าโดนตัวผู้เล่น
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage_amount)
			print("💥 ผู้เล่นโดนเลเซอร์บอสผ่าเข้าให้! ดาเมจ: ", damage_amount)
