extends PanelContainer

const Attribute = preload('res://components/attribute_base/attribute_base.tscn')

var expanded = false

onready var attributes = $Container/Attributes

func _ready():
	# Add effective health
	var health = Attribute.instance()
	health.data = {
		'key': 'health',
		'name': 'T_HEALTH',
		'value': '100/100',
		'format': Config.FORMAT_PLAIN,
	}
	health.show_help_icon = false
	attributes.add_child(health)
	# Add regular attributes
	for key in Config.attributes_base:
		if key != 'action_points' && (!key.begins_with('flag') || Config.attributes_base[key] == 1):
			var attribute = Attribute.instance()
			attribute.data = Config.attributes[key].duplicate(true)
			attributes.add_child(attribute)
	# warning-ignore:return_value_discarded
	State.connect('gear_updated', self, 'update')


func update():
	# Update effective health
	var hp = Util.get_effective_health(State.game.attributes)
	var health = attributes.get_child(0)
	health.data.value = "%d/%d" % [hp * (1 - State.game.damage),hp]
	health.update()
	# Update regular attributes
	for attribute in attributes.get_children():
		var key = attribute.data.key
		if !Config.attributes.has(key):
			continue
		attribute.visible = State.game.difficulty.record >= Config.attributes[key]._level_min
		attribute.data.value = State.game.attributes[key]
		attribute.update()
		if State.game.modifiers.player.has(key):
			attribute.value.text += ' (' + Util.format_value(State.game.modifiers.player[key], attribute.data.format) + ')'

