extends Area2D

var direction: Vector2 = Vector2(0, 0)
var speed: float = 400.0
var max_range: float = 500.0
var distance_traveled: float = 0.0

func _ready():
	set_collision_layer_value(3, true)
	set_collision_mask_value(1, true)
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 4.0
	collision_shape.shape = shape
	add_child(collision_shape)

func _physics_process(delta: float):
	var velocity = direction * speed * delta
	position += velocity
	distance_traveled += velocity.length()
	
	if distance_traveled >= max_range:
		despawn()
	print("Tear position: ", position, " Distance traveled: ", distance_traveled)

func despawn():
	set_physics_process(false)  # Stop processing immediately
	var main_node = get_tree().current_scene
	if main_node and main_node.has_node("Main"):
		main_node = main_node.get_node("Main")
		if self in main_node.active_tears:
			main_node.active_tears.erase(self)
			print("Tear removed from active_tears. Current count: ", main_node.active_tears.size())
		else:
			print("Tear not found in active_tears during despawn")
	else:
		print("Error: Main node not found when despawning tear")
	queue_free()
	print("Tear despawned: Exceeded max_range (", max_range, ") at distance: ", distance_traveled)
