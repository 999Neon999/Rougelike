extends Resource

class_name Stats

@export var lives: int = 0
@export var health: float = 3.0
@export var max_health: float = 3.0
@export var tears: float = 2.73
@export var shot_speed: float = 1.0
@export var range: float = 500.0  # Reduced from 760 to 500
@export var tear_height: float = 10.0
@export var knockback_factor: float = 1.0

func get_tear_delay() -> float:
	return 1.0 / tears

func calculate_knockback() -> float:
	return shot_speed * knockback_factor
