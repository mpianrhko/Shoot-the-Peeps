# safe_area.gd
extends Area2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("mobs"):
		# Tell the mob it has entered a safe zone.
		body.safe_zone_entered()

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("mobs"):
		# Tell the mob it has left the safe zone.
		body.safe_zone_exited()
