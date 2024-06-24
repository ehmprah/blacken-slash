extends ScrollContainer

func _physics_process(_delta):
	if visible:
		var scroll = Input.get_axis("ui_page_up", "ui_page_down")
		if scroll != 0:
			scroll_vertical += scroll * 20
