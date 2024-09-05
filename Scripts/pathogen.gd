class_name Pathogen extends Entity

@export_group("Pathogen Properties")
@export var base_health : int
@export var base_dna_value : int
@export var lock_time : float
@export var invade_rate : float
@export var genome_count : float
@export var face : AnimatedSprite2D
@export var health_bar : TextureProgressBar
@export var death_sfx : AudioStreamPlayer
@export var health_label : Label

var health : int
@onready var MAX_HEALTH = health

var dna_value : int
var distance_to_lock : float

var dead : bool = false
signal increment_kill_count

enum State {
	moving,
	locking,
	invading,
	dying,
}

func _ready() -> void:
	super._ready()
	self.add_to_group("pathogen")
	increment_kill_count.connect(Global.game._increment_kill_count)
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	state = State.moving
	sprite.set_animation("body")
	sprite.set_frame_and_progress(antibody, 0.0)
	face.set_frame_and_progress(antibody, 0.0)
	health_bar.hide()
	anim_player.set_current_animation("move")
	anim_player.play()
	#print(state)

func _process(delta: float) -> void:
	if not dead:
		super._process(delta)
		target = calculate_nearest_target()
		check_for_lock()
		update_health_bar()
		if state == State.invading and not dead:
			anim_player.stop()
			shake(2.0)
	else:
		health_bar.hide()
		

func _physics_process(delta: float) -> void:
	#if is_instance_valid(target):
	var target_pos : Vector2
	if target:
		target_pos = target.global_position
		distance_to_lock = sqrt(global_position.distance_squared_to(target_pos))
	nav_agent.target_position = target_pos
	direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	if state == State.moving:
		#sprite.set_animation("fly")
		#sprite.play()
		var intended_velocity = direction * speed * delta * 100
		nav_agent.set_velocity(intended_velocity)
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
	
	#move_and_slide()
	
	
func calculate_nearest_target() -> Node:
	var nearest_lock : Node = null
	var min_dist : float = 9999999
	for lock in Global.cell.all_locks.get_children():
		var distance = sqrt(global_position.distance_squared_to(lock.global_position))
		if distance < min_dist:
			min_dist = distance
			nearest_lock = lock
			
	return nearest_lock
	
	
func check_for_lock() -> void:
	if not state == State.locking:
		for area in hurtbox.get_overlapping_areas():
			if area.is_in_group("cell_hurtbox") and nav_agent.is_target_reached():
				lock()
		
func lock() -> void:
	state = State.locking
	#print(state)
	await get_tree().create_timer(lock_time).timeout
	invade()
	
func invade() -> void:
	state = State.invading
	#print(state)

	for g in genome_count:
		if not dead:
			var genome : Genome = preload("res://Scenes/genome.tscn").instantiate()
			genome.global_position = global_position
			genome.antibody = antibody
			Global.game.all_genomes.add_child(genome)
			await get_tree().create_timer(1 / invade_rate).timeout

	increment_kill_count.emit()
	hide()
	queue_free()
	
	
func update_health_bar() -> void:
	if mouse_hovering or selected:
		health_bar.min_value = 0
		health_bar.max_value = MAX_HEALTH
		health_bar.step = 1
		health_bar.set_value(health)
		health_label.set_text(str(health))
		health_bar.rotation = -global_rotation
		health_bar.show()
	else:
		health_bar.hide()
	
	
func _on_hurtbox_entered(area : Area2D) -> void:
	if area.is_in_group("ally_hitbox"):
		if (area.owner is Bullet and (area.owner.target == self or area.owner.contacts > 0)) or area.owner is WBC:
			health -= area.owner.damage
			var impact_vfx : GPUParticles2D = preload("res://Scenes/VFX/pathogen_impact.tscn").instantiate()
			impact_vfx.global_position = global_position
			impact_vfx.global_rotation = area.owner.rotation
			impact_vfx.set_texture(antibody_texture)
			Global.game.add_child(impact_vfx)
			vfx_player.set_current_animation("hit")
			vfx_player.play()
		if health <= 0 and not dead:
			die()


func detect_selection() -> void:
	if Global.game.detected_double_tap("lmb") and mouse_hovering and not selected:
		if Global.game.selected_pathogen:
			Global.game.selected_pathogen.selected = false
		selected = true
		Global.game.selected_pathogen = self

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()


func die():
	dead = true
	speed = 0
	face.hide()
	match antibody:
		0:
			sprite.set_animation("blue_splat")
		1:
			sprite.set_animation("green_splat")
		2:
			sprite.set_animation("yellow_splat")
	sprite.scale *= 2
	global_rotation = deg_to_rad(0.0)
	sprite.play()
	collider.set_deferred("disabled", true)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	Global.game.dna += dna_value + abs(snapped(health / 2, 1))
	var explosion_vfx : GPUParticles2D = preload("res://Scenes/VFX/pathogen_explosion_vfx.tscn").instantiate()
	explosion_vfx.global_position = global_position
	explosion_vfx.set_texture(antibody_texture)
	Global.game.add_child(explosion_vfx)
	var point_popup : PointPopup = preload("res://point_popup.tscn").instantiate()
	point_popup.global_position = global_position
	point_popup.dna_value = dna_value
	if health < 0:
		point_popup.overkill = true
		point_popup.overkill_value = abs(snapped(health / 2, 1))
	add_child(point_popup)
	death_sfx.set_volume_db(-25.0)
	death_sfx.set_pitch_scale(death_sfx.pitch_scale + randf_range(0.0, 0.35))
	death_sfx.play()
	await death_sfx.finished
	increment_kill_count.emit()
	queue_free()


func shake(intensity : float) -> void:
	sprite.position = Vector2(0 + randf_range(-intensity, intensity), 0 + randf_range(-intensity, intensity))
