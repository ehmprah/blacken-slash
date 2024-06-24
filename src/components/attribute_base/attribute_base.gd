extends PanelContainer

onready var labels = $Container/Top/Text/Labels
onready var label = $Container/Top/Text/Labels/Name
onready var label_headline = $Container/Top/Text/Labels/Headline
onready var value = $Container/Top/Text/Value
onready var btn_help = $Container/Top/Help

var data
var headline
var show_help_icon = true

func _ready():
	update()


func update():
	label.text = data.name
	
	if headline:
		label_headline.text = String(headline)
		label_headline.visible = true

	if data.has('value'):
		if data.value == null:
			if data.has('format') && data.format == Config.FORMAT_PLAIN:
				value.text = '%.1f - %.1f' % [data._roll_value.min, data._roll_value.max]
			else:
				value.text = Util.format_percent_range(data._roll_value.min, data._roll_value.max)
		elif typeof(data.value) == TYPE_STRING:
			value.text = data.value
		elif data.format == Config.FORMAT_FLAG:
			pass
		else:
			value.text = Util.format_value(data.value, data.format)

	if data.has('key') && show_help_icon:
		btn_help.visible = true
		if data.key.begins_with('flag') && !headline:
			btn_help.visible = false
			label_headline.text = String('T_LEGENDARY_VARIABLE')
			label_headline.visible = true


func update_actions(_item, _container):
	pass


func _on_Help_button_down():
	get_node('/root/Main/UI').popup('attribute', data.key)
