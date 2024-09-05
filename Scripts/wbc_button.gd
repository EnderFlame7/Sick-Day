class_name WBCButton extends Button

@onready var title_label : Label = %"Title Label"
@onready var wbc_icon : TextureRect = %"WBC Icon"
@onready var dna_label : Label = %"DNA Label"

var title : String
var icon_texture : Texture
var dna_cost : int

func _ready() -> void:
	title_label.set_text(title)
	wbc_icon.set_texture(icon_texture)
	wbc_icon.material.set_shader_parameter("flash_value", 0.0)
	dna_label.set_text(str(dna_cost))

func _process(delta: float) -> void:
	if Global.game.dna < dna_cost:
		title_label.set_modulate(Color(1.0, 1.0, 1.0, 0.6))
		wbc_icon.material.set_shader_parameter("flash_color", Color.DIM_GRAY)
		wbc_icon.material.set_shader_parameter("flash_value", 0.5)
		dna_label.set_modulate(Color.RED)
		disabled = true
	elif is_hovered():
		title_label.set_modulate(Color(1.0, 1.0, 0.0, 1.0))
		wbc_icon.material.set_shader_parameter("flash_color", Color.YELLOW)
		wbc_icon.material.set_shader_parameter("flash_value", 0.35)
		dna_label.set_modulate(Color(1.0, 1.0, 1.0))
		disabled = false
	else:
		title_label.set_modulate(Color(1.0, 1.0, 1.0, 1.0))
		wbc_icon.material.set_shader_parameter("flash_value", 0.0)
		dna_label.set_modulate(Color(1.0, 1.0, 1.0))
		disabled = false
