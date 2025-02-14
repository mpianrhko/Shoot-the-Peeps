extends CharacterBody2D

signal hit

@export var speed: float = 400.0  # Movement speed (pixels/sec)
@export var bullet_scene: PackedScene = preload("res://bullet.tscn")
@export var push_force: float = 5.0

var can_shoot: bool = false
var screen_size: Vector2

func _ready() -> void:

	# Determine the visible screen bounds.
	screen_size = get_viewport().get_visible_rect().size
	add_to_group("player")
	disable_shooting()
	
	# (Optional) Hide at startup if desired.
	hide()
	
	# It is recommended to handle collision signals via a child Area2D.
	# For example, if you have an Area2D child named "CollisionDetector":
	if $CollisionDetector:
		$CollisionDetector.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	# --- Gather Input ---
	var input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	)
	
	if input_vector != Vector2.ZERO:
		input_vector = input_vector.normalized()
		$AnimatedSprite2D.play()
	else:
		$AnimatedSprite2D.stop()
	
	# --- Movement ---
	velocity = input_vector * speed
	# In Godot 4, CharacterBody2D.move_and_slide() takes no arguments.
	move_and_slide()
	
	# --- Clamp Position ---
	position = position.clamp(Vector2.ZERO, screen_size)
	
	# --- Apply Impulse to Boxes ---
	var collision_count = get_slide_collision_count()
	for i in range(collision_count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		if collider is RigidBody2D and collider.is_in_group("boxes"):
			# The collision normal points out of the rigid body,
			# so we reverse it to push the box away from the player.
			var impulse = -collision.get_normal() * push_force
			print("Applying impulse:", impulse, "to", collider.name)
			collider.apply_central_impulse(impulse)
	
	# --- Update Sprite Animation/Direction ---
	if input_vector.x != 0:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_v = false
		$AnimatedSprite2D.flip_h = input_vector.x < 0
	elif input_vector.y != 0:
		$AnimatedSprite2D.animation = "up"
		$AnimatedSprite2D.flip_h = input_vector.y > 0

func _input(event: InputEvent) -> void:
	# Only shoot if shooting is enabled.
	if not can_shoot:
		return

	if Input.is_action_just_pressed("shoot_bullet"):
		if bullet_scene:
			var bullet = bullet_scene.instantiate()
			# Determine the direction from the player to the mouse.
			var direction = (get_global_mouse_position() - global_position).normalized()
			if direction.length() == 0:
				direction = Vector2.RIGHT  # Fallback if mouse is exactly at player's position.
			# Offset the bullet spawn so it doesn't appear inside the player.
			var offset_distance = 20.0
			bullet.position = global_position + direction * offset_distance
			bullet.velocity = direction * bullet.speed
			bullet.rotation = direction.angle()
			get_tree().current_scene.add_child(bullet)

# This method is called when the CollisionDetector Area2D detects an overlap.
func _on_body_entered(body: Node) -> void:
	# Ignore bullets.
	if body.is_in_group("bullets"):
		return

	# Collision with mobs causes player death.
	if body.is_in_group("mobs"):
		print("Player collided with mob: ", body.name)
		hide()            # Hide the player.
		hit.emit()        # Emit the hit signal.
		
		# Disable collisions on the player by setting the player's collision layers/masks to 0.
		self.collision_layer = 0
		self.collision_mask = 0
		
		# Disable the CollisionDetector.
		if $CollisionDetector:
			$CollisionDetector.collision_layer = 0
			$CollisionDetector.collision_mask = 0
			$CollisionDetector.monitoring = false
		
		# Stop all processing.
		set_process(false)
		set_physics_process(false)
		set_process_input(false)
		remove_from_group("player")
		return

	# Collision with boxes: push the box.
	if body.is_in_group("boxes"):
		print("Player colliding with box: ", body.name, " pushing it")
		var push_direction = (body.global_position - global_position).normalized()
		# Optionally, you can base push force on player's velocity; here we use a constant.
		var push_force = push_direction * 500   # Adjust the force magnitude as needed.
		if body is RigidBody2D:
			body.apply_impulse(Vector2.ZERO, push_force)
		# (You might also want to prevent further processing here if desired.)

	# (Add additional collision handling here for safe areas, moving boxes, or blocks if needed.)

func start(pos: Vector2) -> void:
	position = pos
	show()
	add_to_group("player")
	
	# Re-enable the player's collision (assuming layer 1 is used).
	self.collision_layer = 1
	self.collision_mask = 1
	$CollisionShape2D.disabled = false
	
	# Re-enable the CollisionDetector if it exists.
	if $CollisionDetector:
		$CollisionDetector.collision_layer = 1
		$CollisionDetector.collision_mask = 1
		$CollisionDetector.monitoring = true
	
	# Re-enable processing.
	set_process(true)
	set_physics_process(true)
	set_process_input(true)
	
	print("Player restarted and collisions re-enabled.")


func enable_shooting() -> void:
	can_shoot = true
	print("Shooting enabled.")

func disable_shooting() -> void:
	can_shoot = false
	print("Shooting disabled.")
