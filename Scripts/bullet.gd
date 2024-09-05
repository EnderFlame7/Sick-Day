class_name Bullet extends Node2D

@export var hitbox : Area2D
@export var hitbox_collider : CollisionShape2D
@export var sprite : AnimatedSprite2D
@export var sfx : AudioStreamPlayer
@export var on_screen_notifier : VisibleOnScreenNotifier2D

var damage : int
var speed : int
var piercing : int
var antibody : Global.Antibody
var target : Pathogen

var sound : AudioStreamWAV
var sound_volume : float
var pitch_scale : float

var contacts : int = 0

func _ready() -> void:
	hitbox.area_entered.connect(_on_hitbox_entered)
	global_scale = Vector2(0.035, 0.035)
	sprite.set_frame_and_progress(antibody, 0.0)
	
	sfx.set_stream(sound)
	sfx.set_volume_db(sound_volume)
	sfx.set_pitch_scale(pitch_scale)
	sfx.play()
	
func _process(delta: float) -> void:
	global_scale = Vector2(0.035, 0.035)
	global_position += Vector2(speed * cos(global_rotation) * 100 * delta, speed * sin(global_rotation) * 100 * delta)

	if not on_screen_notifier.is_on_screen() and not sfx.playing:
		hide()
		queue_free()

func _on_hitbox_entered(area : Area2D) -> void:
	if area.is_in_group("pathogen_hurtbox"):
		if area.owner == target:
			contacts += 1
		elif contacts > 0:
			contacts += 1
		if contacts >= piercing:
				hide()
				hitbox_collider.set_deferred("disabled", true)
				hitbox.set_deferred("monitoring", false)
				hitbox.set_deferred("monitorable", false)
