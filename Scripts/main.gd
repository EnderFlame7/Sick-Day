class_name Main extends Node2D

@onready var menu : Menu = %Menu

var game : Game

func _ready() -> void:
	Global.main = self
	menu.start_game.connect(_start_game)

func _start_game() -> void:
	if game:
		game.hide()
		game.queue_free()
	game = preload("res://Scenes/game.tscn").instantiate()
	add_child(game)
