class_name Game extends Node2D

@export_group("Game Properties")
@export var dna : int
@export var temperature : int
@export var wave : float = 0
@export var MAX_WAVE : float
@export var initial_enemies_per_wave : int
@export var initial_spawn_delay : float
@export var setup_time : float
@export var bake_delay : float
@export var music_volume_db : float
@export var antibody_textures : Array[CompressedTexture2D]

@export_group("Entity Arrays")
@export var white_blood_cells : Array[PackedScene]
@export var pathogens : Array[PackedScene]

@onready var pathogen_nav_region : NavigationRegion2D = %PathogenNavRegion
@onready var all_wbcs : Node2D = %WhiteBloodCells
@onready var all_pathogens : Node2D = %Pathogens
@onready var all_genomes : Node2D = %Genomes
@onready var wbc_preview : Sprite2D = %WBCPreview
@onready var range_preview : Sprite2D = %RangePreview
@onready var bake_timer : Timer = %BakeTimer
@onready var spawn_timer : Timer = %"Spawn Timer"
@onready var pre_wave_timer : Timer = %"Pre Wave Timer"
@onready var music : AudioStreamPlayer = %Music

var lock : int = 0
var holding_wbc : bool = false
var wbc_being_held : int = -1
var selected_pathogen : Pathogen
@onready var enemies_per_wave = initial_enemies_per_wave
@onready var enemies_to_spawn : int = 0
@onready var enemies_killed : int = 0
var time_passed : float
var time_since_click : float

var game_over : bool = false

func _ready() -> void:
	Global.game = self
	wbc_preview.hide()
	
	var cell : Cell = preload("res://Scenes/cell.tscn").instantiate()
	cell.global_position = Vector2(get_viewport_rect().size.x / 1.85, get_viewport_rect().size.y / 2)
	pathogen_nav_region.add_child(cell)
	
	var cell_platform : StaticBody2D = preload("res://Scenes/cell_platform.tscn").instantiate()
	cell_platform.global_position = cell.global_position
	pathogen_nav_region.add_child(cell_platform)
	
	pathogen_nav_region.bake_navigation_polygon()
	await pathogen_nav_region.bake_finished
	
	music.set_volume_db(music_volume_db)
	music.play()
	print("GAME STARTED!")

func _process(delta: float) -> void:
	#print("Enemies in wave: ", enemies_per_wave, " Enemies to spawn: ", enemies_to_spawn, " Enemies Killed: ", enemies_killed)
	time_passed = delta
	var pathogen : Pathogen
	
	if temperature >= 100:
		game_over = true
	
	if (all_pathogens.get_child_count() == 0 or %"Spawn Timer".is_stopped()) and enemies_to_spawn > 0 and pre_wave_timer.is_stopped():
		if Global.tutorial.prompt == 2: Global.tutorial.prompt = 3
		if randi_range(0, 100) <= snapped(25.0 * (wave / MAX_WAVE), 1): pathogen = pathogens[1].instantiate()
		else: pathogen = pathogens[0].instantiate()
		pathogen.global_position = random_pathogen_spawn()
		
		# Difficulty scaling
		pathogen.health = clamp(pathogen.base_health * (8.5 * (wave / MAX_WAVE)), pathogen.base_health, 999)
		pathogen.speed = clamp(pathogen.base_speed * (2.25 * (wave / MAX_WAVE)), pathogen.base_speed, 999)
		pathogen.dna_value = clamp(snapped(pathogen.base_dna_value * (5.0 * (wave / MAX_WAVE)), 1), pathogen.base_dna_value, 999)
		
		var rand_antibody : int = randi_range(0, antibody_textures.size() - 1)
		pathogen.antibody = Global.Antibody.values()[rand_antibody]
		pathogen.antibody_texture = antibody_textures[rand_antibody]
		
		all_pathogens.add_child(pathogen)
		spawn_timer.set_wait_time(clamp(initial_spawn_delay - (wave / (MAX_WAVE * 5)), 0.75, 1))
		spawn_timer.start(clamp(initial_spawn_delay - (wave / (MAX_WAVE * 5)), 0.75, 1))
		enemies_to_spawn -= 1
	elif (wave == 0 and pre_wave_timer.is_stopped()) or (enemies_to_spawn <= 0 and enemies_killed >= enemies_per_wave and pre_wave_timer.is_stopped()):
		if Global.tutorial.prompt == 1: Global.tutorial.prompt = 2
		if Global.tutorial.prompt == 3: Global.tutorial.prompt = 4
		pre_wave_timer.set_wait_time(setup_time)
		pre_wave_timer.start(setup_time)
		
	preview_wbc()

	if bake_timer.is_stopped():
		pathogen_nav_region.bake_navigation_polygon()
		bake_timer.set_wait_time(bake_delay)
		bake_timer.start(bake_delay)
		
	if all_genomes.get_child_count() > 0:
		Global.nucleus.panicking = true
	else:
		Global.nucleus.panicking = false
		
	#if Input.is_action_just_pressed("temp100"):
		#dna = 10000

func preview_wbc() -> void:
	if holding_wbc:
		var wbc : WBC = white_blood_cells[wbc_being_held].instantiate()
		wbc_preview.set_texture(wbc.icon)
		wbc_preview.global_position = get_global_mouse_position()
		range_preview.set_texture(wbc.range_visual.get_texture())
		range_preview.global_scale = Vector2(wbc.range_tiers[0] / (wbc.range_visual_size.x / 2.0), wbc.range_tiers[0] / (wbc.range_visual_size.y / 2.0))
		range_preview.global_position = get_global_mouse_position()
		if Global.cell_platform._allows_spot() and not mouse_hovering_over_wbc():
			wbc_preview.set_modulate(Color(1, 1, 1, 0.6))
		else:
			wbc_preview.set_modulate(Color(Color(1, 0, 0, 0.6)))
		wbc_preview.show()
		range_preview.show()
		
		place_wbc(wbc)

func place_wbc(wbc : WBC) -> void:
	if Input.is_action_just_released("lmb"):
		holding_wbc = false
		wbc_preview.hide()
		range_preview.hide()
		wbc_being_held = -1
		
		if Global.cell_platform._allows_spot() and dna >= wbc.initial_cost and not mouse_hovering_over_wbc():
			Global.cell_platform._add_wbc(wbc)
			dna -= wbc.initial_cost
		else:
			wbc.queue_free()
	else:
		wbc.queue_free()

func _hold_wbc(wbc : int) -> void:
	holding_wbc = true
	wbc_being_held = wbc
	
# Called by nucleus script
func _increase_temp(amount : int) -> void:
	temperature += amount
	temperature = clamp(temperature, 0, 100)
	
func random_pathogen_spawn() -> Vector2:
	var rand_side : int = randi_range(0, 3)
	match rand_side:
		0:
			return Vector2(randi_range(0, get_viewport_rect().size.x), 0)
		1:
			return Vector2(get_viewport_rect().size.x, randi_range(0, get_viewport_rect().size.y))
		2:
			return Vector2(randi_range(0, get_viewport_rect().size.x), get_viewport_rect().size.y)
		3:
			return Vector2(0, randi_range(0, get_viewport_rect().size.y))
	return Vector2.ZERO

func detected_double_tap(input : String) -> bool:
	if Input.is_action_just_pressed(input):
		if time_since_click <= 0.25:
			time_since_click = 0
			return true
		else:
			time_since_click = 0
			
	if not Input.is_action_pressed(input):
		time_since_click += get_time_passed()
		
	return false
	
	
func mouse_hovering_over_wbc() -> bool:
	for white_blood_cell in Global.cell_platform.all_wbcs.get_children():
		if white_blood_cell.mouse_hovering:
			return true
	return false
	

func get_time_passed() -> float:
	return time_passed
	

# Called from pathogen script
func _increment_kill_count() -> void:
	enemies_killed += 1


func _on_pre_wave_timer_timeout() -> void:
	wave += 1
	if wave > 1:
		enemies_per_wave = initial_enemies_per_wave * ceil((22.0 * (wave / MAX_WAVE)))
	enemies_to_spawn = enemies_per_wave
	enemies_killed = 0
