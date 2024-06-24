extends PanelContainer

const SkillFX = preload("res://components/skill_fx/skill_fx.tscn")

var data

onready var label = $Container/Name/Label
onready var desc = $Container/Description/Label
onready var skill_effects = $Container/SkillEffects


func _ready():
	label.text = data.name
	desc.text = data.desc
	var fx = SkillFX.instance()
	fx.skill = data
	fx.show_help_icon = false
	skill_effects.add_child(fx)
