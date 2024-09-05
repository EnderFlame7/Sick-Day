class_name CellPlatform extends StaticBody2D

@export var spin_rate : int

@onready var placement_area : Area2D = %PlacementArea
@onready var all_wbcs : Node2D = %WBCs

var mouse_hovering : bool = false

func _ready() -> void:
	Global.cell_platform = self
	placement_area.mouse_entered.connect(_on_mouse_entered)
	placement_area.mouse_exited.connect(_on_mouse_exited)
	global_rotation = deg_to_rad(randi_range(0, 360))


func _process(delta: float) -> void:
	global_rotation += deg_to_rad(spin_rate * delta)

# called from game script
func _add_wbc(wbc : WBC) -> void:
	wbc.global_position = get_local_mouse_position()
	all_wbcs.add_child(wbc)

func _allows_spot() -> bool:
	return mouse_hovering
	
	
func _on_mouse_entered() -> void:
	mouse_hovering = true
	
	
func _on_mouse_exited() -> void:
	mouse_hovering = false
