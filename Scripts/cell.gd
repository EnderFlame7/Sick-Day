class_name Cell extends Node2D

const BASE_RADIUS : float = 175.0
@export var radius : int = BASE_RADIUS
@export var spin_rate : int

@onready var sprite : Sprite2D = %Sprite
@onready var collider : CollisionShape2D = %Collider
@onready var hurtbox : Area2D = %Hurtbox
@onready var hurtbox_collider : CollisionShape2D = %HurtboxCollider
@onready var all_locks : Node2D = %Locks
@onready var nav_region : NavigationRegion2D = %NavRegion
@onready var genome_sfx : AudioStreamPlayer = %"Genome SFX"

var nucleus : Nucleus

func _ready() -> void:
	Global.cell = self
	adjust_size()
	position_locks()
	nucleus = preload("res://Scenes/nucleus.tscn").instantiate()
	add_child(nucleus)

func _process(delta: float) -> void:
	global_rotation += deg_to_rad(spin_rate * delta)
	
	if Global.game.all_genomes.get_child_count() > 0:
		if not genome_sfx.is_playing(): genome_sfx.play()
	else:
		genome_sfx.stop()

func adjust_size() -> void:
	sprite.global_scale = Vector2(radius / (sprite.get_texture().get_width() / 2.0), radius / (sprite.get_texture().get_height() / 2.0))
	collider.get_shape().radius = radius
	hurtbox_collider.get_shape().radius = radius + 5
	nav_region.global_scale = Vector2(radius / BASE_RADIUS, radius / BASE_RADIUS)
	#nav_region.global_scale *= Vector2(2.0, 2.0)

func position_locks() -> void:
	for i in all_locks.get_child_count():
		var lock = all_locks.get_child(i)
		lock.position = Vector2(radius * cos(i * deg_to_rad(360.0 / all_locks.get_child_count())),
								radius * sin(i * deg_to_rad(360.0 / all_locks.get_child_count())))
