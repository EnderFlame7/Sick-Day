class_name StatInfo extends Control

var property_label : String
var property_value : String
var property_upgrade_label : String

func _ready() -> void:
	%"Property Label".set_text(property_label)
	%"Property Value".set_text(property_value)
	%"Property Upgrade Value".set_text(property_upgrade_label)
