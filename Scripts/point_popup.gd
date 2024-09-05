class_name PointPopup extends VBoxContainer

@onready var dna_label : Label = %DNAValue
@onready var overkill_label : Label = %OverkillValue
@onready var anim_player : AnimationPlayer = %AnimPlayer

var dna_value : int
var overkill_value : int
var overkill : bool = false

func _ready() -> void:
	hide()
	dna_label.set_text("+ " + str(dna_value))
	if overkill:
		overkill_label.set_text("+ " + str(overkill_value))
		overkill_label.show()
	else:
		overkill_label.hide()
	show()
	anim_player.set_current_animation("popup")
	anim_player.play()


func _process(delta: float) -> void:
	scale = Vector2(1, 1)


func _on_animation_finished(anim_name: StringName) -> void:
	hide()
	queue_free()
