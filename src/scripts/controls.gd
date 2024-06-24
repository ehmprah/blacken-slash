extends Node

signal controls_changed
signal controller_type_changed

enum {
	TOUCH,
	MOUSE,
	KEYBOARD,
	CONTROLLER,
}

enum {
	TYPE_NONE,
	TYPE_KEYBOARD,
	TYPE_XBOX,
	TYPE_PS,
	TYPE_JOYCON,
}

var scheme = TOUCH
var type = TYPE_NONE

func _ready():
	var platform = OS.get_name()
	if platform == 'Android' || platform == 'iOS':
		set_process_input(false)


func _input(event):
	if event is InputEventJoypadButton || event is InputEventJoypadMotion:
		change_control_scheme(CONTROLLER)
	elif event is InputEventMouseButton || event is InputEventMouseMotion:
		change_control_scheme(MOUSE)


func change_control_scheme(which):
	if scheme != which:
		scheme = which
		if scheme != MOUSE:
			Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			type = TYPE_KEYBOARD
			emit_signal('controller_type_changed', type)
		if scheme == CONTROLLER:
			type = TYPE_XBOX
			var device_name = Input.get_joy_name(0)
			if "PS" in device_name:
				type = TYPE_PS
			elif "Joy-Con" in device_name || "Joy Con" in device_name:
				type = TYPE_JOYCON
			emit_signal('controller_type_changed', type)
		emit_signal('controls_changed', needs_focus())
		print('control scheme changed')


func needs_focus():
	return scheme != TOUCH


func change_focus():
	emit_signal('controls_changed', needs_focus())
