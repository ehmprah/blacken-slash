extends PanelContainer

const Attribute = preload("res://components/attribute_base/attribute_base.tscn")
const SkillFX = preload("res://components/skill_fx/skill_fx.tscn")

onready var attributes = $ScrollContainer/Container/Attributes
onready var scroll = $ScrollContainer

func _ready():
	for index in State.game.skills.size():
		var fx = SkillFX.instance()
		fx.show_help_icon = false
		fx.skill = State.game.skills[index].duplicate(true)
		attributes.add_child(fx)

	# Show effective health
	var health = Attribute.instance()
	var hp = Util.get_effective_health(State.game.attributes)
	health.data = {
		'name': 'T_HEALTH',
		'value': "%d/%d" % [hp * (1 - State.game.damage),hp],
		'format': Config.FORMAT_PLAIN,
	}
	attributes.add_child(health)
	health.show_help_icon = false
	health.labels.rect_min_size = Vector2.ZERO

	# Add regular attributes
	for key in State.game.attributes:
		if (
			key != 'action_points' && 
			!key.begins_with('flag') &&
			State.game.difficulty.record >= Config.attributes[key]._level_min
		):
			var attribute = Attribute.instance()
			attribute.data = {
				'name': Config.attributes[key].name,
				'value': State.game.attributes[key],
				'format': Config.attributes[key].format,
			}
			attributes.add_child(attribute)
			attribute.labels.rect_min_size = Vector2.ZERO


func _gui_input(_event):
	accept_event()


func _physics_process(_delta):
	var diff = Input.get_axis("ui_page_up", "ui_page_down")
	if diff != 0:
		scroll.scroll_vertical += diff * 20
