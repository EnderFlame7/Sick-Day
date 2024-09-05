class_name UI extends Control

@export var wbc_button_size : Vector2

# ON SCREEN UI NODES
@onready var dna_label : Label = %DNALabel
@onready var timer_label : Label = %"Timer Label"
@onready var wave_label : Label = %"Wave Label"
@onready var thermometer_bar : TextureProgressBar = %ThermometerBar
@onready var thermometer_label : Label = %ThermometerLabel
@onready var wbc_buttons : VBoxContainer = %WhiteBloodCells

# UPGRADE PANEL NODES
@onready var upgrade_panel : TextureRect = %"Upgrade Panel"
@onready var wbc_title : Label = %"WBC Title Label"
@onready var close_button : TextureButton = %"Close Button"
@onready var wbc_viewport : TextureRect = %"WBC Viewport"
@onready var tier_value : Label = %"Tier Value"
@onready var stats_region : VBoxContainer = %"WBC Stats Region"
@onready var upgrade_cost : Label = %"Upgrade Cost"
@onready var upgrade_button : TextureButton = %"Upgrade Button"
@export var upgrade_disabled_texture : CompressedTexture2D
@export var max_upgrades_texture : CompressedTexture2D
@onready var sell_price : Label = %"Sell Price"
@onready var sell_button : TextureButton = %"Sell Button"

@onready var game_over_screen : Control = %"Game Over Screen"

@onready var anim_player : AnimationPlayer = %AnimPlayer
@onready var show_sfx : AudioStreamPlayer = %"Show SFX"

var stop_looping_the_fucking_animation : bool = false
var showing_upgrade_panel : bool = false
var upgrade_panel_wbc : WBC
signal holding_wbc(wbc)

func _ready() -> void:
	Global.ui = self
	game_over_screen.hide()
	upgrade_panel.hide()
	close_button.pressed.connect(hide_upgrade_panel)
	sell_button.pressed.connect(hide_upgrade_panel)
	holding_wbc.connect(get_parent()._hold_wbc)
	add_wbc_buttons()

func _process(delta: float) -> void:
	if not Global.game.game_over:
		dna_label.set_text(str(Global.game.dna))
		
		if Global.game.pre_wave_timer.is_stopped():
			timer_label.set_text("")
		else:
			timer_label.set_text("WAVE " + str(Global.game.wave + 1) + " STARTS IN " + str(snapped(Global.game.pre_wave_timer.get_time_left(), 1
			)) + " SECONDS!")
		
		wave_label.set_text("WAVE " + str(Global.game.wave) + " / " + str(Global.game.MAX_WAVE))

		update_thermometer()
		
		if upgrade_panel_wbc: update_upgrade_button(upgrade_panel_wbc)
		
	elif not anim_player.get_current_animation() == "game_over" and not stop_looping_the_fucking_animation:
		anim_player.set_current_animation("game_over")
		await anim_player.animation_finished
		stop_looping_the_fucking_animation = true
	
func _on_wbc_button_down() -> void:
	hide_upgrade_panel()
	for i in wbc_buttons.get_child_count():
		var button : Button = wbc_buttons.get_child(i)
		if button.button_pressed:
			holding_wbc.emit(i)
			
			
func add_wbc_buttons() -> void:
	for wbc in owner.white_blood_cells:
		var current_wbc : WBC = wbc.instantiate()
		var button : WBCButton = preload("res://Scenes/wbc_button.tscn").instantiate()
		button.set_custom_minimum_size(wbc_button_size)
		button.title = current_wbc.title
		button.icon_texture = current_wbc.icon
		button.dna_cost = current_wbc.initial_cost
		button.button_down.connect(_on_wbc_button_down)
		wbc_buttons.add_child(button)
		current_wbc.queue_free()
		
func _show_upgrade_panel(wbc : WBC) -> void:
	if not Global.game.game_over:
		show_sfx.play()
		showing_upgrade_panel = true
		update_upgrade_panel(wbc)
		anim_player.set_current_animation("show_upgrade_panel")
		anim_player.play()
	
	
func update_upgrade_panel(wbc : WBC) -> void:
	for stat in stats_region.get_children():
		stat.hide()
		stat.queue_free()
	
	if upgrade_panel_wbc:
		upgrade_button.pressed.disconnect(upgrade_panel_wbc._upgrade)
		sell_button.pressed.disconnect(upgrade_panel_wbc._sell)
		upgrade_panel_wbc.selected = false
	wbc.selected = true
	upgrade_panel_wbc = wbc
	wbc_title.set_text(wbc.title)
	wbc_viewport.set_texture(wbc.viewport.get_texture())
	tier_value.set_text("TIER " + str(wbc.tier))

	add_stats(wbc)

	update_upgrade_button(wbc)

	sell_price.set_text(str(wbc.sell_price))
	sell_button.pressed.connect(wbc._sell)
	
	
func add_stats(wbc : WBC) -> void:
	for i in range(3):
		var stat : StatInfo = preload("res://Scenes/stat_info.tscn").instantiate()
		match i:
			0:
				stat.property_label = "Damage:"
				stat.property_value = str(wbc.damage)
				if wbc.tier < wbc.MAX_TIER and not wbc.damage_tiers[wbc.tier] - wbc.damage == 0:
					stat.property_upgrade_label = "+" + str(wbc.damage_tiers[wbc.tier] - wbc.damage)
				elif wbc.tier == wbc.MAX_TIER:
					stat.property_upgrade_label = "MAX"
			1:
				stat.property_label = "Attack Speed:"
				stat.property_value = str(wbc.attack_rate)
				if wbc.tier < wbc.MAX_TIER and not wbc.attack_rate_tiers[wbc.tier] - wbc.attack_rate == 0:
					stat.property_upgrade_label = "+" + str(wbc.attack_rate_tiers[wbc.tier] - wbc.attack_rate)
				elif wbc.tier == wbc.MAX_TIER:
					stat.property_upgrade_label = "MAX"
			2:
				stat.property_label = "Range:"
				stat.property_value = str(wbc.range / 10)
				if wbc.tier < wbc.MAX_TIER and not ((wbc.range_tiers[wbc.tier] / 10) - (wbc.range / 10)) == 0:
					stat.property_upgrade_label = "+" + str((wbc.range_tiers[wbc.tier] / 10) - (wbc.range / 10))
				elif wbc.tier == wbc.MAX_TIER:
					stat.property_upgrade_label = "MAX"
		stats_region.add_child(stat)
		
	for i in range(wbc.special_properties.size()):
		var stat : StatInfo = preload("res://Scenes/stat_info.tscn").instantiate()
		stat.property_label = wbc.special_properties[i]
		stat.property_value = str(wbc.special_property_values[i])
		stat.property_upgrade_label = "+" + str(99)
		stats_region.add_child(stat)

func hide_upgrade_panel() -> void:
	if showing_upgrade_panel and not Global.game.game_over:
		showing_upgrade_panel = false
		if upgrade_panel_wbc:
			upgrade_panel_wbc.selected = false
		anim_player.set_current_animation("hide_upgrade_panel")
		anim_player.play()

func update_upgrade_button(wbc : WBC) -> void:
	if wbc.tier >= wbc.MAX_TIER:
		upgrade_cost.set_text("-")
		upgrade_cost.set_modulate(Color.WHITE)
		upgrade_button.texture_disabled = max_upgrades_texture
		upgrade_button.disabled = true
	elif Global.game.dna < wbc.upgrade_cost:
		upgrade_cost.set_text(str(wbc.upgrade_cost))
		upgrade_cost.set_modulate(Color.RED)
		upgrade_button.pressed.connect(wbc._upgrade)
		upgrade_button.texture_disabled = upgrade_disabled_texture
		upgrade_button.disabled = true
	else:
		upgrade_cost.set_text(str(wbc.upgrade_cost))
		upgrade_cost.set_modulate(Color.WHITE)
		upgrade_button.pressed.connect(wbc._upgrade)
		upgrade_button.disabled = false


func update_thermometer() -> void:
	thermometer_bar.set_value(Global.game.temperature)
	thermometer_label.set_text(str(Global.game.temperature))


func _on_menu_button_pressed() -> void:
	anim_player.set_current_animation("game_over")
	anim_player.play_backwards()
	await anim_player.animation_finished
	Global.main.game.hide()
	Global.main.game.queue_free()
	Global.menu.show_menu()


func _on_retry_button_pressed() -> void:
	anim_player.set_current_animation("game_over")
	anim_player.play_backwards()
	await anim_player.animation_finished
	Global.main._start_game()
