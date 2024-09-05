class_name Menu extends Control

@onready var anim_player : AnimationPlayer = %AnimPlayer
@onready var sneeze_sfx : AudioStreamPlayer = %"Sneeze SFX"
@onready var menu_music : AudioStreamPlayer = %"Menu Music"

signal start_game
signal start_tutorial

func _ready() -> void:
	Global.menu = self
	show_menu()

func _on_play_button_pressed() -> void:
	anim_player.set_current_animation("show_menu")
	anim_player.play_backwards()
	await anim_player.animation_finished
	menu_music.stop()
	hide()
	start_game.emit()


func _on_tutorial_button_pressed() -> void:
	hide()
	start_tutorial.emit()
	
	
func show_menu() -> void:
	hide()
	anim_player.set_current_animation("show_menu")
	anim_player.stop()
	show()
	await get_tree().create_timer(1).timeout
	sneeze_sfx.play()
	await get_tree().create_timer(0.2).timeout
	anim_player.play()
	await get_tree().create_timer(0.1).timeout
	menu_music.play()
