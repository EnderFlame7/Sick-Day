class_name Tutorial extends Control

@export var prompts : Array[String]

@onready var prompt_label : Label = %Prompt

var prompt : int = 0

func _ready() -> void:
	Global.tutorial = self

func _process(delta: float) -> void:
	prompt_label.set_text(prompts[prompt])
	
	if prompt == prompts.size() - 1:
		await get_tree().create_timer(5).timeout
		hide()

func _on_close_button_pressed() -> void:
	hide()
