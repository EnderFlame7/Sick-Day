class_name Nucleus extends CharacterBody2D

@export var speed : float

const BASE_RADIUS : float = 35.0
@export var radius : int = BASE_RADIUS

@onready var face : AnimatedSprite2D = %Face
@onready var body : AnimatedSprite2D = %Body
@onready var collider : CollisionShape2D = %Collider
@onready var hurtbox : Area2D = %Hurtbox
@onready var hurtbox_collider : CollisionShape2D = %HurtboxCollider

var panicking : bool = true	# changed from cell script
signal increase_temp(amount)

func _ready() -> void:
	Global.nucleus = self
	hurtbox.area_entered.connect(_on_hurtbox_entered)
	increase_temp.connect(Global.game._increase_temp)
	adjust_size()
	look_at(Vector2(randi_range(0, get_viewport_rect().size.x), randi_range(0, get_viewport_rect().size.y)))
	
func _process(delta: float) -> void:
	
	global_rotation = deg_to_rad(0.0)
	
	if panicking:
		face.set_frame_and_progress(1, 0.0)
		body.set_frame_and_progress(1, 0.0)
		shake(1.0)
	else:
		face.set_frame_and_progress(0, 0.0)
		body.set_frame_and_progress(0, 0.0)
		body.position = Vector2.ZERO

	move_and_slide()

func adjust_size() -> void:
	body.global_scale = Vector2(radius / (513 / 2.0), radius / (509 / 2.0))
	collider.get_shape().radius = radius
	hurtbox_collider.get_shape().radius = radius + 1


func shake(intensity : float) -> void:
	body.position = Vector2(0 + randf_range(-intensity, intensity), 0 + randf_range(-intensity, intensity))


func _on_hurtbox_entered(area : Area2D) -> void:
	if area.is_in_group("genome_hurtbox"):
		increase_temp.emit(area.owner.temp_value)
