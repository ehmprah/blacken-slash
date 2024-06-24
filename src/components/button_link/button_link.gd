extends Button

export var url: String

func _on_Button_button_down():
	# warning-ignore:return_value_discarded
	OS.shell_open(url)


func _on_Button_mouse_entered():
	modulate = Color(1, 1, 1)


func _on_Button_mouse_exited():
	modulate = Color(0.75, 0.75, 0.75)
