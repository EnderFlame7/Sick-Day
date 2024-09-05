class_name MeleeWBC extends WBC

@export_group("Melee WBC Tiers")
@export var hit_distance_tiers : Array[int]
@export var speed_tiers : Array[int]

@export_group("Melee WBC Nodes")
@export var hitbox : Area2D
@export var hitbox_collider : CollisionShape2D
@export var attack_area : Area2D
@export var attack_collider : CollisionShape2D
@export var weapon : Node2D
@export var attack_delay : Timer
@export var sfx_player : AudioStreamPlayer

@export_group("Viewport Nodes")
@export var viewport_size : Vector2
@export var viewport : SubViewport
@export var vp_body : AnimatedSprite2D
@export var vp_face : AnimatedSprite2D
@export var vp_weapon : Node2D

var max_hit_distance : int 

func _ready() -> void:
	super._ready()
	max_hit_distance = hit_distance_tiers[tier - 1]
	speed = speed_tiers[tier - 1]
	special_property_values.append(max_hit_distance)
	special_property_values.append(speed)
	nav_agent.set_target_desired_distance(max_hit_distance * 0.9)
	hitbox_collider.set_deferred("disabled", true)
	sfx_player.set_stream(attack_sfx)
	sfx_player.set_volume_db(attack_volume_db)
	adjust_collisions()

func _process(delta: float) -> void:
	super._process(delta)
	
	adjust_collisions()
	
	if target and is_instance_valid(target) and nav_agent.is_target_reachable():
		move_towards_target(delta)
	else:
		anim_player.set_speed_scale(1.0)
		weapon.global_rotation = lerp(weapon.global_rotation, deg_to_rad(0.0), 10 * delta)
		for child in weapon.get_children():
			if child is AnimatedSprite2D:
				child.flip_v = false
				
	update_viewport()
				
func move_towards_target(delta : float) -> void:
	var target_pos : Vector2 = target.global_position
	nav_agent.target_position = target_pos
	direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	if not reached_target():
		anim_player.set_current_animation("move")
		anim_player.set_speed_scale(1.0)
		anim_player.play()
		velocity = direction * speed * delta * 100
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.y = move_toward(velocity.y, 0, speed)
		weapon.look_at(target.global_position)
		attack()
	
	move_and_slide()

func attack() -> void:
	if attack_delay.is_stopped():
		anim_player.stop()
		anim_player.set_current_animation("attack")
		anim_player.set_speed_scale(anim_player.get_current_animation_length() / (1 / attack_rate))
		anim_player.play()
		attack_delay.set_wait_time(1 / attack_rate)
		attack_delay.start(1 / attack_rate)
		
		
func reached_target() -> bool:
	for area in attack_area.get_overlapping_areas():
		if area.owner == target:
			return true
	return false


func adjust_collisions() -> void:
	attack_collider.get_shape().radius = max_hit_distance
	hitbox_collider.get_shape().size = Vector2(float(max_hit_distance), 500.0)
	hitbox_collider.position.x = max_hit_distance / 2


func update_viewport() -> void:
	viewport.size = viewport_size
	vp_body.global_transform = body.global_transform
	vp_face.global_transform = face.global_transform
	vp_weapon.global_transform = weapon.global_transform
	
	for child in vp_weapon.get_child_count():
		if vp_weapon.get_child(child) is AnimatedSprite2D:
			vp_weapon.get_child(child).global_transform = weapon.get_child(child).global_transform
			
	vp_body.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	vp_body.scale = Vector2(1, 1)
	
	for child in vp_weapon.get_child_count():
		if vp_weapon.get_child(child) is AnimatedSprite2D:
			vp_weapon.get_child(child).flip_v = weapon.get_child(child).flip_v


# called from ui script
func _upgrade() -> void:
	super._upgrade()
	max_hit_distance = hit_distance_tiers[tier - 1]
	speed = speed_tiers[tier - 1]
	special_property_values.clear()
	special_property_values.append(max_hit_distance)
	special_property_values.append(speed)
	Global.ui.update_upgrade_panel(self)
	vfx_player.set_current_animation("upgraded")
	vfx_player.play()
