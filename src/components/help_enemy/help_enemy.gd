extends MarginContainer

const Attribute = preload("res://components/attribute_base/attribute_base.tscn")
const SkillFX = preload("res://components/skill_fx/skill_fx.tscn")

var data

onready var details = {
	'name': $Container/Type/Labels/Name,
	'desc': $Container/Type/Labels/Description,
	'sprite': $Container/Type/Top/Sprite,
	'attributes': $Container/Attributes,
}

func _ready():
	details.sprite.texture = data.sprite.texture
	details.name.text = data.name
	details.desc.text = data.desc
	details.sprite.modulate = data.color
	details.name.modulate = data.color

	# Add skills
	for index in data.skills.size():
		var fx = SkillFX.instance()
		fx.show_help_icon = false
		fx.skill = data.skills[index].duplicate(true)
		details.attributes.add_child(fx)

	# Add effective health
	var health = Attribute.instance()
	var hp = Util.get_effective_health(data.attributes)
	health.data = {
		'name': 'T_HEALTH',
		'value': "%d/%d" % [hp, hp],
		'format': Config.FORMAT_PLAIN,
	}
	details.attributes.add_child(health)
	health.show_help_icon = false
	health.labels.rect_min_size = Vector2.ZERO

	# Add remaining attributes
	for key in Config.attributes_enemy:
		if data.attributes.has(key):
			add_attribute(key, Util.format_value(data.attributes[key], Config.attributes[key].format))
		elif (
			Config.attributes[key].base != 0 ||
			(State.game != null && State.game.modifiers.enemy.has(key))
		):
			add_attribute(key, Util.format_value(Config.attributes[key].base, Config.attributes[key].format))


func add_attribute(key, value):
	if State.game != null && State.game.modifiers.enemy.has(key):
		value += " [+%s]" % Util.format_value(State.game.modifiers.enemy[key], Config.attributes[key].format)
	var attribute = Attribute.instance()
	attribute.data = {
		'name': Config.attributes[key].name,
		'value': value,
	}
	details.attributes.add_child(attribute)
	attribute.labels.rect_min_size = Vector2.ZERO
