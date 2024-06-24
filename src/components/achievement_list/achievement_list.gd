extends VBoxContainer

const Achievement = preload("res://components/achievement/achievement.tscn")

var hide_completed = false

onready var scroll_container = $Scroll
onready var list = $Scroll/Margin/List

func _ready():
	for achievement in Config.achievements.values():
		var scene = Achievement.instance()
		scene.data = achievement
		list.add_child(scene)


func _physics_process(_delta):
	if visible:
		var scroll = Input.get_axis("ui_page_up", "ui_page_down")
		if scroll != 0:
			scroll_container.scroll_vertical += scroll * 20


func update():
	for achievement in list.get_children():
		achievement.update()
		achievement.visible = !hide_completed || !achievement.unlocked


func _on_CheckButton_toggled(button_pressed):
	hide_completed = button_pressed
	update()
