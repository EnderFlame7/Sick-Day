class_name Entity extends CharacterBody2D

@export_group("Entity Properties")
@export var base_speed : float

@export_group("Necessary Nodes")
@export var collider : Node2D
@export var hurtbox : Area2D
@export var space_area : Area2D
@export var sprite : AnimatedSprite2D
@export var nav_agent : NavigationAgent2D
@export var anim_player : AnimationPlayer
@export var vfx_player : AnimationPlayer

var speed : int
var state
var target
var antibody : Global.Antibody = Global.Antibody.circle
var antibody_texture : CompressedTexture2D
var direction : Vector2
var mouse_hovering : bool = false
var selected : bool = false
var upgrading : bool = false

func _ready() -> void:
	if not speed: speed = base_speed
	space_area.mouse_entered.connect(_on_mouse_entered)
	space_area.mouse_exited.connect(_on_mouse_exited)
	set_motion_mode(CharacterBody2D.MotionMode.MOTION_MODE_FLOATING)
	if target and is_instance_valid(target):
		adjust_sprite(0.0)

func _process(delta: float) -> void:
	apply_visual_effects()
	if target and is_instance_valid(target):
		adjust_sprite(delta)
		

func adjust_sprite(delta : float) -> void:
	if target.global_position.x < global_position.x:
		if sprite.scale.x > 0:
			sprite.scale.x = -abs(sprite.scale.x)
	else:
		if sprite.scale.x < 0:
			sprite.scale.x = abs(sprite.scale.x)
		
	look_at(target.global_position)
	sprite.look_at(target.global_position)
	sprite.global_rotation = clamp(sprite.global_rotation, deg_to_rad(-30), deg_to_rad(30))


func apply_visual_effects() -> void:
	if selected:
		vfx_player.set_current_animation("selected")
		vfx_player.play()
	elif not mouse_hovering:
		vfx_player.set_current_animation("reset")
	else:
		if is_in_group("wbc"):
			vfx_player.set_current_animation("hover")
			vfx_player.play()
		else:
			vfx_player.set_current_animation("reset")


func _on_mouse_entered() -> void:
	mouse_hovering = true
func _on_mouse_exited() -> void:
	mouse_hovering = false
