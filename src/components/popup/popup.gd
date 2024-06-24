extends PanelContainer

const Attribute = preload('res://components/help_attribute/help_attribute.tscn')
const Skill = preload('res://components/help_skill/help_skill.tscn')
const Meta = preload('res://components/help_meta/help_meta.tscn')

onready var animation = $AnimationPlayer

var child

func _ready():
	$V/Container.add_child(child)
	animation.play("Enter")


func hide():
	animation.play_backwards("Enter")
	yield(animation, "animation_finished")
	queue_free()


func _input(event):
	if (
		event.is_action_pressed("ui_cancel") ||
		event.is_action_pressed("ui_accept")
	):
		hide()
		accept_event()


func add(type, what):
	match type:
		'meta':
			child = Meta.instance()
		'attribute':
			child = Attribute.instance()
			child.data = Config.attributes[what]
		'skill':
			child = Skill.instance()
			child.data = what
