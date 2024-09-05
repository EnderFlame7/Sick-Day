class_name WBC extends Entity

@export_group("WBC Properties")
@export var title : String
@export var initial_cost : int
@export var sell_price : int = 50
@export var tier : int = 1
@export var range_visual_size : Vector2 = Vector2(300.0, 300.0)
@export var special_properties : Array[String]
var special_property_values : Array[int]
@export var icon : Texture

@export_group("WBC Tiers")
@export var tier_cost : Array[int]
@export var damage_tiers : Array[int]
@export var attack_rate_tiers : Array[float]
@export var range_tiers : Array[float]

@export_group("WBC Nodes")
@export var range_area : Area2D
@export var range_shape : CollisionShape2D
@export var range_visual : Sprite2D
@export var body : AnimatedSprite2D
@export var face : AnimatedSprite2D
@export var attack_sfx : AudioStreamWAV
@export var attack_volume_db : float
@export var upgrade_sfx : AudioStreamPlayer
@export var tier_label : Label

var upgrade_cost : int
var damage : int
var attack_rate : float
var range : float

const MAX_TIER = 4

signal show_upgrade_panel(wbc : WBC)

func _ready() -> void:
	super._ready()
	
	tier_label.hide()
	
	tier_cost.clear()
	tier_cost.append(initial_cost)
	tier_cost.append(initial_cost * 3)
	tier_cost.append(initial_cost * 7)
	tier_cost.append(initial_cost * 15)
	
	upgrade_cost = tier_cost[tier]
	
	damage = damage_tiers[tier - 1]
	attack_rate = attack_rate_tiers[tier - 1]
	range = range_tiers[tier - 1]
	
	sell_price = initial_cost / 2
	
	Global.tutorial.prompt = 1
	show_upgrade_panel.connect(Global.ui._show_upgrade_panel)
	hide()
	range_shape.get_shape().radius = range
	range_visual.scale = Vector2(range / (range_visual_size.x / 2.0), range / (range_visual_size.y / 2.0))
	range_visual.hide()
	self.add_to_group("wbc")
	show()

func _process(delta: float) -> void:
	super._process(delta)
	
	target = calculate_nearest_target()
	
	if not (target and is_instance_valid(target)):
		body.scale.x = abs(body.scale.x)
		body.global_rotation = lerp(body.global_rotation, deg_to_rad(0), 10 * delta)
		anim_player.set_current_animation("idle")
		anim_player.play()
		
	if Input.is_action_just_pressed("lmb") and mouse_hovering and not selected:
		selected = true # Might not work
		show_upgrade_panel.emit(self)
	
	if selected or mouse_hovering:
		update_tier_label()
		tier_label.show()
		if selected: range_visual.show()
	else:
		tier_label.hide()
		range_visual.hide()
	
func calculate_nearest_target() -> Pathogen:
	var nearest_pathogen : Pathogen = null
	var min_dist : float = 9999999
	for area in range_area.get_overlapping_areas():
		if area.is_in_group("pathogen_hurtbox") and not area.owner.dead:
			var pathogen : Pathogen = area.owner
			if pathogen.selected:
				nearest_pathogen = pathogen
				break
			else:
				#var distance = sqrt(global_position.distance_squared_to(pathogen.global_position))
				var distance = pathogen.distance_to_lock
				if distance < min_dist:
					min_dist = distance
					nearest_pathogen = pathogen
			
	return nearest_pathogen


func update_tier_label() -> void:
	tier_label.set_text(str(tier))
	tier_label.rotation = -global_rotation

# called from ui script
func _upgrade() -> void:
	if tier < MAX_TIER:
		Global.game.dna -= upgrade_cost
		tier += 1
		upgrade_sfx.play()
		if tier < MAX_TIER: upgrade_cost = tier_cost[tier]
		damage = damage_tiers[tier - 1]
		attack_rate = attack_rate_tiers[tier - 1]
		range = range_tiers[tier - 1]
		range_shape.get_shape().radius = range
		range_visual.scale = Vector2(range / (range_visual_size.x / 2.0), range / (range_visual_size.y / 2.0))
	
# called from ui script
func _sell() -> void:
	Global.game.dna += sell_price
	hide()
	queue_free()
