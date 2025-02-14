# bullet.gd
extends Area2D

@export var speed: float = 800.0
var velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("bullets")
	# Connect the Area2D signal for collisions.
	self.connect("body_entered", Callable(self, "_on_body_entered"))

func _physics_process(delta: float) -> void:
	position += velocity * delta

func _on_body_entered(body: Node) -> void:
	# Ignore collisions with the player.
	if body.is_in_group("player"):
		return
	if body.is_in_group("mobs"):
		body.hit_by_bullet()
		queue_free()
