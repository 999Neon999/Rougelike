extends CharacterBody2D

var speed = 500.0
var acceleration = 5.0
var current_room: Vector2i = Vector2i(0, 0)
var can_transition: bool = true
signal door_transition(direction: String, room_pos: Vector2i)

@export var stats: Stats = preload("res://Scripts/Stats.tres")
var tear_scene = preload("res://Scenes/Tear.tscn")
var can_shoot: bool = true
var tear_timer: float = 0.0

func _ready():
	var collision_shape = $CollisionShape2D
	var door_detector = $DoorDetector
	if door_detector:
		print("Player is ready at frame 0 Collision shape: ", collision_shape, " Node type: ", get_class())
		print("DoorDetector layer: ", door_detector.collision_layer, " Mask: ", door_detector.collision_mask)
	else:
		print("Error: DoorDetector node missing")
	collision_layer = 1
	collision_mask = 1
	print("Player stats loaded - Range: ", stats.range)

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	input = input.normalized()
	
	velocity = lerp(velocity, input * speed, delta * acceleration)
	move_and_slide()
	
	handle_shooting(delta)
	check_door_collision()

func handle_shooting(delta):
	if not can_shoot:
		tear_timer -= delta
		if tear_timer <= 0:
			can_shoot = true
	
	var shoot_direction = Vector2.ZERO
	if Input.is_action_pressed("shoot_up"):
		shoot_direction = Vector2(0, -1)
	elif Input.is_action_pressed("shoot_down"):
		shoot_direction = Vector2(0, 1)
	elif Input.is_action_pressed("shoot_left"):
		shoot_direction = Vector2(-1, 0)
	elif Input.is_action_pressed("shoot_right"):
		shoot_direction = Vector2(1, 0)
	
	if shoot_direction != Vector2.ZERO and can_shoot:
		shoot_tear(shoot_direction)
		can_shoot = false
		tear_timer = stats.get_tear_delay()

func shoot_tear(direction: Vector2):
	var tear = tear_scene.instantiate()
	if not tear:
		print("Error: Failed to instantiate Tear scene")
		return
	if not tear.has_method("_physics_process"):
		print("Error: Tear instance does not have expected script")
		tear.queue_free()
		return
	tear.position = position
	tear.set("direction", direction)
	tear.set("speed", stats.shot_speed * 400.0)
	tear.set("max_range", stats.range)
	print("Setting tear - Direction: ", direction, " Speed: ", stats.shot_speed * 400.0, " Max Range: ", stats.range)
	get_tree().current_scene.add_child(tear)
	# Add tear to active_tears in Main.gd
	var main_node = get_tree().current_scene
	if main_node and main_node.has_node("Main"):
		main_node = main_node.get_node("Main")
		main_node.active_tears.append(tear)
	print("Shot tear in direction: ", direction, " at position: ", tear.position)

func check_door_collision():
	if not can_transition:
		return
	var door_detector = $DoorDetector
	if not door_detector:
		print("Error: DoorDetector not found")
		return
	var overlapping_bodies = door_detector.get_overlapping_bodies()
	for body in overlapping_bodies:
		print("Overlapping body: ", body.name, " Type: ", body.get_class())
		if body is StaticBody2D and "Door" in body.name:
			var direction = body.name.split("_")[1].to_lower()
			# Despawn all tears immediately upon touching the door
			var main_node = get_tree().current_scene
			if main_node and main_node.has_node("Main"):
				main_node = main_node.get_node("Main")
				for tear in main_node.active_tears:
					if is_instance_valid(tear):
						tear.queue_free()
				main_node.active_tears.clear()
				print("Despawned all tears immediately upon touching door: ", direction, " at ", current_room)
			can_transition = false
			emit_signal("door_transition", direction, current_room)
			print("Player collided with door: ", direction, " at ", current_room)
			await get_tree().create_timer(1.0).timeout
			can_transition = true

func take_damage(amount: float):
	stats.health -= amount
	print("Player took damage: ", amount, " Health remaining: ", stats.health)
	if stats.health <= 0:
		if stats.lives > 0:
			stats.lives -= 1
			stats.health = stats.max_health
			print("Player revived with ", stats.lives, " lives remaining")
		else:
			print("Player died")
			queue_free()
