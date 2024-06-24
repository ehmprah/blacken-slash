extends TextureRect

export(Texture) var icon_keyboard
export(Texture) var icon_xbox
export(Texture) var icon_ps
export(Texture) var icon_joycon


func _ready():
	texture = null
	update_icon(Controls.type)
	# warning-ignore:return_value_discarded
	Controls.connect('controller_type_changed', self, 'update_icon')


func update_icon(type):
	match type:
		Controls.TYPE_NONE:
			texture = null
		Controls.TYPE_KEYBOARD:
			texture = icon_keyboard
		Controls.TYPE_XBOX:
			texture = icon_xbox
		Controls.TYPE_PS:
			texture = icon_ps
		Controls.TYPE_JOYCON:
			texture = icon_joycon
