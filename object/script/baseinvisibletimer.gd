extends StaticBody2D

@export var disappear_time: float = 3.0
@export var respawn_time: float = 3.0
@export var blink_speed: float = 0.15
@export var wait_a: float = 1.5

var timer_started := false


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("เหยียบ:", body.name)

	if body.is_in_group("player") and !timer_started:
		timer_started = true
		
		
		await waitbeforeblink()
		
		disappear()
		
		await get_tree().create_timer(respawn_time).timeout
		
		respawn()

func waitbeforeblink():
	await get_tree().create_timer(wait_a).timeout
	
	blink_warning()
	

func blink_warning():
	var time_passed := 0.0
	
	while time_passed < disappear_time:
		$Sprite2D.visible = false
		await get_tree().create_timer(blink_speed).timeout
		
		$Sprite2D.visible = true
		await get_tree().create_timer(blink_speed).timeout
		
		time_passed += blink_speed * 2


func disappear():
	print("พื้นหาย")
	
	$CollisionShape2D.disabled = true
	$Sprite2D.hide()


func respawn():
	print("พื้นกลับมา")
	
	$CollisionShape2D.disabled = false
	$Sprite2D.show()
	
	timer_started = false
