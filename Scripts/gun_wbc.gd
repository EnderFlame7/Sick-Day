class_name GunWBC extends WBC

@export_group("Gun WBC Properties")
@export var using_shotgun : bool = false
@export var using_sniper : bool = false
@export var bullet_speed : int
@export var bullet_count : int = 1
@export var spread : int = 0
@export var piercing : int = 1

@export_group("Gun WBC Tiers")
@export var bullet_count_tiers : Array[int]
@export var spread_tiers : Array[int]
@export var piercing_tiers : Array[int]

@export_group("Gun WBC Nodes")
@export var arm : AnimatedSprite2D
@export var barrel : Marker2D
@export var fire_delay : Timer

@export_group("Viewport Nodes")
@export var viewport_size : Vector2
@export var viewport : SubViewport
@export var vp_body : AnimatedSprite2D
@export var vp_face : AnimatedSprite2D
@export var vp_arm : AnimatedSprite2D

func _ready() -> void:
	super._ready()
	if using_shotgun:
		bullet_count = bullet_count_tiers[tier - 1]
		spread = spread_tiers[tier - 1]
		special_property_values.append(bullet_count)
		special_property_values.append(spread)
	elif using_sniper:
		piercing = piercing_tiers[tier - 1]
		special_property_values.append(piercing)

func _process(delta: float) -> void:
	super._process(delta)
	
	if target and is_instance_valid(target):
		arm.look_at(target.global_position)
		attack()
	else:
		arm.global_rotation = lerp(arm.global_rotation, deg_to_rad(20.0), 10 * delta)
		arm.flip_v = false
		
	update_viewport()

func attack() -> void:
	if fire_delay.is_stopped():
		for i in bullet_count:
			var bullet : Bullet = preload("res://Scenes/bullet.tscn").instantiate()
			bullet.global_position = barrel.global_position
			bullet.global_rotation = arm.global_rotation
			if spread > 0:
				bullet.global_rotation += deg_to_rad(randi_range(-spread/2.0, spread/2.0))
			bullet.damage = damage
			bullet.speed = bullet_speed
			bullet.piercing = piercing
			bullet.antibody = target.antibody
			bullet.target = target
			bullet.sound = attack_sfx
			bullet.sound_volume = attack_volume_db
			bullet.pitch_scale = 1 + randf_range(-0.1, 0.1)
			Global.game.add_child(bullet)
			anim_player.stop()
			anim_player.set_current_animation("attack")
			anim_player.play()
			fire_delay.set_wait_time(1 / attack_rate)
			fire_delay.start(1 / attack_rate)

func update_viewport() -> void:
	viewport.size = viewport_size
	vp_body.global_transform = body.global_transform
	vp_face.global_transform = face.global_transform
	vp_arm.global_transform = arm.global_transform
	vp_body.position = Vector2(viewport_size.x / 2, viewport_size.y / 2)
	vp_body.scale = Vector2(1, 1)
	vp_arm.flip_v = arm.flip_v
	
	
# called from ui script
func _upgrade() -> void:
	super._upgrade()
	if using_shotgun:
		bullet_count = bullet_count_tiers[tier - 1]
		spread = spread_tiers[tier - 1]
		special_property_values.clear()
		special_property_values.append(bullet_count)
		special_property_values.append(spread)
	elif using_sniper:
		piercing = piercing_tiers[tier - 1]
		special_property_values.clear()
		special_property_values.append(piercing)
	Global.ui.update_upgrade_panel(self)
	vfx_player.set_current_animation("upgraded")
	vfx_player.play()
