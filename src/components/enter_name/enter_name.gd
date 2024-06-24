extends PanelContainer

onready var entername = $Panel/V
onready var name_field = $Panel/V/Name
onready var name_save = $Panel/V/SaveName

var regex

func _ready():
	regex = RegEx.new()
	regex.compile("[^A-Za-z0-9]")
	if Controls.needs_focus():
		name_field.grab_focus()


func _on_Name_text_changed(text):
	name_save.disabled = text.length() == 0 || regex.search(text) != null


func _on_Name_text_entered(_new_text):
	save_name()


func save_name():
	State.profile.name = name_field.text
	State.save_profile()
	visible = false
	queue_free()
