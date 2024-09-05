class_name Genome extends Entity

@export_group("Genome Properties")
@export var temp_value : int

@export_group("Genome Nodes")
@export var death_sfx : AudioStreamPlayer

var dead : bool = false

func _ready() -> void:
	
	speed = base_speed * ceil((2.0 * (Global.game.wave / Global.game.MAX_WAVE)))
	
	super._ready()
	self.add_to_group("genome")
	match antibody:
		0:
			sprite.set_animation("blue")
		1:
			sprite.set_animation("green")
		2:
			sprite.set_animation("yellow")
	target = Global.nucleus
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	sprite.play()
	
func _process(delta: float) -> void:
	look_at(target.global_position)
	if mouse_hovering and Input.is_action_just_pressed("lmb") and not dead:
		dead = true
		death_sfx.set_pitch_scale(randf_range(1.5, 1.65))
		death_sfx.play()
		collider.set_deferred("disabled", true)
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		speed = 0
		match antibody:
			0:
				sprite.set_animation("blue_splat")
			1:
				sprite.set_animation("green_splat")
			2:
				sprite.set_animation("yellow_splat")
		sprite.scale *= 2
		sprite.play()
		await sprite.animation_finished
		hide()
		queue_free()

func _physics_process(delta: float) -> void:
	var target_pos : Vector2 = target.global_position
	nav_agent.target_position = target_pos
	direction = (nav_agent.get_next_path_position() - global_position).normalized()
	
	velocity = direction * speed * delta * 100
	
	move_and_slide()

func _on_hurtbox_entered(area : Area2D) -> void:
	if area.is_in_group("nucleus_hurtbox"):
		collider.set_deferred("disabled", true)
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
		anim_player.set_current_animation("invade")
		anim_player.play()
		await anim_player.animation_finished
		hide()
		queue_free()
