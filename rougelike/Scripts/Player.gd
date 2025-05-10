extends CharacterBody2D

var speed = 500.0
var acceleration = 5.0
var current_room: Vector2i = Vector2i(0, 0)
var can_transition: bool = true  # Cooldown flag
signal door_transition(direction: String, room_pos: Vector2i)

func _physics_process(delta):
	var input = Vector2.ZERO
	input.x = int(Input.is_action_pressed("ui_right")) - int(Input.is_action_pressed("ui_left"))
	input.y = int(Input.is_action_pressed("ui_down")) - int(Input.is_action_pressed("ui_up"))
	input = input.normalized()
	
	velocity = lerp(velocity, input * speed, delta * acceleration)
	move_and_slide()

	
	check_door_collision()

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
			var direction = body.name.split("_")[1].to_lower()  # Ensure correct case
			can_transition = false
			emit_signal("door_transition", direction, current_room)
			print("Player collided with door: ", direction, " at ", current_room)
			await get_tree().create_timer(1.0).timeout  # Cooldown
			can_transition = true

func _ready():
	var collision_shape = $CollisionShape2D
	var door_detector = $DoorDetector
	if door_detector:
		print("Player is ready at frame 0 Collision shape: ", collision_shape, " Node type: ", get_class())
		print("DoorDetector layer: ", door_detector.collision_layer, " Mask: ", door_detector.collision_mask)
	else:
		print("Error: DoorDetector node missing")
	collision_layer = 1
	collision_mask = 1  # Only detect floors (1), doors via Area2D
