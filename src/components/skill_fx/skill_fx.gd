extends PanelContainer

var skill
var show_help_icon = true

onready var help_icon = $Margin/Container/Help
onready var icon = $Margin/Container/Skill
onready var skill_name = $Margin/Container/Labels/Name
onready var fx = $Margin/Container/Labels/Effects

func _ready():
	update()
	# warning-ignore:return_value_discarded
	Settings.connect('language_changed', self, 'update')


func update():
	help_icon.visible = show_help_icon
	icon.hydrate(skill)
	skill_name.text = tr('T_SCRIPT') + ': '  + tr(skill.name)
	var effect_strings = []
	for effect in skill.effects:
		effect_strings.append(stringify(effect))
	if skill.has('followup'):
		var followup = Config.skills[skill.followup]
		for effect in followup.effects:
			effect_strings.append(stringify(effect))
	fx.text = Util.join_array(effect_strings, ', ')


func stringify(effect):
	var output = tr(effect.name)
	if effect.type == 'damage':
		if effect.has('min'):
			output += ' ' + Util.format_damage(effect.min, effect.max)
		if effect.has('value'):
			output += ' ' + Util.format_damage(effect.value)
	else:
		if effect.has('min'):
			output += ' ' + Util.format_percent_range(effect.min, effect.max)
		if effect.has('value'):
			output += ' ' + Util.format_percent(effect.value)
	return output


func update_actions(_item, _container):
	pass


func _on_Help_button_down():
	get_node('/root/Main/UI').popup('skill', skill)
