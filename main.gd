# main.gd
extends Node

@export var mob_scene: PackedScene
@export var safe_area_scene: PackedScene = preload("res://safe_area.tscn")

var score: int

var game_running: bool = false

# Variables to track safe area state.
var safe_area_timer: Timer
var safe_area_active: bool = false
var safe_area_instance: Node = null

func _ready() -> void:
	# Create the safe area timer but do not auto-start it.
	safe_area_timer = Timer.new()
	safe_area_timer.wait_time = 5.0
	safe_area_timer.one_shot = false
	safe_area_timer.autostart = false
	add_child(safe_area_timer)
	safe_area_timer.connect("timeout", Callable(self, "_on_safe_area_timer_timeout"))
	
func _process(delta: float) -> void:
	# (Your existing code, if any.)
	pass

func new_game() -> void:
	score = 0
	$Player.start($StartPosition.position)
	$StartTimer.start()
	
	$HUD.update_score(score)
	$HUD.show_message("Get Ready")
	
	# Remove any existing mobs.
	get_tree().call_group("mobs", "queue_free")
	
	$Music.play()
	
	# Allow the player to shoot.
	$Player.enable_shooting()
	
	# Reset safe area if one is active from before.
	if safe_area_instance:
		safe_area_instance.queue_free()
		safe_area_instance = null
	safe_area_active = false
	
	# Start the safe area timer.
	safe_area_timer.start()
	print("Safe area timer started.")

# Timer callback to toggle safe area.
func _on_safe_area_timer_timeout() -> void:
	if safe_area_active:
		# Remove the safe area.
		if safe_area_instance:
			safe_area_instance.queue_free()
			safe_area_instance = null
		safe_area_active = false
		print("SafeArea removed")
	else:
		# Spawn safe area at a random position.
		safe_area_instance = safe_area_scene.instantiate()
		var viewport_rect = get_viewport().get_visible_rect()
		var random_x = randf_range(viewport_rect.position.x, viewport_rect.position.x + viewport_rect.size.x)
		var random_y = randf_range(viewport_rect.position.y, viewport_rect.position.y + viewport_rect.size.y)
		safe_area_instance.position = Vector2(random_x, random_y)
		add_child(safe_area_instance)
		safe_area_active = true
		print("SafeArea spawned at: ", safe_area_instance.position)

func _on_start_timer_timeout() -> void:
	# Start spawning mobs after the “Get Ready” delay.
	$MobTimer.start()

func _on_mob_timer_timeout() -> void:
	# Create a new mob instance.
	var mob = mob_scene.instantiate()
	
	# Connect the mob's killed signal so we can update the score.
	mob.connect("killed", Callable(self, "_on_mob_killed"))
	
	# Choose a random spawn location along the path.
	var mob_spawn_location = $MobPath/MobSpawnLocation
	mob_spawn_location.progress_ratio = randf()
	
	# Set the mob's direction perpendicular to the path.
	var direction = mob_spawn_location.rotation + PI / 2
	
	mob.position = mob_spawn_location.position
	
	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)
	mob.rotation = direction
	
	# (Optional) If using the chase logic from before, you might remove the initial random linear_velocity.
	# Add the mob to the Main scene.
	add_child(mob)

func _on_mob_killed() -> void:
	score += 1
	$HUD.update_score(score)

func game_over() -> void:
	# Set game_running flag to false.
	game_running = false
	
	$MobTimer.stop()
	$HUD.show_game_over()
	$Music.stop()
	$DeathSound.play()
	
	# Clear all remaining bullets.
	get_tree().call_group("bullets", "queue_free")
	
	# Prevent the player from shooting.
	$Player.disable_shooting()
	
	# Stop the safe area timer.
	safe_area_timer.stop()
	# Remove any active safe area.
	if safe_area_instance:
		safe_area_instance.queue_free()
		safe_area_instance = null
	safe_area_active = false
	print("Safe area timer stopped and safe area removed on game over.")
