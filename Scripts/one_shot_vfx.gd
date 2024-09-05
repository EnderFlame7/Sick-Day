extends GPUParticles2D

func _ready() -> void:
	one_shot = true
	emitting = true
	finished.connect(_on_finished)

func _on_finished() -> void:
	hide()
	queue_free()
