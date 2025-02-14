# mob.gd
extends RigidBody2D

signal killed

@export var chase_speed: float = 200.0
var hit_count: int = 0
var in_safe_zone: bool = false  # Track if the mob is inside a safe area.

func _ready() -> void:
	add_to_group("mobs")
	var mob_types = $AnimatedSprite2D.sprite_frames.get_animation_names()
	$AnimatedSprite2D.play(mob_types[randi() % mob_types.size()])

func _physics_process(delta: float) -> void:
	# Only chase the player if not in a safe zone.
	if in_safe_zone:
		linear_velocity = Vector2.ZERO
		return

	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player = players[0]
		var direction = (player.global_position - global_position).normalized()
		linear_velocity = direction * chase_speed
		rotation = direction.angle()
	else:
		linear_velocity = Vector2.ZERO

func hit_by_bullet() -> void:
	hit_count += 1
	if hit_count == 1:
		$AnimatedSprite2D.modulate = Color(1, 0, 0)
	elif hit_count >= 2:
		emit_signal("killed")
		queue_free()

# These methods will be called by the safe area's signals.
func safe_zone_entered() -> void:
	in_safe_zone = true
	# Optionally, you can also stop the mob's animation or change its behavior.
	print("Mob entered safe zone.")

func safe_zone_exited() -> void:
	in_safe_zone = false
	print("Mob exited safe zone.")
