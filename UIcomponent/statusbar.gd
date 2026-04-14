extends Node2D

@onready var health_bar: TextureProgressBar = $VBoxContainer/healthbar
@onready var stamina_bar: TextureProgressBar = $VBoxContainer/staminabar

func setup(max_hp: float, hp: float, max_stamina: float, stamina: float) -> void:
	health_bar.min_value = 0
	health_bar.max_value = max_hp
	health_bar.value = hp

	stamina_bar.min_value = 0
	stamina_bar.max_value = max_stamina
	stamina_bar.value = stamina

func set_health(hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = clamp(hp, 0.0, max_hp)

func set_stamina(stamina: float, max_stamina: float) -> void:
	stamina_bar.max_value = max_stamina
	stamina_bar.value = clamp(stamina, 0.0, max_stamina)
